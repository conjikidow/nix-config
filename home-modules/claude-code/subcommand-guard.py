# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

import itertools
import json
import re
import sys

import tree_sitter_bash
from tree_sitter import Language, Node, Parser

GIT_OPTIONS_WITH_VALUE = {"-C", "--git-dir", "--work-tree", "--namespace"}
GIT_FLAGS = {"--no-pager", "-P", "-p", "--paginate", "--bare", "--no-replace-objects", "--no-lazy-fetch"}
GIT_FLAGS |= {"--no-optional-locks", "--no-advice", "--literal-pathspecs", "--glob-pathspecs"}
GIT_FLAGS |= {"--noglob-pathspecs", "--icase-pathspecs"}
GIT_GLOBAL = GIT_OPTIONS_WITH_VALUE | GIT_FLAGS | {"-c", "--exec-path", "--config-env"}

STATIC_STRING_PARTS = {'"', "string_content"}


class Undecidable(Exception):
    pass


def static_value(node: Node) -> str:
    """Return the value of a word that always expands to exactly that one word."""
    text = node.text.decode()
    if node.type in ("word", "number"):
        if re.search(r"[$`{}*?\[\]<>]", text):
            raise Undecidable(text)
        return re.sub(r"\\(.)", r"\1", text)
    if node.type == "raw_string":
        return text[1:-1]
    if node.type == "ansi_c_string" and text.isascii():
        return text[2:-1].encode().decode("unicode_escape")
    if node.type == "string" and all(child.type in STATIC_STRING_PARTS for child in node.children):
        return re.sub(r'\\([$`"\\])', r"\1", text[1:-1])
    if node.type == "concatenation":
        return "".join(static_value(child) for child in node.children)
    raise Undecidable(text)


def rule_matcher(rule: str):
    pattern = re.sub(r":\*$", " *", rule)
    regex = re.compile(".*".join(map(re.escape, pattern.split("*"))), re.DOTALL)
    bare = pattern[:-2] if pattern.endswith(" *") and pattern.count("*") == 1 else None
    return lambda text: regex.fullmatch(text) is not None or text == bare


def load_rules(path: str) -> dict:
    with open(path) as file:
        permissions = json.load(file)
    return {
        kind: [rule_matcher(rule[5:-1]) for rule in permissions.get(kind, []) if rule.startswith("Bash(")]
        for kind in ("deny", "ask", "allow")
    }


def option_value(node: Node) -> None:
    """Fail unless the option value is always exactly one word."""
    if node.type not in ("string", "raw_string", "ansi_c_string"):
        static_value(node)


def subcommand_index(program: str, args: list) -> int:
    """Return the index of the first argument after the global options."""
    i = 0
    while i < len(args):
        value = static_value(args[i])
        if (program == "git" and value in GIT_OPTIONS_WITH_VALUE) or (program == "gh" and value in ("-R", "--repo")):
            option_value(args[i + 1])
            i += 2
        elif (
            program == "git"
            and (value in GIT_FLAGS or re.match(r"--(git-dir|work-tree|namespace)=", value))
            or program == "gh"
            and re.match(r"(-R|--repo=).", value)
        ):
            i += 1
        elif value.startswith("-"):
            raise Undecidable(value)
        else:
            return i
    raise Undecidable("no subcommand")


def static_or_raw(node: Node) -> str:
    try:
        return static_value(node)
    except Undecidable:
        return node.text.decode()


def plain(node: Node) -> bool:
    return node.text.decode() == static_or_raw(node)


def hidden_call(args: list) -> bool:
    """Tell whether a later word starts a git or gh call with options before its subcommand."""
    values = [static_or_raw(arg) for arg in args]
    for word, following in itertools.pairwise(values):
        if word.lstrip("=") == "git" and following.split("=")[0] in GIT_GLOBAL:
            return True
        if word.lstrip("=") == "gh" and re.match(r"(-R|--repo)", following):
            return True
    return False


def possible_call(text: str) -> bool:
    """Tell whether git or gh may appear as a word once quotes, escapes and line continuations are removed."""
    return re.search(r"(?<![\w.-])(git|gh)(?![\w-])", re.sub(r"\\\n|['\"\\]", "", text)) is not None


