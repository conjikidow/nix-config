---
name: subagent-prompting
description: How to write the prompt when delegating work to a subagent via the Agent tool — a done-state task definition, embedded context, explicit scope boundaries, an output contract, and fallback rules, then reviewing what comes back. Use whenever spawning or messaging a subagent.
---

# Subagent Prompting

Write the prompt in this order.

## 1. One-sentence task definition

State what "done" looks like, not just the activity.
Not "investigate the flaky test" but "identify why test X intermittently fails and report the root cause with file:line
references".

## 2. Embedded context

Transcribe every fact the subagent needs but cannot know:
repository paths (absolute), branch names, reproduction steps,
what has already been discovered, and what was already tried and failed.
References like "the file we discussed" or "the earlier error" do not exist for the subagent.

## 3. Scope boundaries

State explicitly what is in and out of bounds:

- Read-only, or allowed to edit?
- Commit, or leave changes in the working tree?
- Which directories or components are in scope?
- Which constraints of this environment it must obey, such as resource limits or commands it must never run,
  stated as non-negotiable rather than as preferences.

Without boundaries, subagents expand scope in good faith.

## 4. Output contract

Only the subagent's final message comes back.
Specify the report format concretely:

- Structure ("conclusion first, then evidence", "a list of file:line entries").
- The negative case ("if nothing is found, say so explicitly rather than padding").
- Anything that must be included verbatim (error messages, commands run, test output).

## 5. Fallback rules

The subagent cannot ask questions mid-task, so pre-answer its likely dilemmas:

- "If torn between A and B, choose A."
- "If confidence is low, return the ranked candidates instead of guessing."
- "If blocked, report exactly what is missing and stop."

## After the subagent returns

- Review its diff yourself before reporting: you own the result,
  and scope additions the subagent made unasked must be surfaced to the user.
- Verify load-bearing claims before acting on them; a subagent's confident summary is a hypothesis, not ground truth.
