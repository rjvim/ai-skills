---
name: rjv-work-plan
description: "Use when starting, resuming, or checking in on work on a BRANCH — bug, feature, refactor, enhancement. One committed plan per branch (.plans/<name>.md, declaring `Branch:` in its header) is the working memory: what we're doing, where we stopped, how to resume. Deterministic resume via git branch → the plan whose Branch matches → RESUME HERE block; reconcile-on-open; real-time promotion of settled facts to durable docs. Triggers: 'pick up X', 'where were we', 'what's the status', 'resume', 'start this branch', 'plan this work'."
---

# Work Plan — branch-scoped working memory

One line: **the branch is the unit of work; one committed plan per branch is its
memory.** Plans hold *volatile* state (what we're doing, where we stopped). Durable
truth — specs, glossary, decisions — lives in `_docs/` and is owned by
`rjv-spec-driven`. The plan **links** to durable docs, never duplicates them.

- `.plans/<name>.md` = working memory for ONE branch (one plan per branch).
  Committed, so any agent on any machine that checks out the branch resumes from it.
  Deleted before merge.
- **Each plan declares `Branch: <name>` in its header.** The file itself can be
  named anything readable (a topic name is fine); the current branch is the key, and
  resume finds the plan whose `Branch:` matches `git branch --show-current`. No index
  to maintain — **git branches ARE the active-work index**, and the branch you have
  checked out is which plan, without being told.
- On `main`, `.plans/` is empty. Non-empty only on in-flight branches.

Tool-agnostic: same files serve Claude Code, Codex, any agent (reference this from
AGENTS.md so every agent follows it).

## Entry point — resume or start

On any new conversation about the current work, hydrate in order — no code before
step 4:

1. Find this branch's plan: `b=$(git branch --show-current)` then
   `grep -l "^Branch: $b\$" .plans/*.md`.
   - **1 match** → that's the plan.
   - **0 matches** → branch isn't scoped yet; create a plan (format below), set its
     `Branch:` + goal, before touching code.
   - **>1 match** → violates one-plan-per-branch; ask the human, or take the
     most-recently-modified and flag the others as stragglers.
2. `grep -A6 ">>> RESUME HERE <<<" <that-plan>` — land on the resume block, then read
   the whole plan.
3. Read every durable doc the plan's **Source of Truth** section links (specs via
   `rjv-spec-driven`, glossary, ADRs).
4. **Reconcile-on-open** (below). Only then act.
5. Report to the human: current state, drift found, next step about to be taken.

## Plan format

```
# Plan: <topic or branch>
Branch: <branch-name>          ← the deterministic key; resume matches on this line
Status: brainstorm | approved | in-progress | blocked | shipped
Last reconciled: <date> — <matches reality? what drifted?>

## Goal            ← what this branch delivers (+ one-line intent if too small to spec)
## Cast            ← who builds this: agents, models, approver (see below)
## Decisions       ← locked choices + why (crystallized brainstorm; promote hard ones to ADRs)
## Open Questions  ← still-live brainstorm (resolve → Decisions or ADR)
## Current State   ← VERIFIED ground truth now, not assumed
## Next Steps      ← ordered resume point; carries the RESUME HERE block
## Regression Guard← how to avoid breaking existing behaviour
## Out of Scope
## Source of Truth ← links to _docs/ spec, glossary, ADRs, key file:line
```

Task lists, test cases, data models slot under Next Steps / Current State. One-line,
actionable, agent-register (terse facts, file:line). The plan holds ONLY volatile
state — anything settled and durable promotes out in real time (see below).

**Next Steps always carries the literal marker block:**

```
## Next Steps
>>> RESUME HERE <<<
Step: <id> — <status>
Do next: <one imperative — the exact next action>
Must-read first: <file:line, …>
<<< END RESUME >>>
1. …ordered steps after the current one…
```

**Cast section** — the agent lineup is a locked decision, recorded at plan creation;
every resume plays its role without re-negotiating:

```
## Cast
Orchestrator: claude-code @ fable        ← holds this plan, integrates
Author:       claude (main session)      ← or: codex · qwen3.6:35b via rjv-codex-ollama-subagents
Reviewer:     codex via codex:rescue     ← explicit APPROVED gates each step (gated builds)
Subagents:    haiku = sweeps/forwarders · sonnet = routine code
Human gates:  spec sign-off · USER-flagged decisions · live/prod switches
```

