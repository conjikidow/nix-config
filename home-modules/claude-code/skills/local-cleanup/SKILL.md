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
2. Verify the merge actually happened: `gh pr view <num> --json state,mergedAt` must report `MERGED`.
3. In the main worktree (listed first by `git worktree list`), not in a worktree created for this work:
   `git switch <default-branch>` then `git pull --ff-only`.
   Run the remaining steps from there as well.
4. For each merged branch, confirm it holds nothing beyond the PR:
   its tip must equal the PR's last head commit (`gh pr view <num> --json headRefOid`).
   If it differs, report the branch and leave both it and its worktree in place.
5. Remove leftover temporary files created for the PR, such as `.pr-body.md`,
   from the main worktree and from any worktree created for this work.
6. Remove those worktrees (`git worktree remove <path>`, without `--force`), if applicable.
   A branch still checked out in a worktree cannot be deleted, even with `-D`.
   If the removal is refused, the worktree still holds modified or untracked files:
   report them and leave the worktree and its branch in place.
7. Delete the merged local branches with `git branch -d`.
   If `-d` refuses (squash-merged branches are not detected as merged), use `-D` for a branch that passed step 4.
8. `git fetch --prune`.

Use `git -C <path>` for repositories outside the current working directory.

## Boundaries

- Only delete branches whose PRs are confirmed merged; never touch unrelated branches.
- If a branch has unpushed commits or its PR is not merged, report it instead of deleting.
- Finish with a one-line report per repository: which branch was deleted and the new tip of the default branch.
