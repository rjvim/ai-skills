---
name: rjv-gated-build
description: "Use automatically for financial/money, production-safety, security, destructive, high-blast-radius, zero-debt, multi-agent, or phase-reviewed builds where an INDEPENDENT reviewer must approve each slice—even when the user never says 'gated build'. Compose with `rjv-work-plan` and `rjv-spec-driven`: durable acceptance criteria live in `spec.md`; the plan holds cast, active criterion IDs, evidence, grill trail, and RESUME HERE. Enforce spec grill before code, ID-bound WORK/REVIEW, explicit APPROVED/REJECTED loops, crash/compaction durability, and model-economy routing (via `rjv-subagents-claude` / `rjv-subagents-codex`). Triggers also include: gated build, grill each step, adversarial review, overnight run, high-stakes build, human QA gate, or repeated review rejections."
---

# Gated build: adversarial multi-agent construction

For work where being *plausibly wrong* is expensive. One agent cannot reliably
catch its own errors, because the blind spot that produced the bug also reviews
it. Quality comes from **independence**: a second agent whose job is NO-AGREE,
grilling every step to an explicit APPROVED.

Economics: compress everything agents read (specs, notes, grill prompts) so you
can afford a second agent to disagree. Efficiency funds redundancy.

## 1. Casting the roles → `CASTING.md`

Three roles: **Orchestrator** (holds anchor doc, casts, integrates), **Author**
(drafts), **Reviewer** (grills to APPROVED). Cast each role for the task in hand.

- **The human casts the orchestrator at launch. ASK them.**
- **Reviewer ≥ author strength, and independent.** Above mechanical work,
  self-review does not count as review. Prefer cross-vendor for the grill.
- **Record the cast once** in the anchor plan's `## Cast` (`rjv-work-plan`), models
  named. Every resume obeys it; recasting is a logged Decision with a why.
- **The human is also a reviewer.** Surface designs at phase boundaries.

Read [`CASTING.md`](./CASTING.md) at build start or when recasting: the
orchestrator-choice table (Opus / Sonnet / Codex and the reviewer each requires),
the author×reviewer pairings, execution bindings for each cast, and the evidence
behind the two hard rules.

## 2. Grill the durable SPEC before any code

The highest-leverage grill is pre-implementation. Source build: the reviewer's
round-1 verdict on the *design* was "not buildable as written", with 10 ranked
attack scenarios, 8 valid. Fixing pre-code cost a doc rewrite; post-code it would
have cost the build.

- A gated build runs as `Build mode: gated + spec-driven` (`rjv-work-plan`), so
  `rjv-spec-driven` is always loaded. Acceptance criteria live in
  `_docs/features/<area>/spec.md`. The plan links the spec and carries only the
  active criterion IDs plus the compressed grill trail.
- Prompt: "ATTACK this design and criteria. Ranked failure scenarios. Verdict: AGREE /
  NO-AGREE with blockers."
- Iterate spec → attack → amend until AGREE. Record each round in the anchor doc
  (v1 → v2 → v2.1…), noting objections accepted *on merit* and those rejected,
  with reasons.
- A reviewer that never says NO-AGREE is not reviewing. Instant approvals every
  round → sharpen the prompt (§4) or recast.
- Issue `WORK` only after the human agrees with the criteria and the independent
  reviewer returns AGREE. Every active criterion has a permanent ID.

## 3. The gated loop (per implementation step)

```
agreed spec IDs → red proof → implement → self-review + smoke → REVIEWER GRILL by IDs → fix → re-grill … → APPROVED → commit → next IDs
```

Stop rules are part of the spec. Write them explicitly per step with this
template:

```
loop step: reach [verifiable end state], only touching [scope],
stop after [success cond] OR [N iters] OR [$/token budget], verifier = [test/build/screenshot].
```

- **Spec first.** Durable criteria live in `spec.md`; the anchor plan names the
  active IDs before coding. Grading against criteria invented mid-code blesses bugs.
- **ID-bound commands.** `WORK`, handoff, and `REVIEW` name the same criterion IDs
  (command table in `rjv-spec-driven`). Behaviour discovered mid-flight pauses the
  slice until its criterion is agreed.
- **Self-review + throwaway smoke** before handoff. It catches the dumb bugs
  cheaply, so the reviewer's rounds go to subtle ones.
- **Grill to an explicit APPROVED.** One round-trip is not review.
- **Park instead of rubber-stamping.** Cap rounds per step (~6). Still blocked →
  write the open blockers to the anchor doc and STOP that step. "Parked, here's
  why" beats a faked approval. This is non-negotiable when money or safety is at
  stake.
- **Living plan / reach-backs.** A grill that invalidates an EARLIER approved step
  → reopen, fix, re-test, re-grill, LOG the reach-back. A locked-in wrong step is
  worse than a reopened one.

Done when: the step has an explicit APPROVED and is committed, or it is parked
with its blockers written to the anchor doc.

## 4. Driving the reviewer: prompt rules

The reviewer posture and verdicts (`APPROVED` / `REJECTED` / `SPEC-GAP`) are
defined in `rjv-spec-driven`. Put these rules into every grill prompt:

- **REVIEW ONLY.** First line: "REVIEW ONLY — do not modify files, do not
  implement." The reviewer reads, reasons and votes.
