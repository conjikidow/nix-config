# Markdown

In Markdown, line breaks in the source file are not reflected in the rendered output.
Breaking lines at points that do not match sentence boundaries makes the source harder to read.

## Line Break Rules

- Do NOT break a line in the middle of a sentence.
- DO break a line at sentence boundaries.
- As a rule, keep each sentence on a single line.

## When a Line Is Too Long

Only when a line triggers a markdownlint line-length error (`MD013`) MAY you break it mid-line.
In that case, break at the most semantically natural point (e.g. a comma) to resolve the error.

You do NOT need to count characters yourself.
Fix a line only when markdownlint actually reports it as failed, e.g. via a pre-commit hook or CI.
