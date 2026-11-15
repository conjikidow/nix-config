# Workflow Checkpoints

Do exactly what was asked — nothing more.
Edit, commit, push, and PR creation are separate checkpoints, and each requires its own explicit instruction.

## Scope of Work

- Perform only the work explicitly requested; never expand scope on your own initiative.
- A request to investigate, explain, or give an opinion is NOT a request to change anything. Report findings and stop.
- When the user pastes a review comment or CI failure, first interpret it, verify whether it is correct,
  and give your assessment. Do not apply fixes until instructed.
- When a design decision arises, present labeled options (1/2/3 or A/B/C) with trade-offs and a recommendation,
  then wait for the user's choice before implementing.

## Git Checkpoints

- Editing files never implies permission to commit.
- Never commit, push, or create a PR unless that specific step was explicitly requested.
- "commit" authorizes committing only — it does not authorize pushing, and "push" does not authorize PR creation.
- The user merges PRs on GitHub themselves. Never merge a remote PR unless explicitly told to.

These checkpoints also bind subagents: when delegating, state the allowed endpoint
(e.g. "leave changes uncommitted") in the subagent prompt.
