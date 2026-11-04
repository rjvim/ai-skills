---
name: rjv-spec-driven
description: "Use BEFORE coding any real feature, architecture/foundation, public SDK/API/contract, state machine, durable-data change, multi-app/multi-actor journey, embedded feature, or branch with multiple implementation/review slices—even when the user never says 'spec'. Also use for acceptance criteria, requirements docs, glossary/ubiquitous language, ADRs, reviewing a diff against requirements, or answering what behavior is live. Create `_docs/features/{area}/spec.md` with permanent criterion IDs and one test per criterion; bind WORK, handoff, REVIEW, and QA to those IDs. No criterion is met without a passing mapped test, and no QA/ship approval is allowed while any criterion is GAP. Compose with `rjv-work-plan`; high-stakes or multi-agent work also requires `rjv-gated-build`."
---

# Spec-driven: durable truth and acceptance criteria

The durable half of the workflow. `rjv-work-plan` holds volatile branch state
and is always on; this skill owns what is permanently true: the spec (as
testable acceptance criteria), the glossary, and the decision records.
`rjv-gated-build` layers on top of both for gated work.

**There is no prose "how it works today" doc**, because it rots. Durable truth is
(1) the acceptance-criteria spec, which carries its own test-backed status,
(2) the glossary, (3) ADRs. "What's true today" = code + tests + these three.

## Three durable artifacts, each with a bundled format

| Artifact | Home | Format | Holds |
|---|---|---|---|
| **Spec** | `_docs/features/<area>/spec.md` | [SPEC-FORMAT.md](./SPEC-FORMAT.md) | requirements AS acceptance criteria (`U1`, `U2`…), 1 criterion = 1 test, per-group status |
| **Glossary** | `CONTEXT.md` / `<area>/CONTEXT.md` | [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md) | ubiquitous language, terms + `_Avoid_` |
| **ADRs** | `docs/adr/NNNN-*.md` | [ADR-FORMAT.md](./ADR-FORMAT.md) | decisions + why, immutable after first commit |

Read the format file when authoring that artifact. **Produce exactly the
structure in the format file:** fill the template, match the worked example's
shape, and keep its sections and ID numbering as given.

## Mandatory activation gate

`rjv-work-plan` owns the classification. Its Build-mode gate holds the one list
of triggers and records the answer as `Build mode` in the branch plan. This
skill is mandatory whenever that reads `spec-driven` or `gated + spec-driven`,
and `rjv-gated-build` is mandatory on top for the latter. Take the mode from the
plan. If you arrived without a branch plan, create one and classify there
first, before code.

- **`simple`** → no plan file and no spec doc; the commit message carries the intent.
- **Either spec mode** → a `spec.md` in the format BEFORE code. Criteria are the
  build target; the component "passes" only when every criterion holds in code.
  The same doc spans the lifecycle: written as planned, it drives the build, and
  its status block reports what is live. It stays the one behaviour doc.

Before the first `WORK` command:

1. Write the spec in the bundled format.
2. Grill the criteria with the human and, for gated work, an independent
   reviewer (`rjv-gated-build` §2 runs that loop).
3. Resolve objections until the spec is agreed.
4. Add the spec to the plan's Source of Truth.
5. Put exact active criterion IDs in `RESUME HERE` and the author prompt.

Done when: the human has agreed the criteria (and, for gated work, the reviewer
returned AGREE), and `RESUME HERE` lists the active IDs.

## Real-time promotion and the mutation test

Settled facts leave the volatile plan the moment they settle, as a branch commit
that merges with the code (`rjv-work-plan`). The test for where a fact goes:

> If working on this branch *changes* the doc → it's PLAN state (`rjv-work-plan`).
> A durable artifact (spec criterion, term, decision) changes only via a
> deliberate promotion, never as running scratch.

- Term settles → `CONTEXT.md` now. Hard decision made → ADR now. Criterion
  agreed → `spec.md` now.
- **ADR exception to mutation:** promotion creates an ADR and never reopens one.
  A committed ADR is immutable; a reversal or correction is the next numbered ADR
  with `Supersedes: ADR NNNN`. `ADR-FORMAT.md` owns the rule; read it before
  authoring or superseding one.

