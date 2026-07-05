---
name: feature-workflow
description: >
  Use whenever: starting, planning, scoping, or RESUMING a feature or task;
  invoked with a feature name to hydrate all context for it ("feature-workflow
  <name>", "pick up <feature>", "where were we on <feature>", "what's the
  status"); creating/opening/updating/shipping a plan; updating a roadmap
  status (planned/in-progress/shipped); recording tech or product debt; or
  when a plan may have drifted from the code. Covers the plan-vs-docs split,
  the roadmap contract, the reconcile-on-open ritual, and promotion of
  durable truth into docs before a plan dies. Multiple features in flight =
  multiple plans, each independently resumable.
---

# Feature Workflow

Working memory that survives sessions, agents, and parallel features. One
line: **plans hold the work; docs hold the truth.**

- `.plans/<name>.md` = working memory for ONE piece of work. Live,
  brainstorm-friendly, ephemeral. Deleted when shipped.
- `_docs/` = source of truth. How the system works today, third-party API
  behavior, established patterns. Durable, authoritative.
- Plans **link** to docs, never duplicate them. A durable fact discovered
  while working gets **promoted** into `_docs/` before the plan is deleted.
  Never let truth die with the plan.

Tool-agnostic: the same files serve Claude Code, Codex, or any agent
(reference this procedure from AGENTS.md so every agent follows it).

## Entry point — invoked with a feature name

When asked to start or resume work on `<feature>` (e.g. "feature-workflow
risk-profiling", "pick up the bottom-nav work"), hydrate in this order —
do not touch code before step 4:

1. `_docs/features/<feature>/roadmap.md` — the feature's items, statuses,
   debt sections. Create it if starting something new.
2. The linked plan (`→ .plans/<name>.md` on the in-progress item), or
   create one from the format below (and set the roadmap item
   `[in-progress]`).
3. Every doc the plan's **Source of Truth** section links.
4. **Run reconcile-on-open** (below). Only then act.
5. Report to the human: current state, drift found, next step about to be
   taken.

## Plan format

```
# Plan: <name>
Status: brainstorm | approved | in-progress | blocked | shipped
Last reconciled: <date> — <matches reality? what drifted?>

## Goal
## Cast               ← who builds this: agents, models, approver (see below)
## Decisions          ← locked choices + why (crystallized brainstorm)
## Open Questions     ← still-live brainstorm (resolve → move to Decisions)
## Current State      ← VERIFIED ground truth now, not assumed
## Next Steps         ← ordered resume point: exact place to pick up
## Regression Guard   ← how to avoid breaking existing behavior
## Out of Scope
## Source of Truth    ← links to _docs/, API docs, key file:line
```

**Cast section** — the agent lineup is a locked decision, not a
per-session improvisation. Record it at plan creation; every resume
(any agent, any session) reads it and plays its role without
re-negotiating:

```
## Cast
Orchestrator: claude-code @ fable        ← holds this plan, integrates
Author:       claude (main session)      ← or: codex · qwen3.6:35b via ollama-delegate
Reviewer:     codex via codex:rescue     ← explicit APPROVED gates each step
Subagents:    haiku = sweeps/forwarders · sonnet = routine code
Human gates:  spec sign-off · USER-flagged decisions · live/prod switches
```

Recasting mid-build is allowed but is a logged Decision (with why), not
a drift. If a session starts under a different agent than the Cast
names (e.g. Codex opens a claude-authored plan), it says so and either
plays the role the Cast gives it or asks the human to recast.

Task lists, test cases, data models slot under Next Steps / Current State.
One-line, actionable, agent-register (terse facts, file:line — plans are
agent-read; docs for humans stay prose).

## Reconcile-on-open — never stale

The resume guarantee is a cheap ritual, not "the agent remembers":

```
read plan → VERIFY each "done" claim against real code/db → note drift in
Current State → rewrite Next Steps → stamp Last reconciled → then act
```

Never trust a checkbox. A plan whose "done" you haven't verified is a
rumor. **During work**: update the plan in the same turn as the change,
never batched for later. **On stop/handoff**: Next Steps points at the
exact resume point; no `done` that isn't.

## Brainstorm in the plan

The plan is where thinking out loud lives — options weighed, discussion
recorded. Keep it from rotting: resolved → one-line **Decision** with the
why; unresolved → **Open Questions**; loose musing either crystallizes or
dies.

## Roadmap contract

Every plan implements a roadmap item:

1. Find (or create) `_docs/features/<feature>/roadmap.md`
2. Set the item `[in-progress]` and link it: `→ .plans/<name>.md`
3. On ship: `[shipped]`, remove the plan link, promote durable facts,
   delete the plan
4. On abandon: revert to `[planned]`, delete the plan

Tech debt and product debt live in the same roadmap.md under their own
sections — one place per feature, not a separate debts folder.
Cross-cutting infra debt → `_docs/architecture/roadmap.md`.

## Don't invent

Before touching a third-party integration or existing subsystem, read its
`_docs/` entry — it is authoritative. If docs and reality disagree,
**reality wins**: fix the docs and cite the source (API URL, file:line,
commit) so the correction is verifiable, not another invention.

## With gated-build

For high-stakes adversarial builds (see the `gated-build` skill), the
feature's plan file IS that build's anchor document — the grill trail,
evidence ledger, and tombstones live as sections inside it. Multiple
concurrent gated builds = multiple plans, each hydrated by name through
the entry point above.

---

*Provenance: production workflow from a live Laravel/fintech monorepo
(mfstack), where multiple concurrent features + two agents (Claude Code,
Codex) share the same plans and docs.*
