# Git Commands

## Operating on a repository outside the working directory

When running Git against a repository that is not the current working directory,
use `git -C <path> <subcommand>` instead of `cd <path> && git <subcommand>`.

This holds **even when the target repo is a subdirectory of the working directory**:
a subdirectory is still a different directory.
If the working directory is `/repos` and the repo is `/repos/app`, use `git -C /repos/app …`,
not `cd /repos/app && git …`.

When chaining several Git commands, **repeat `git -C <path>` for each one** — do not `cd` once and then run bare `git`.
The extra verbosity is intended.

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

## Operating on a GitHub repository outside the working directory

The same principle applies to `gh`: when the working directory is not the target repository,
pass the repo explicitly with `gh -R <owner/repo>` (equivalently `--repo`) instead of `cd <path> && gh <subcommand>`,
for the subcommands that accept it, such as `gh pr`, `gh issue`, `gh run`, `gh release`, and `gh workflow`.

- `gh repo` subcommands take the repository as an argument instead: `gh repo view <owner/repo>`.
- `gh api` has no `-R`: write the owner and repo into the endpoint path, such as `gh api repos/<owner>/<repo>/pulls`.

Unlike `git -C`, which takes a filesystem path, `gh -R` takes the `owner/repo` slug (or a GitHub URL).
If you don't know the slug, derive it with `git -C <path> remote get-url origin` first.

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
  or a lint fix that does not change behavior, stage only that fix, and retry the same commit.
  Report any other failure, such as a failing test, a logic error, or a fix needed in another file,
  and wait for instructions.
- If hooks auto-modified files, review the changes.
  Stage and retry only when they are of the same mechanical kind and limited to the files being committed;
  otherwise report what the hooks changed and wait for instructions.
  If a changed file also held unstaged changes before the commit, staging it would take those in as well:
  report it and wait instead.
- If the correct fix is to change the hook/lint rule itself (e.g. a false positive),
  propose the change to the user and get approval first; NEVER modify hook or lint rules unilaterally.
- When committing, keep an approved hook/lint rule change in its own commit, separate from code changes.
