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


def subcommand_index(program: str, args: list) -> int:
    """Return the index of the first argument after the global options."""
    i = 0
    while i < len(args):
        value = static_value(args[i])
        if (program == "git" and value in GIT_OPTIONS_WITH_VALUE) or (program == "gh" and value in ("-R", "--repo")):
            static_value(args[i + 1])
            i += 2
        elif program == "git" and (value in GIT_FLAGS or re.match(r"--(git-dir|work-tree|namespace)=", value)):
            i += 1
        elif program == "git" and value.startswith("-"):
            raise Undecidable(value)
        elif program == "gh" and re.match(r"(-R|--repo=).", value):
            i += 1
        else:
            return i
    raise Undecidable("no subcommand")


def hidden_call(args: list) -> bool:
    """Tell whether a later word starts a git or gh call with options before its subcommand."""
    values = [arg.text.decode() for arg in args]
    for word, following in itertools.pairwise(values):
        if word.lstrip("=") == "git" and following.split("=")[0] in GIT_GLOBAL:
            return True
        if word.lstrip("=") == "gh" and re.match(r"(-R|--repo)", following):
            return True
    return False


def check(command: Node, source: bytes, rules: dict):
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
        program = None
    if program not in ("git", "gh"):
        if hidden_call(args):
            return "ask", "A git or gh call with options before its subcommand is nested in another command."
        return None
    try:
        sub = subcommand_index(program, args)
        if sub == 0:
            return None
        static_value(args[sub])
    except (Undecidable, IndexError):
        return "ask", f"The options before the {program} subcommand could not be resolved."
    normalized = f"{program} " + source[args[sub].start_byte : args[-1].end_byte].decode()
    for kind in ("deny", "ask"):
        if any(match(normalized) for match in rules[kind]):
            return kind, f"Matches a {kind} rule once the options before the subcommand are removed: {normalized}"
    if not any(match(normalized) for match in rules["allow"]):
        return "ask", f"Not allowed once the options before the subcommand are removed: {normalized}"
    return None


def commands(node: Node):
    if node.type == "command":
        yield node
    for child in node.children:
        yield from commands(child)


def main():
    text = json.load(sys.stdin).get("tool_input", {}).get("command") or ""
    if "git" not in text and "gh" not in text:
        return
    source = text.encode()
    tree = Parser(Language(tree_sitter_bash.language())).parse(source)
    rules = load_rules(sys.argv[1])
    decisions = [d for d in (check(c, source, rules) for c in commands(tree.root_node)) if d]
    if tree.root_node.has_error or "\\`" in text:
        decisions.append(("ask", "The command could not be parsed, so its git and gh calls could not be checked."))
    for kind in ("deny", "ask"):
        reasons = [reason for decision, reason in decisions if decision == kind]
        if reasons:
            output = {"hookEventName": "PreToolUse", "permissionDecision": kind, "permissionDecisionReason": reasons[0]}
            print(json.dumps({"hookSpecificOutput": output}))
            return


main()
