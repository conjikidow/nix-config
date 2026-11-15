# Git Commands

## Operating on a repository outside the working directory

When running Git against a repository that is not the current working directory,
use `git -C <path> <subcommand>` instead of `cd <path> && git <subcommand>`.

This holds **even when the target repo is a subdirectory of the working directory**:
a subdirectory is still a different directory, so `cd <subdir> && git …` triggers the prompt.
If the working directory is `/repos` and the repo is `/repos/app`, use `git -C /repos/app …`,
not `cd /repos/app && git …`.

When chaining several Git commands, **repeat `git -C <path>` for each one** — do not `cd` once and then run bare `git`.
The extra verbosity is intended.

Reason: Claude Code's read-only auto-approval covers `cd` and read-only `git` forms individually,
but always prompts when `cd` (into a different directory) and `git` are combined in one compound command,
because Git may execute that directory's hooks
(see [permissions docs](https://code.claude.com/docs/en/permissions#read-only-commands)).
Using `git -C` avoids the unnecessary confirmation.

Example:

```sh
# Good
git -C /path/to/repo status
git -C /path/to/repo log --oneline -20
git -C /path/to/repo branch -a

# Avoid — cd into a different directory combined with git
cd /path/to/repo && git status && git log --oneline -20 && git branch -a
```

This applies whenever the target repo differs from the working directory —
including when the working directory is not a Git repo at all.

A PreToolUse hook enforces this: a `cd <path> && … git …` compound is denied with a reminder to use `git -C`.
Rewrite it rather than trying to work around the hook.

## Operating on a GitHub repository outside the working directory

The same principle applies to `gh`: when the working directory is not the target repository,
pass the repo explicitly with `gh -R <owner/repo>` (equivalently `--repo`) instead of `cd <path> && gh <subcommand>`,
for the subcommands that accept it, such as `gh pr`, `gh issue`, `gh run`, `gh release`, and `gh workflow`.

- `gh repo` subcommands take the repository as an argument instead: `gh repo view <owner/repo>`.
- `gh api` has no `-R`: write the owner and repo into the endpoint path, such as `gh api repos/<owner>/<repo>/pulls`.

Unlike `git -C`, which takes a filesystem path, `gh -R` takes the `owner/repo` slug (or a GitHub URL).
If you don't know the slug, derive it with `git -C <path> remote get-url origin` first.

Reason: `cd` into a directory outside the working directory is not auto-approved (read-only `cd` only covers the working
directory and additional directories), so `cd <path> && gh …` triggers a prompt.
`gh -R <owner/repo>` keeps the call to a single `gh` command that is auto-approved.

Example:

```sh
# Good
gh -R owner/app pr view 344 --json state,mergedAt,headRefName

# Avoid — cd into a different directory just to run gh
cd /path/to/repo && gh pr view 344 --json state,mergedAt,headRefName
```

## When hooks fail

- If a commit is rejected by hooks, never bypass with `--no-verify`.
  Fix a mechanical problem in the files being committed, such as formatting, a typo,
  or a lint fix that does not change behavior, and retry the same commit.
  Report any other failure, such as a failing test, a logic error, or a fix needed in another file,
  and wait for instructions.
- If hooks auto-modified files, review the changes, stage them, and retry the same commit.
- If the correct fix is to change the hook/lint rule itself (e.g. a false positive),
  propose the change to the user and get approval first; NEVER modify hook or lint rules unilaterally.
- When committing, keep an approved hook/lint rule change in its own commit, separate from code changes.
