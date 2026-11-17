# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

import json
import subprocess
import sys

guard, rules, cases_path = sys.argv[1:4]
with open(cases_path) as file:
    cases = json.load(file)


def decision(command: str) -> str:
    result = subprocess.run(
        [guard, rules],
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
for expected, groups in cases.items():
    for group, commands in groups.items():
        for command in commands:
            total += 1
            got = decision(command)
            if got != expected:
                failures.append(f"{expected} / {group}: got {got}: {command!r}")

print(f"{total - len(failures)} of {total} cases passed")
for failure in failures:
    print(failure)
sys.exit(1 if failures else 0)
