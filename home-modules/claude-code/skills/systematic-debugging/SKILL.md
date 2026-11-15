---
name: systematic-debugging
description: Hypothesis-driven debugging discipline — reproduce first, read the actual error, run the shortest falsifying experiment, and fix the root cause instead of the symptom. Use whenever investigating a bug, test failure, crash, or unexpected behavior, before editing any code.
---

# Systematic Debugging

Debugging is a search problem.
Guess-and-edit turns it into a random walk; the discipline below keeps it a binary search.

## 0. Do not edit code yet

The most common failure mode is patching the first plausible-looking line.
No fix is written until a hypothesis has survived an experiment.

## 1. Reproduce before anything else

- Find the smallest command or input that triggers the failure, and run it yourself.
  A bug you cannot reproduce is a bug you cannot verify as fixed.
- If it is intermittent, run it enough times to know the failure rate;
  that baseline is how you will later prove the fix.
- Record the exact reproduction command; you will run it after every experiment.
- Reproduce only where it is safe: in a local or disposable environment, with inputs that have no external
  or irreversible effects.
  If reproducing would send messages, change a shared or production system, or delete data,
  do not run it without the user's explicit go-ahead; diagnose from the logs, the code, and the recorded evidence instead.

## 2. Read the actual evidence

- Read the full error message and the stack trace, not a skim of the first line.
  The answer is often literally printed (wrong path, `None` where a value was expected, version mismatch).
- Check what changed recently: `git log`, `git diff`, dependency updates, config edits.
  A previously-working system that broke almost always broke because of a change.
- Distinguish the failure site from the fault site.
  Where an exception is raised is often far downstream of where the bad state was created.

## 3. One hypothesis, shortest falsifying experiment

- State the single most likely cause explicitly ("the cache returns stale entries after TTL expiry").
- Design the cheapest experiment that can prove it **wrong** — a log line, a debugger breakpoint, a one-off script,
  a bisect — and run it.
- If the experiment contradicts the hypothesis, discard the hypothesis entirely and form the next one.
  Do not stack a second guess on top of a dead first one, and do not bend evidence to fit.
- Change one variable at a time.
  If you flip two things and the failure disappears, you have learned nothing.

## 4. Bisect when the search space is large

- Over history: `git bisect` between a known-good and known-bad commit,
  in a disposable worktree (`git worktree add --detach <path>`) rather than the one the user works in.
  Always end it with `git bisect reset`, then remove the worktree (`git worktree remove <path>`);
  if the removal is refused, report it and leave the worktree in place.
- Over input: shrink the failing input by halves until it is minimal.
- Over the pipeline: check intermediate state at the midpoint to learn which half owns the fault.

## 5. Fix the root cause, then prove it

- Write the fix only when the request asks for one.
  When asked only to investigate or explain, or when a review comment or CI failure was pasted,
  skip to section 6, report the confirmed cause, and wait (see the workflow-checkpoints rule).
- Fix where the bad state is created, not where it explodes.
  Guards at the crash site that hide upstream faults are symptom patches.
- Re-run the exact reproduction from step 1 and confirm it now passes; for intermittent failures,
  run it against the recorded baseline rate.
- Run the surrounding test suite to check the fix did not break neighbors.
- If you attempted a familiar remedy (restart, cache clear, reinstall) and it worked, keep asking why —
  remedies that work for unknown reasons are bugs still in flight.

## 6. Report with the chain of evidence

State the root cause, the experiment that confirmed it, the fix, and the verification result.
If the cause was never confirmed and the fix is speculative, say so explicitly instead of reporting it as solved.
