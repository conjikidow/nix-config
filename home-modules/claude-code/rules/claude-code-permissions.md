# Claude Code Permissions

How the Git and tooling rules meet Claude Code's permission settings.

- Claude Code's read-only auto-approval covers `cd` and read-only `git` forms individually,
  but always prompts when `cd` into a different directory and `git` are combined in one compound command,
  because Git may execute that directory's hooks
  (see [permissions docs](https://code.claude.com/docs/en/permissions#read-only-commands)).
  This holds for a subdirectory of the working directory as well.
  Using `git -C` avoids the unnecessary confirmation.
- A PreToolUse hook enforces the `git -C` rule:
  a `cd <path> && … git …` compound is denied with a reminder to use `git -C`.
  Rewrite it rather than trying to work around the hook.
- `cd` into a directory outside the working directory is not auto-approved
  (read-only `cd` only covers the working directory and additional directories),
  so `cd <path> && gh …` triggers a prompt.
  `gh -R <owner/repo>` keeps the call to a single `gh` command that is auto-approved.
- `pip`, `pip3`, `python -m pip`, and `uv pip` are all denied by permissions.
