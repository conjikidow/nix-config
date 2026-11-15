---
name: code-change-discipline
description: Minimal-diff discipline for editing code — smallest change that satisfies the request, match the surrounding idiom, strict comment policy, no drive-by refactors or speculative generality. Use whenever writing or modifying code in an existing codebase.
---

# Code Change Discipline

The unit of review is the diff.
Every line you touch is a line someone must review, and a line that can regress; spend them deliberately.

## 1. Smallest diff that satisfies the request

- Implement what was asked, not what might be asked next.
  No speculative parameters, no "while I'm here" generalizations, no abstractions with a single caller.
- Do not add defensive padding the failure model does not call for: blanket `try/except`,
  null-checks for values that cannot be null, fallbacks for impossible states.
  Padding hides real bugs and bloats review.
- If you notice an unrelated problem while working, report it in your final message;
  do not fix it in the same diff unless asked.

## 2. Match the surrounding code

- Read the neighborhood before writing.
  Match its naming, error-handling style, comment density, import organization, and test structure —
  even where your own preference differs.
- Reuse existing helpers and utilities instead of re-implementing them;
  search for an existing solution in the codebase before writing a new one.
- New code should be indistinguishable in style from the code around it.

## 3. Comment policy

A comment says **what** a block of code does, never **why**.
The reasoning — the constraint worked around, the alternative rejected, the bug prevented —
goes in the commit message body, where it stays attached to the change that introduced it.

- Write a comment as a statement of what the code does, such as "Set the prompt for interactive shells only."
- Cut "so that …" and "because …" clauses; they carry the why.
- Never explain why your change is correct or what it replaced — that is reviewer-talk, noise the moment the change lands.
- Never restate the function name in sentence form.

This holds in every file type: source code, shell scripts, Nix modules, tests, and CI configuration.

When editing, preserve existing comments unless they become false; update the ones your change invalidates.

## 4. Deleting and rewriting

- Prefer editing existing code over rewriting a file; rewrites destroy history and hide the actual change from review.
- Before deleting code, confirm it is actually dead: check for callers, dynamic references, and exports.
- Do not delete or weaken a failing test to make the suite pass; fix the code or report the conflict.

## 5. Self-check before finishing

Diff your own change and ask:

- Does every hunk serve the request? Remove the ones that do not.
- Would a reviewer ask "why is this here?" about anything? Either you can state its reason, or the hunk goes.
  Give the reason in your report, and in the commit message body once you are asked to commit.
- Did formatting-only churn slip in (re-wrapped lines, import reshuffles in untouched code)? Revert it.