- **Review the invariant.** Start by writing the rule the slice claims to
  establish. Then attempt to violate that rule without reverting the author's
  exact edit. A proof that only recognizes the syntax just fixed is not a gate.
- **Audit every load-bearing hop.** Trace producer → contract/type → adapter/wrapper →
  consumer → failure UI. Inspect every declared return type and failure semantic. If
  the change makes an adjacent file load-bearing, that file is inside review scope
  even when the author did not edit it.
- **Invent bypasses before approval.** For every new architecture/static gate, try at
  least: alternate initialization, object/wrapper state, indirection/helper, and a
  different but valid syntax. Record the attempted bypasses and their red result.
  A fixture copied from the original bug is necessary but insufficient.
- **Prove the negative path.** Success screenshots do not prove rejection, rollback,
  cancellation, retry, hidden/conditional fields, or duplicate input. Exercise the
  failure that the contract exists to carry, plus one nearby non-regression.
- **Missing test infrastructure is a blocker.** A regex scan may enforce file
  ownership or forbidden dependencies; it cannot prove async settlement, React
  state, or rendering behavior. If no runner can execute the invariant, return
  `REJECTED`/`SPEC-GAP` and propose the smallest harness. **Do not add a
  dependency without human approval.**
- **Every discovered defect counts, pre-existing or not.** It is registered and
  keeps the verdict red until fixed, disproved, deduplicated, or explicitly
  accepted by the human. “Unchanged,” “non-blocking,” and “later” are not
  dispositions.
- **You run the tests; the reviewer reads.** Reviewer sandboxes hang on
  execution. Run the suite yourself and paste results ("suite already run: N
  passed, review by reading the code"). The reviewer may read files and never
  executes.
- **Name the failure modes.** Exact files, spec section, numbered hunt-list. Money
  code: double-exposure, oversell, lost/duplicated intent across restart, ordering
  races, idempotency, fees/precision, the risky path just written. Vague prompts
  give vague reviews.
- **Bound every grill you start yourself (only when the Cast names a
  self-started reviewer); cancel-first on timeout.** Run it in the background
  with a 15 min wall-clock cap. This cap is a stop rule owned here, because
  reviewer sandboxes hang; the box in `rjv-subagents-claude` is sizing advice
  only. Timeout → cancel FIRST, verify nothing is running,
  relaunch fresh, kill orphans. Cap relaunches (~3). A persistent no-verdict is a
  tooling failure: park the step and report it.

Reviewer handoff must include this compact evidence table:

```text
criterion | invariant | boundary hops inspected | bypasses attempted | negative proof | verdict
```

If any cell is empty, the criterion is not ready for `APPROVED`.

## 5. The anchor document → `ANCHOR-DOC.md`

One compressed working-memory doc **per build**, living inside `rjv-work-plan`'s
`.plans/<branch>.md`. Conversation is disposable; the anchor doc is not. It obeys
the plan's ~400-line ceiling (owned by `rjv-work-plan`); over it, compress BEFORE
acting.

Read [`ANCHOR-DOC.md`](./ANCHOR-DOC.md) when setting up the plan's sections, when
deciding where a fact belongs, or when the plan is nearing the ceiling: the owned-
sections table (GOAL, EVIDENCE LEDGER, INVARIANTS, DESIGN vN, TOMBSTONES, …), the
caveman register rule for agent-read text, the no-later rule, and the promotion
mandate that says what collapses to where.

## 6. Staying alive → `RUNTIME.md`

**Keep all state on disk; the live conversation can drop at any time.** Rewrite
`>>> RESUME HERE <<<` at the END of every step; commit each approved step
immediately; hand the grill to a background command or a watcher subagent
(`rjv-subagents-claude` §7); the host wakes you when it exits. Never sleep or
poll for it. Keep steps idempotent so a mid-step re-entry is replay-safe.

Read [`RUNTIME.md`](./RUNTIME.md) after a drop, compaction or wake, before a long
or overnight run, and when driving an OpenAI Codex CLI reviewer (cancel-first on
timeout, pkill orphans, why its sandbox can't run your tests).

## 7. Model economy → `rjv-subagents-claude` (Codex: `rjv-subagents-codex`)

Load `rjv-subagents-claude` (Codex: `rjv-subagents-codex`) before delegating
anything: who does the work, which model, the brief and the time budget. Reviewer
grills take a 15 min cap (§4). Who may author and who must review is in
[`CASTING.md`](./CASTING.md).

## 8. Scope honesty, especially for financial systems

State in one line what "done" covers. "Reviewer-APPROVED through step N" ≠
"validated against reality" if the run only exercised a simulator/paper path.
Keep dangerous gates (live trading, prod deploys, destructive ops) **physically
off** until a separate explicit validation phase with its own gate (paper-parity,
fill-ratio bands, fail-closed thresholds). Never let "approved" read as
"safe to ship."

---

**One-line invariant:** independent reviewer + compressed on-disk state + scheduled
self-wakes = a run that converges to correct and survives every hang, drop, and
compaction.

*Provenance: distilled from a live high-stakes build (options trading bot, 2026-07:
6+ grill rounds, real NO-AGREEs, a human-caught design hole, losses studied at tick
level) + a verified local-model delegation spike. Register + spec-section ideas
credited to the caveman/cavekit family (github.com/juliusbrussee).*
