# Pull Requests

## Title

Follow [Conventional Commits](commit-messages.md) for pull request titles.
The title becomes the squash-merge commit subject, so the same `<type>(<scope>)[!]: <description>` rules apply.

## Body

- Write in English.
- Keep it concise and focused on the changes made.
- Skip section headings for small PRs — short prose or a few bullets is enough.
  - Only use `## Summary` / `## Background` style sections when the PR is large enough to need them.
- Do not write about routine pre-commit hooks, linters, formatters, or CI checks. These are expected and add noise.
- Do not list every file changed; the diff already shows that.
- Do not include attribution lines like "Generated with Claude Code" or co-author trailers.
- Keep the PR self-contained within its repository:
  do not reference other repositories or their PRs unless explicitly instructed.
- When the PR closes an issue, append `Closes #<num>` on its own line at the end of the body.

## Workflow

- Prepare the body in a local file (e.g. `.pr-body.md`) and pass it with `gh pr create --body-file <path>`.
  Avoid inline `--body "..."` for anything multi-line.
- When the base repository is owned by the user's own account, self-assign with `gh pr create --assignee @me`.
  Check ownership by comparing `gh repo view --json owner --jq .owner.login` with `gh api user --jq .login`;
  for organization-owned repositories, leave the assignee unset.
- Delete the temporary local file after the PR is merged.
