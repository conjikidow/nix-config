# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

import json
import subprocess
import sys

guard, rules, cases_path = sys.argv[1:4]
with open(cases_path) as file:
    cases = json.load(file)

failures = []
for expected, commands in cases.items():
    for command in commands:
        result = subprocess.run(
            [guard, rules],
            input=json.dumps({"tool_name": "Bash", "tool_input": {"command": command}}),
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            got = f"exit {result.returncode}: {result.stderr.strip()}"
        elif result.stdout.strip():
            got = json.loads(result.stdout)["hookSpecificOutput"]["permissionDecision"]
        else:
            got = "none"
        if got != expected:
            failures.append(f"expected {expected}, got {got}: {command!r}")

total = sum(len(commands) for commands in cases.values())
print(f"{total - len(failures)} of {total} cases passed")
for failure in failures:
    print(failure)
sys.exit(1 if failures else 0)
