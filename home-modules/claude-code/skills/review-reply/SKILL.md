---
name: review-reply
description: Handle PR review comments in two phases — first interpret and verify the pasted comment without changing any code, then (once a fix is authorized and made) draft a concise ~1-line reply that references the fixing commit hash. Use when the user pastes a reviewer's comment ("というreviewが来た", "どういうこと？", "正しい？") or asks for a review reply ("reviewへの返信を作成して").
---

# Review Reply

## Phase 1 — Triage (a review comment is pasted)

The user pastes a reviewer's comment and asks what it means or whether it is correct.

1. Restate what the reviewer is claiming, in plain terms.
2. Verify the claim against the actual code, CI logs, or official docs.
   Do not take the reviewer's word for it, and do not defend the current code reflexively either.
3. Give a verdict: correct (fix warranted), incorrect (explain why the current behavior is right), or partially correct.
4. Do NOT modify any code in this phase.
   Wait for the user's instruction (see the workflow-checkpoints rule).

## Phase 2 — Reply drafting (the user asks for a reply)

Typical request: "reviewへの返信を1行程度で簡潔に作成して".

- Draft a reply of about one sentence in English — factual, polite, no filler.
- If a fix was made, reference the fixing commit hash (e.g. "Fixed in `abc1234`."),
  optionally with a half-sentence on what changed.
- If no fix is needed, state the reason concisely: intentional behavior, out of scope, tracked separately, etc.
- Present the draft to the user; the user usually posts it themselves.
  Only post via `gh` when explicitly instructed, and reply in the review comment's thread, not as a new issue comment.
