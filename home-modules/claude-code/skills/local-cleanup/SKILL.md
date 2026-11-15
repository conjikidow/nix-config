---
name: local-cleanup
description: Post-merge local cleanup routine. Use when the user says "merged", "local cleanup", "merged. local cleanup", "all merged", "both merged", or similar after PRs have been merged on GitHub — switch to the default branch, pull, delete merged local branches, prune, and remove temporary PR files.
---

# Local Cleanup

The user merges PRs on GitHub themselves, then says "merged. local cleanup".
This means: bring the local repository (or repositories) back to a clean baseline state.
"both merged" / "all merged" covers every repository touched in the recent work.

## Steps (per repository)

1. Identify which repositories and local branches the just-merged PR(s) belong to.
2. Verify the merge actually happened: `gh pr view <num> --json state,mergedAt`,
   or confirm the branch tip is contained in the default branch after pulling.
3. `git switch <default-branch>` then `git pull`.
4. Delete the merged local branches with `git branch -d`.
   If `-d` refuses (squash-merged branches are not detected as merged), confirm the PR state is MERGED via `gh` first,
   then use `-D`.
5. `git fetch --prune`.
6. Remove leftover temporary files created for the PR, such as `.pr-body.md`.
7. Remove any Git worktrees created for this work (`git worktree remove`), if applicable.

Use `git -C <path>` for repositories outside the current working directory.

## Boundaries

- Only delete branches whose PRs are confirmed merged; never touch unrelated branches.
- If a branch has unpushed commits or its PR is not merged, report it instead of deleting.
- Finish with a one-line report per repository: which branch was deleted and the new tip of the default branch.