## Status is DERIVED, never hand-maintained

The spec's per-group status block is regenerated at reconcile, not remembered:

```
run the suite → map each criterion ID to pass/fail (via test name / @spec tag)
→ rewrite the status block: Met + tested = passing, GAP = failing/absent
→ stamp `verified <YYYY-MM-DD>`
```

So the spec cannot drift from reality: the suite writes the status. This
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

### Criterion proof shape

Before `WORK`, each active criterion must name more than the happy result:

```text
ID | invariant | producer→consumer boundary | failure/rollback path | mapped proofs
```

- Map at least one behavioural proof to the criterion. Add more when one test cannot
  cover its boundary and failure semantics.
- For contract changes, trace and type every hop. A safe type at the producer and
  consumer does not help if a middle adapter can legally discard the value.
- For architecture/static gates, add an adversarial bypass matrix. Test alternate
  syntax, initialization, wrappers/objects, and indirection—not only the exact code
  that caused the review finding.
- A structure scan proves structure only. It cannot mark an async, state, rendering,
  or failure-behaviour criterion Met. Use a behavioural runner/browser proof, or keep
  the criterion GAP and request the smallest test harness.
- Every negative proof must fail for the intended reason before the implementation is
  restored. Record red and green evidence; reasoned coverage is labelled unproven.

Use `scripts/check_spec_coverage.py <spec.md> <test-root> [<test-root> ...]` to fail
on duplicate criterion IDs or criteria with no test reference, and to print where each
ID is mapped. Point it at test roots only, because any file mentioning an ID counts as a
mapping. This checks mapping; the relevant suite still proves pass/fail.

## Reviewing against the spec: two axes

Review a diff on **two separate axes and report them separately**, because a
change can pass one and fail the other (right thing in the wrong style, or clean
style doing the wrong thing):

- **Spec** (this skill's axis): does the diff faithfully implement the
  originating `spec.md`? Report (a) criteria asked for but missing or partial;
  (b) behaviour nobody asked for (scope creep); (c) criteria that look done but
  are implemented wrong. Quote the criterion ID for each finding. A criterion
  with no test is a Spec-axis finding.
- **Standards** (companion axis): does it follow the repo's documented standards,
  plus a Fowler smell baseline (mysterious name, duplication, feature envy, data
  clumps, primitive obsession, shotgun surgery, speculative generality…)? A
  documented repo standard overrides the baseline. Skip what tooling already
  enforces.

Reviewer posture is adversarial. First restate the invariant, then look for a
legal implementation shape that violates it while leaving the author's exact
fixtures green. Inspect the adjacent load-bearing boundaries as well as the
touched files. Approval evidence names the bypasses attempted and the failure
path exercised. A working diff alone does not show that the invariant will
survive the next refactor.

Reviewer output ends with exactly one verdict:

- `APPROVED` only when every assigned ID is implemented, mapped to a passing test,
  contains no scope creep, and the Standards axis has zero unresolved findings.
- `REJECTED` with each finding attached to a criterion ID, or `SPEC-GAP` when the
  behaviour has no agreed criterion yet.

## Realigning existing docs to the format

A pure-docs sweep ("redo all docs to the format") is branch work. Run
`rjv-work-plan` for the resumable plan (inventory + conformance status), use the
format files here as the done target, and delegate the mechanical rewrites
(cost rules in `rjv-subagents-claude` (Codex: `rjv-subagents-codex`) /
`rjv-codex-ollama-subagents`). The flagship model judges conformance. No
separate migration skill exists; these compose.

## Reality wins

When docs and reality disagree, **reality wins**. Fix mutable specs and
glossaries to match and cite the source (test, `file:line`, commit). A committed
ADR is corrected only by a successor ADR. A spec criterion with no test is a
GAP, and the status block says so.

---

*Steals from mattpocock/skills (`domain-modeling` CONTEXT/ADR formats, `code-review`
two-axis + Fowler baseline), stripped of issue-tracker coupling for flat-file use.
Spec-as-acceptance-criteria format + test-backed status from a live financial build.*
