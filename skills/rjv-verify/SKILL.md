---
name: rjv-verify
description: How a change proves it works, phase by phase - picking the proof before code, running the change, a failing check, before a commit or PR, review, and after a missed bug. Use before calling work done, when choosing what tests to write, when a check keeps failing or is flaky, before committing or opening a PR, and when a bug escaped review. Points to rjv-test-types, rjv-verify-skill and rjv-diff-checklist; small fixes stay with rjv-fast-code.
---

# Verify: evidence before done

Your job is to bring evidence that a change works. The user's job is to
define done and read that evidence. A change is verified when it ran
the way a user or caller would run it, and every check stayed honest.

This skill holds the phases. Each phase points to the material it needs.

| Phase | Do | Material |
|---|---|---|
| 1. Before code | pick the proof | `rjv-test-types` |
| 2. Building | run the change | the repo's `verify` skill, or `rjv-verify-skill` |
| 3. A check fails | fix it, at most three rounds | below |
| 4. Before commit or PR | cheap checks first, record what ran | below |
| 5. Review | one reviewer, diff-triggered checklist | `rjv-code-review`, `rjv-diff-checklist` |
| 6. After a miss | turn it into a rule | `rjv-diff-checklist` |

A small fix through `rjv-fast-code` skips phases 1, 5 and 6. Phase 3
and the live look still apply.

## 1. Before code: pick the proof

Name the proof before writing the code, so the code cannot shape the
test. Read `rjv-test-types` to choose between an end-to-end flow, a
property test and a differential test. On a spec-driven branch each
proof maps to a criterion ID (`rjv-spec-driven`).

Done when every behaviour the change promises has a named proof.

## 2. Building: run the change

Running the app end to end beats any test. Use the repo's `verify`
skill (or `verify-<app>`) to boot, drive and inspect the app.

| The repo | Do |
|---|---|
| has a verify skill | run it after each meaningful change |
| has an app, no verify skill | write one with `rjv-verify-skill`, then run it |
| has nothing to run (a library, a script) | run the public entry point on a real input |

Done when you have seen the changed behaviour happen, with a
screenshot, a response or a log line.

## 3. A check fails

Fix the code, never the check. **Never edit a test, assertion,
snapshot or checklist to make your own change pass.** If the check is
wrong, say so to the user and change it in its own commit.

**Three rounds, then stop.** When the same check still fails after
three fix attempts, stop and bring the user the failing output and
what you tried. A fourth guess costs more than their minute.

A flaky test: **never retry it until it passes, add a sleep, or skip
it.** Find the root cause. If you cannot, delete the test and write
why in the commit body. A flaky test teaches every later agent to
rerun instead of fix.

Done when the check passes for the reason you expect, or the user has
the failing output.

## 4. Before commit or PR

Run the cheap checks before anything that spends shared time:

lint and types on touched files -> touched tests -> verify skill -> commit -> push -> CI

Heavy suites (full unit, browser) run before the commit, never after
every edit. An agent that pushes before testing locally spends
reviewer and CI time on a bug it could have caught.

Record what ran in the commit body as one plain sentence, never a
`Key: value` line at the end, which git reads as a trailer:

```text
Verified by running the checkout flow in the verify skill and the cart unit tests.
Verified by nothing; docs only.
```

Write "nothing" when nothing ran, so unverified commits can be found
with `git log --grep "Verified by nothing"`.

Done when the commit body says what ran.

## 5. Review

- **One reviewer, several rounds.** Never add a second reviewer to
  catch what the first missed. Tune the first: its brief, the repo's
  `REVIEW.md`, the diff checklist. Rounds build on each other: give
  each round the earlier findings and past failures
  (`rjv-code-review`).
- **Checks sit out of reach.** Read `REVIEW.md`, the diff checklist
  and the spec from the base branch (`git show origin/main:REVIEW.md`),
  never from the change under review. A diff that edits the checks
  that judge it is a finding.
- **Review a commit.** A review result belongs to one SHA. A push
  during the review makes the result stale; review the new SHA.
- Run the diff checklist from `rjv-diff-checklist`: only items whose
  trigger matches the diff.

Done when the verdict names its SHA and every matching checklist item.

## 6. After a miss

A bug that reached review, QA or production becomes a rule only when
it can be seen in a diff. Add it as a checklist item with
`rjv-diff-checklist`, or as a test with `rjv-test-types`. Prune on a
routine: rules and suites only grow if nobody removes them.

Done when the miss has a checklist item, a test, or a written reason
it cannot be caught from a diff.