Recasting mid-build is allowed but is a logged Decision (with why), not a drift.

## Ceiling — the plan stays thin

**Hard ceiling ~400 lines / ~20KB.** A plan is re-read on every resume — an unbounded
plan is a recurring token tax that compounds each turn. It stays thin by
construction:

- **Git holds history, so the plan doesn't.** Never keep a log "in case" —
  `git log .plans/<name>.md` is the log. The plan is a *current-state* surface.
- **Real-time promotion** (below) drains settled facts out continuously.
- If it's over the ceiling at reconcile, promote durable facts to `_docs/` and
  compress BEFORE acting.

## Real-time promotion + the mutation test

Settled facts leave the plan the instant they crystallize — written straight to
their durable home (a branch commit that merges with the code), never parked in the
plan for "later". The test for where a fact belongs:

> If working on this branch *changes* the doc → it's PLAN state (here).
> A durable fact (spec criterion, term, decision) changes only via deliberate
> promotion → `_docs/`, owned by `rjv-spec-driven`. Never a running edit.

Because promoted docs are branch commits, they travel through the same PR and land
on `main` exactly when the code does — no drift, no batch-at-merge. See
`rjv-spec-driven` for the artifacts (spec / glossary / ADR) and their formats.

## Reconcile-on-open — never stale

The resume guarantee is a cheap ritual, not "the agent remembers":

```
read plan → VERIFY each "done" claim against real code/db/tests → note drift in
Current State → rewrite Next Steps → stamp Last reconciled →
if over the ~400-line ceiling, promote + compress → then act
```

Never trust a checkbox; a plan whose "done" you haven't verified is a rumor.
**During work:** update the plan in the same turn as the change, never batched.
**On stop/handoff:** rewrite the `>>> RESUME HERE <<<` block to the exact resume
point; no `done` that isn't.

## Resume mechanism — deterministic, do not reinvent

The `>>> RESUME HERE <<<` / `<<< END RESUME >>>` strings are **literal — never
paraphrase them**, or the grep breaks. A fixed string is a deterministic landing
(`grep` finds it every time, survives header drift); a semantic "find the Next Steps
section" is something each agent re-locates and each session re-invents.

```
b=$(git branch --show-current)                       # current branch = the key
grep -l "^Branch: $b\$" .plans/*.md                   # → the plan that declares it
grep -A6 ">>> RESUME HERE <<<" <that-plan>            # land on the block
→ reconcile-on-open (verify done-claims) → act
→ at END of every step: rewrite the block
```

There is NO `RESUME.md` — git branches are the active-work index. Concurrent work =
concurrent branches (or worktrees), each with its own committed plan.

## Merge — the plan is deleted, main stays clean

**Delete this branch's plan in the final PR commit.** Its durable facts already
left in real time, so merge is a backstop: "anything un-promoted? — rare", then the
plan is gone. Invariant: **`.plans/` is empty on `main`.** Guard it so it can't be
forgotten — a merge-checklist line, or a CI check "`.plans/` empty on main".

## Roadmap — the backlog (durable)

A branch usually implements a backlog item. Keep a durable backlog in
`_docs/features/<area>/roadmap.md` (or `_docs/architecture/roadmap.md` for
cross-cutting): items with `[planned] | [in-progress] | [shipped]`, tech + product
debt under their own sections. On branch start, set the item `[in-progress]` → link
the branch; on merge, `[shipped]`. This is the durable "what's next", distinct from
the transient plan.

## Brainstorm in the plan

The plan is where thinking out loud lives. Keep it from rotting: resolved → one-line
**Decision** with the why (promote hard-to-reverse ones to an ADR); unresolved →
**Open Questions**; loose musing either crystallizes or dies.

## With rjv-spec-driven and rjv-gated-build

- **`rjv-spec-driven`** — load when the branch is substantial enough to spec. It
  owns the durable artifacts (acceptance-criteria spec, glossary, ADRs) the plan
  links to. Small branch → skip it, a one-line Goal is enough (proportional).
- **`rjv-gated-build`** — high-stakes/financial/prod branches. The plan file IS that
  build's anchor doc; the grill trail, evidence ledger, tombstones live as sections
  inside it. Multiple concurrent gated builds = multiple branches, each hydrated by
  its branch name through the entry point above.

---

*Provenance: production workflow from a live fintech monorepo — multiple concurrent
branches, two agents (Claude Code, Codex) sharing committed plans + `_docs/`.*