def check(command: Node, source: bytes, rules: dict, possible: bool):
    """Return the decision and its reason for one simple command, or None."""
    name = command.child_by_field_name("name")
    args = command.children_by_field_name("argument")
    if name is None:
        return None
    if name.type == "command_name" and name.named_children:
        name = name.named_children[0]
    try:
        program = static_value(name).lstrip("=")
    except Undecidable:
        if possible or (args and static_or_raw(args[0]).split("=")[0] in GIT_GLOBAL | {"-R", "--repo"}):
            return "ask", "The command name expands, so it could not be checked against the git and gh rules."
        return None
    if program not in ("git", "gh"):
        if hidden_call(args):
            return "ask", "A git or gh call with options before its subcommand is nested in another command."
        return None
    if not args or [static_or_raw(arg) for arg in args] in (["--version"], ["--help"], ["-h"]):
        return None
    try:
        sub = subcommand_index(program, args)
        if sub == 0 and name.text.decode() == program and plain(args[0]):
            return None
        subcommand = static_value(args[sub])
    except (Undecidable, IndexError):
        return "ask", f"The options before the {program} subcommand could not be resolved."
    normalized = f"{program} {subcommand}" + source[args[sub].end_byte : args[-1].end_byte].decode()
    for kind in ("deny", "ask"):
        if any(match(normalized) for match in rules[kind]):
            return kind, f"Matches a {kind} rule once written as plain {program}: {normalized}"
    if not any(match(normalized) for match in rules["allow"]):
        return "ask", f"Not allowed once written as plain {program}: {normalized}"
    return None


def nodes(root: Node):
    stack = [root]
    while stack:
        node = stack.pop()
        yield node
        stack.extend(reversed(node.children))


def unparsed_substitution(node: Node) -> bool:
    """Tell whether a heredoc body or ${...} expansion holds a substitution that was not parsed."""
    if node.type == "heredoc_body":
        start = next((child for child in node.parent.children if child.type == "heredoc_start"), None)
        if start is None or re.search(r"['\"\\]", start.text.decode()):
            return False
    elif node.type != "expansion":
        return False
    text = node.text.decode()
    markers = text.count("$(") + text.count("`") // 2
    parsed = sum(1 for child in nodes(node) if child.type in ("command_substitution", "arithmetic_expansion"))
    return markers > parsed or ("`" in text and not parsed)


def escaped_backtick(node: Node) -> bool:
    text = node.text.decode()
    return node.type == "command_substitution" and text.startswith("`") and "\\`" in text


def decisions_for(text: str, rules: dict) -> list:
    source = text.encode("utf-8", "surrogatepass")
    tree = Parser(Language(tree_sitter_bash.language())).parse(source)
    possible = possible_call(text)
    all_nodes = list(nodes(tree.root_node))
    decisions = [d for d in (check(n, source, rules, possible) for n in all_nodes if n.type == "command") if d]
    unchecked = any(unparsed_substitution(n) for n in all_nodes)
    if possible and (tree.root_node.has_error or any(escaped_backtick(n) for n in all_nodes)):
        unchecked = True
    if unchecked:
        decisions.append(("ask", "The command could not be parsed, so its git and gh calls could not be checked."))
    return decisions


def decide(text: str, rules_path: str):
    rules = load_rules(rules_path)
    decisions = decisions_for(text, rules)
    if "\\\n" in text:
        decisions += decisions_for(text.replace("\\\n", ""), rules)
    for kind in ("deny", "ask"):
        reasons = [reason for decision, reason in decisions if decision == kind]
        if reasons:
            return kind, reasons[0]
    return None


def main():
    try:
        text = json.load(sys.stdin).get("tool_input", {}).get("command") or ""
        decision = decide(text, sys.argv[1])
    except Exception as error:  # noqa: BLE001
        decision = ("ask", f"The subcommand guard failed ({type(error).__name__}), so this command needs confirmation.")
    if decision:
        output = {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision[0],
            "permissionDecisionReason": decision[1],
        }
        print(json.dumps({"hookSpecificOutput": output}))


main()
