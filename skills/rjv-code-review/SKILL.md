---
name: rjv-code-review
description: "Review a code change, a proposed fix or a design for behavioral regressions, especially when a prior review missed a bug. Also runs the round-numbered review loop: Claude writes a brief file for Codex or opencode, the user relays it, the reviewer writes a result file, every path absolute. Use for PR reviews, design reviews, follow-up review rounds, writing a review brief, reading a review result, and claims that a fix is clean. Works in Claude Code and Codex."
---

# Code review: prove the neighboring behavior

Review the behavior users can reach. A passing test and a plausible diff do not prove that an old path still works. Load the repository's domain and product review skills too when the change touches their area. A review is read-only: edit, stage or commit nothing in the repo. The only file you write is the result file or the reply.

A stated scope limits what you report on. It does not limit what you read. When an existing rule, producer or feature the change depends on sits outside the scope, read it anyway and report the gap as a finding: "the brief put X out of scope, and the change depends on it". **Base a clean verdict only on code you read**, never on code the scope told you to skip.

When you run the review loop with Codex or opencode (writing a round brief, reading a round result, or cleaning up the round files under `~/.reviews/`), read [`ROUNDS.md`](ROUNDS.md). **Never start a reviewer (Codex or opencode) yourself unless the user asks in this session or the plan's Cast (`rjv-gated-build`) names a self-started reviewer**; otherwise the user relays each file by hand.

## Before judging the diff

1. State the behavior the change promises and the old behavior it must preserve.
2. Trace each changed route or entry point through its caller, state read, decision, write, and downstream reader. Include unchanged files that are load-bearing in that chain, including any outside the requested scope.
3. Search for an existing feature that already does part of the job: shows, hides, prefills, skips, defaults or verifies the same value or step. Search by behavior (the field, the step, the status); the diff's own names miss older code. A new path should build on that feature or state why not. A second, parallel rule for the same decision is a finding.
4. Find the domain's existing predicate or policy for every new condition. Compare the new condition with all callers of the old one. Check legal boundary values such as `null`, empty string, missing key, incomplete record, and stale record. A display status is not automatically the authority for an access or redirect decision.
5. For every changed write, list all current producers and owners of that value: user input, signup identity, imported or prefilled data, provider response, existing record, and configuration. Read the existing precedence and preservation rules before approving a new source or overwrite.
6. Check the order of existing guards and migrations. A new fast path at the start of a route must not write before a completed-state guard, ownership check, or lazy migration that the old path reached first.

Done when every changed write has its producer list and every new condition is compared with the existing predicate.

## Disprove the change

Choose concrete, reachable states at the intersections the diff creates:

- new record, resumed record, edited record, and record created before the switch or fix;
- default and enabled configuration, including tenant or account modes that alter field ownership;
- missing, partially verified, fully verified, and previously verified values from a different source;
- first visit, reload, direct link, and the path after a failed submission.

For each chosen state, follow the resulting route, visible fields, stored values, verification state, and downstream payload. Compare a new fast path with the existing form or workflow it replaces. Check that a field's hide or skip decision refers to the same value the form or fast path will submit; a verified account column does not validate stale step data. If the old workflow deliberately lets the user edit a value, check that the value stays editable after an automatic fill. If an existing producer marks a value verified, find its other sources before treating signup as the only one.

Treat facts supplied in a review brief as claims to check. Verify the facts that carry the decision and look for a legal state they omit. Tests are evidence for their exact fixture only: inspect whether the fixture covers the competing producer, boundary value, and old feature. A test that asserts the new implementation's output can still encode the wrong product contract.

Done when every chosen state has a traced outcome or a named reason it is unreachable.

## Follow-up rounds

Review the new commits against the last reviewed SHA. First check whether each old finding is fixed. Then treat every new branch, read, write, and call site introduced by the fix as a fresh change. Re-run the preservation states; a fix that solves the reported fixture can break an adjacent path. Withdraw a prior finding only with the specific code evidence that disproves it.

Done when every old finding is marked fixed, open or withdrawn with code evidence.

## Design reviews

The same checks, with a design doc in place of a commit range (in the loop, the same files too). The reviewer tries to disprove the design before any code exists:

- Run step 3 of "Before judging the diff" against the design: find the existing feature, predicate or producer that already owns the decision.
- Walk the states from "Disprove the change" through the design: new, resumed and old records; each tenant mode; failed and reloaded paths.
- For every value the design writes, name its current producers and who wins.
- List every decision the design leaves open. An open question that changes behavior is a finding.

Done when every open decision is listed.

## Writing a brief for another reviewer

The brief steers the review, so a blind spot in it becomes a blind spot in the review.

- Name the prior art you know: existing features, predicates, producers and modes in the area, with where they live.
- Tell the reviewer to run step 3 of "Before judging the diff" (search by behavior for existing features) before judging the diff.
- Keep every existing producer, predicate and replaced form in scope. Scope out only code the change cannot reach.
- Give the claim to disprove and leave your conclusion out. Label every fact as checked in code, or not checked.
- On a follow-up round, give the last reviewed SHA, each old finding, and the commit that claims to fix it.

Done when every fact in the brief carries checked or not checked.

## Report

For every finding, give the wrong behavior, reachable caller chain, affected state, severity, and the existing rule it violates. Distinguish observed runtime behavior from code inference. Name what was inspected and what was not run. Say "code review clean" only after every state you chose under "Disprove the change" and every negative path has evidence: code read, a test, or a run. If runtime or delivery checks were required but unavailable, keep the overall verdict inconclusive; never promote a code-only pass to product approval.

## Escape that shaped this skill

An onboarding review followed a new redirect's derived status string but missed the account's existing `isOnboardingComplete()` rule. An empty provider id made those answers disagree and could send an existing account to the new-account form. A later fix copied verified signup contact over existing account contact, missing provider prefill and the multiple-account mode where contact remains editable. The earliest catch was a canonical-predicate search and a producer/ownership map before accepting either change. On the follow-up review, repeat those checks for the fix itself.

Two review rounds passed the contact fill because the brief put the contact form and its flows out of scope, never named the page's existing rule that hides verified fields, and the reviewer stayed inside the brief. A search for an existing feature that already hides or skips the same fields would have found it in one step.
