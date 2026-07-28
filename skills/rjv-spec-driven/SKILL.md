---
name: rjv-spec-driven
description: "Use BEFORE coding any real feature, architecture/foundation, public SDK/API/contract, state machine, durable-data change, multi-app/multi-actor journey, embedded feature, or branch with multiple implementation/review slices—even when the user never says 'spec'. Also use for acceptance criteria, requirements docs, glossary/ubiquitous language, ADRs, reviewing a diff against requirements, or answering what behavior is live. Create `_docs/features/{area}/spec.md` with permanent criterion IDs and one test per criterion; bind WORK, handoff, REVIEW, and QA to those IDs. No criterion is met without a passing mapped test, and no QA/ship approval is allowed while any criterion is GAP. Compose with `rjv-work-plan`; high-stakes or multi-agent work also requires `rjv-gated-build`."
---

# Spec-driven — durable truth + acceptance criteria

The durable half of the workflow. Where `rjv-work-plan` holds *volatile* branch
state, this owns what's *permanently true*: the spec (as testable acceptance
criteria), the glossary, and the decision records. Load it when a branch is worth
speccing — a real feature/behaviour change — not for a typo fix (proportional; see
`rjv-work-plan`). `rjv-work-plan` is the always-on backbone; this layers on top, the
way `rjv-gated-build` does.

Model: **there is no prose "how it works today" doc** (it rots). Durable truth =
(1) acceptance-criteria spec that carries its own test-backed status, (2) glossary,
(3) ADRs. "What's true today" = code + tests + these three.

## Three durable artifacts — each has a bundled format

| Artifact | Home | Format | Holds |
|---|---|---|---|
| **Spec** | `_docs/features/<area>/spec.md` | [SPEC-FORMAT.md](./SPEC-FORMAT.md) | requirements AS acceptance criteria (`U1`, `U2`…), 1 criterion = 1 test, per-group status |
| **Glossary** | `CONTEXT.md` / `<area>/CONTEXT.md` | [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md) | ubiquitous language, terms + `_Avoid_` |
| **ADRs** | `docs/adr/NNNN-*.md` | [ADR-FORMAT.md](./ADR-FORMAT.md) | decisions + why, immutable after first commit |

Read the format file when authoring that artifact. **One-shot rule for the AI:**
produce EXACTLY the structure in the format file — fill the template, the worked
example is the target shape, do not invent sections or renumber IDs.

## The spec is the driving spec (proportional)

- **Small branch** → a one-line intent in the `rjv-work-plan` plan. No spec doc.
- **Real feature** → a `spec.md` in the format BEFORE code. Criteria are the build
  target; the engine "passes" only when every criterion holds in code.
- The spec spans the lifecycle in ONE doc: written planned → drives the build →
  its status block reports what's live. It never becomes a separate "behaviour doc".

## Mandatory activation gate

Do not rely on the phrase “substantial enough.” Load this skill and create/link the
spec before code when ANY item is true:

- more than one meaningful implementation slice;
- architecture/foundation, public API/SDK/contract, state machine, durable data, or migration;
- multiple apps, actors, journeys, providers, callbacks, jobs, or embedded Features;
- multiple author/reviewer agents, repeated review rounds, or a human QA gate;
- financial, production, security, or other high-blast-radius behaviour;
- planning agreement can plausibly drift during implementation.

Only a one-slice, low-risk change whose complete intent fits in one sentence may stay
plan-only. Uncertainty means spec it. Record the result as `Build mode` in the branch
plan. If high-stakes or independently reviewed, use `gated + spec-driven` and load
`rjv-gated-build` too.

Before the first `WORK` command:

1. Write the spec in the bundled format.
2. Grill the criteria with the human and, for gated work, an independent reviewer.
3. Resolve objections until the spec is agreed.
4. Add the spec to the plan's Source of Truth.
5. Put exact active criterion IDs in `RESUME HERE` and the author prompt.

## Real-time promotion + the mutation test

Settled facts leave the volatile plan the instant they crystallize (a branch commit
that merges with the code — see `rjv-work-plan`). The test for where a fact goes:

> If working on this branch *changes* the doc → it's PLAN state (`rjv-work-plan`).
> A durable artifact (spec criterion, term, decision) changes only via a deliberate
> promotion — never as running scratch.

- Term settles → `CONTEXT.md` now. Hard decision made → ADR now. Criterion agreed →
  `spec.md` now. Never parked in the plan for "later".
