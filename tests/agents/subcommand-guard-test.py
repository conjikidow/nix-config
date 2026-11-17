# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

import json
import subprocess
import sys

guard, rules, cases_path = sys.argv[1:4]
with open(cases_path) as file:
    cases = json.load(file)


def decision(command: str, *flags: str, rules_path: str = rules) -> str:
    result = subprocess.run(
        [guard, rules_path, *flags],
        input=json.dumps({"tool_name": "Bash", "tool_input": {"command": command}}),
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return f"exit {result.returncode}: {result.stderr.strip()}"
    if result.stdout.strip():
        return json.loads(result.stdout)["hookSpecificOutput"]["permissionDecision"]
    return "none"


failures = []
total = 0


def expect(mode: str, group: str, command: str, expected: str, *flags: str, rules_path: str = rules) -> None:
    global total
    total += 1
    got = decision(command, *flags, rules_path=rules_path)
    if got != expected:
        failures.append(f"{mode} {expected} / {group}: got {got}: {command!r}")


deny_only = cases.pop("deny-only")
for expected, groups in cases.items():
    for group, commands in groups.items():
        for command in commands:
            expect("default", group, command, expected)
            expect("--deny-only", group, command, "deny" if expected == "deny" else "none", "--deny-only")
for expected, groups in deny_only.items():
    for group, commands in groups.items():
        for command in commands:
            expect("--deny-only", group, command, expected, "--deny-only")
expect("default", "a missing rules file", "git status", "ask", rules_path="/nonexistent")
expect("--deny-only", "a missing rules file", "git status", "deny", "--deny-only", rules_path="/nonexistent")

print(f"{total - len(failures)} of {total} checks passed")
for failure in failures:
    print(failure)
sys.exit(1 if failures else 0)
