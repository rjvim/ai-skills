---
name: rjv-code-review
description: Review a code change or a proposed fix for behavioral regressions, especially when a prior review missed a bug. Use for PR reviews, follow-up review rounds, and claims that a fix is clean. Works in Claude Code and Codex.
---

# Code review: prove the neighboring behavior

Review the behavior users can reach. A passing test and a plausible diff do not prove that an old path still works. Use the repository's domain and product review skills alongside this one when they apply. Honor the reviewer's stated scope and read-only limits.

## Before judging the diff

1. State the behavior the change promises and the old behavior it must preserve.
2. Trace each changed route or entry point through its caller, state read, decision, write, and downstream reader. Include unchanged files that are load-bearing in that chain. Stop at the requested scope boundary.
3. Find the domain's existing predicate or policy for every new condition. Compare the new condition with all callers of the old one. Check legal boundary values such as `null`, empty string, missing key, incomplete record, and stale record. A display status is not automatically the authority for an access or redirect decision.
4. For every changed write, list all current producers and owners of that value: user input, signup identity, imported or prefilled data, provider response, existing record, and configuration where relevant. Read the existing precedence and preservation rules before approving a new source or overwrite.
5. Check the order of existing guards and migrations. A new fast path at the start of a route must not write before a completed-state guard, ownership check, or lazy migration that the old path reached first.

## Try to disprove the change

Choose concrete, reachable states at the intersections the diff creates:

- new record, resumed record, edited record, and record created before the switch or fix;
- default and enabled configuration, including tenant or account modes that alter field ownership;
- missing, partially verified, fully verified, and previously verified values from a different source;
- first visit, reload, direct link, and the path after a failed submission where relevant.

For each chosen state, follow the resulting route, visible fields, stored values, verification state, and downstream payload. Compare a new fast path with the existing form or workflow it replaces. Check that a field's hide or skip decision refers to the same value the form or fast path will submit; a verified account column does not validate stale step data. If the old workflow deliberately lets the user edit a value, an automatic fill must not silently remove that choice. If an existing producer marks a value verified, do not assume signup is its only source.

Do not treat facts supplied in a review brief as proof of the conclusion. Verify the facts that carry the decision and look for a legal state they omit. Tests are evidence for their exact fixture only: inspect whether the fixture covers the competing producer, boundary value, and old feature. A test that asserts the new implementation's output can still encode the wrong product contract.

## Follow-up rounds

Review the new commits against the last reviewed SHA. First check whether each old finding is fixed. Then treat every new branch, read, write, and call site introduced by the fix as a fresh change. Re-run the preservation states; a fix that solves the reported fixture can break an adjacent path. Withdraw a prior finding only with the specific code evidence that disproves it.

## Report

For every finding, give the wrong behavior, reachable caller chain, affected state, severity, and the existing rule it violates. Distinguish observed runtime behavior from code inference. Name what was inspected and what was not run. Say “code review clean” only after the selected preservation states and negative paths have evidence. If runtime or delivery checks were required but unavailable, keep the overall verdict inconclusive; never promote a code-only pass to product approval.

## Escape that shaped this skill

An onboarding review followed a new redirect's derived status string but missed the account's existing `isOnboardingComplete()` rule. An empty provider id made those answers disagree and could send an existing account to the new-account form. A later fix copied verified signup contact over existing account contact, missing provider prefill and the multiple-account mode where contact remains editable. The earliest catch was a canonical-predicate search and a producer/ownership map before accepting either change. On the follow-up review, repeat those checks for the fix itself.