- **ADR exception to mutation:** promotion creates an ADR; it does not reopen one.
  Once an ADR has any git history, never edit, rename, replace, or delete it. A
  reversal or correction creates the next numbered ADR with `Supersedes: ADR NNNN`
  and leaves the original byte-for-byte untouched. Read `ADR-FORMAT.md` before
  authoring or superseding one.

## Status is DERIVED, never hand-maintained

The spec's per-group status block is regenerated at reconcile, not remembered:

```
run the suite → map each criterion ID to pass/fail (via test name / @spec tag)
→ rewrite the status block: Met + tested = passing, GAP = failing/absent
→ stamp `verified <YYYY-MM-DD>`
```

So the spec can't drift from reality — reality (the suite) writes the status. This
is the answer to "what does the system do today": you don't maintain it, you
regenerate it. IDs are append-only and never reused, so a criterion means the same
thing across the system's life.

## Bind commands to criterion IDs

The spec drives execution only when every command is ID-bound:

```text
WORK <IDs>   → author changes only those criteria; first records red proof
HANDOFF      → ID → test → result → files; list deviations as GAP, never improvise
REVIEW <IDs> → vote on Spec axis and Standards axis separately
QA / SHIP    → forbidden while any criterion is GAP or lacks a mapped passing test
```

Hard rules:

- Never issue a prose-only `WORK` command on a spec-driven branch.
- A criterion's test name or `@spec` tag carries its permanent ID.
- Add the failing test before implementation; confirm it fails for the intended reason.
- Behaviour discovered mid-flight becomes a proposed criterion and is agreed before
  its fix. Do not silently expand the contract while coding.
- Scope creep is a Spec-axis rejection even when the code is clean.
- A review finding is unresolved until fixed, disproved, deduplicated, or explicitly
  accepted by the human; “later” and “non-blocking” are not dispositions.
- Reconcile status from fresh test results. Old green output does not carry across edits.

Use `scripts/check_spec_coverage.py <spec.md> <test-root> [<test-root> ...]` to fail
on duplicate criterion IDs or criteria with no test reference, and to print where each
ID is mapped. Point it at test roots only — any file mentioning an ID counts as a
mapping. This checks mapping; the relevant suite still proves pass/fail.

## Reviewing against the spec — the Spec axis

Adapted from mattpocock/skills `code-review` (two-axis). Review a diff on **two
separate axes so neither masks the other** — report them apart, don't merge:

- **Spec** (this skill's axis): does the diff faithfully implement the originating
  `spec.md`? Report (a) criteria asked for but missing/partial; (b) behaviour not
  asked for (scope creep); (c) criteria that look done but implemented wrong. Quote
  the criterion ID for each finding. If a criterion has no test, that's a Spec-axis
  finding, not a pass.
- **Standards** (companion axis): does it follow the repo's documented standards,
  plus a Fowler smell baseline (mysterious name, duplication, feature envy, data
  clumps, primitive obsession, shotgun surgery, speculative generality…)? Documented
  repo standard overrides the baseline; skip what tooling already enforces.

A change can pass one axis and fail the other (right thing / wrong style, or clean
style / wrong thing) — that's why they stay separate.

Reviewer output ends with exactly one verdict:

- `APPROVED` only when every assigned ID is implemented, mapped to a passing test,
  contains no scope creep, and the Standards axis has zero unresolved findings.
- `REJECTED` with each finding attached to a criterion ID, or `SPEC-GAP` when the
  behaviour has no agreed criterion yet.

## Realigning existing docs to the format

A pure-docs sweep ("redo all docs to the format") is still branch work: run
`rjv-work-plan` for the resumable plan (inventory + conformance status), use the
format files here as the "done" target, delegate the mechanical rewrites (cost
rules in `rjv-gated-build` §7 / `rjv-codex-ollama-subagents`), flagship judges
conformance. No separate migration skill — it composes.

## Don't invent

Docs and reality disagree → **reality wins**. Fix mutable specs/glossaries and cite
the source (test, `file:line`, commit). For a committed ADR, record the correction
in a new successor ADR—never rewrite the historical record. A spec criterion with
no test is not "done" — it's a GAP, and the status block must say so.

---

*Steals from mattpocock/skills (`domain-modeling` CONTEXT/ADR formats, `code-review`
two-axis + Fowler baseline), stripped of issue-tracker coupling for flat-file use.
Spec-as-acceptance-criteria format + test-backed status from a live financial build.*
