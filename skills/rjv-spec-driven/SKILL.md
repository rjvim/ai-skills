---
name: rjv-spec-driven
description: "Use when a branch is substantial enough to spec — author or update a Requirements & Acceptance-Criteria doc that DRIVES the build and doubles as source-of-truth (per-item test-backed status), maintain the domain glossary (CONTEXT.md) and decision records (ADRs), and review a diff against its spec. The proportional durable-truth layer on top of rjv-work-plan. Triggers: 'write a spec', 'acceptance criteria', 'requirements doc', 'spec-driven', 'record a decision / ADR', 'glossary / ubiquitous language', 'review against the spec', 'realign docs to the format', 'what does the system do today'."
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
| **ADRs** | `docs/adr/NNNN-*.md` | [ADR-FORMAT.md](./ADR-FORMAT.md) | decisions + why, tiny, criteria-gated |

Read the format file when authoring that artifact. **One-shot rule for the AI:**
produce EXACTLY the structure in the format file — fill the template, the worked
example is the target shape, do not invent sections or renumber IDs.

## The spec is the driving spec (proportional)

- **Small branch** → a one-line intent in the `rjv-work-plan` plan. No spec doc.
- **Real feature** → a `spec.md` in the format BEFORE code. Criteria are the build
  target; the engine "passes" only when every criterion holds in code.
- The spec spans the lifecycle in ONE doc: written planned → drives the build →
  its status block reports what's live. It never becomes a separate "behaviour doc".

## Real-time promotion + the mutation test

Settled facts leave the volatile plan the instant they crystallize (a branch commit
that merges with the code — see `rjv-work-plan`). The test for where a fact goes:

> If working on this branch *changes* the doc → it's PLAN state (`rjv-work-plan`).
> A durable artifact (spec criterion, term, decision) changes only via a deliberate
> promotion — never as running scratch.

- Term settles → `CONTEXT.md` now. Hard decision made → ADR now. Criterion agreed →
  `spec.md` now. Never parked in the plan for "later".

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

## Realigning existing docs to the format

A pure-docs sweep ("redo all docs to the format") is still branch work: run
`rjv-work-plan` for the resumable plan (inventory + conformance status), use the
format files here as the "done" target, delegate the mechanical rewrites (cost
rules in `rjv-gated-build` §7 / `rjv-codex-ollama-subagents`), flagship judges
conformance. No separate migration skill — it composes.

## Don't invent

Docs and reality disagree → **reality wins**: fix the doc, cite the source
(test, `file:line`, commit). A spec criterion with no test is not "done" — it's a
GAP, and the status block must say so.

---

*Steals from mattpocock/skills (`domain-modeling` CONTEXT/ADR formats, `code-review`
two-axis + Fowler baseline), stripped of issue-tracker coupling for flat-file use.
Spec-as-acceptance-criteria format + test-backed status from a live financial build.*
