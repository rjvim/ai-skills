---
name: rjv-subagents
description: "Use before launching ANY subagent, Codex sub-agent, opencode run or local Ollama run, and whenever the big model (Opus/Fable, Astra/Sol) is about to spend itself on mundane work. Owns the delegation rules: when to do it yourself, how to split, which worker, the brief, the time-budget box, the overrun drill, and checking results. Triggers: spawn a subagent, delegate, fan out, parallel agents, which model, save Opus usage, save tokens, cheaper model, time budget, subagent took too long, opencode, local model, model economy."
---

# Subagents — spend the big model on judgment

The big model (Opus or Fable in Claude Code, Astra or Sol in Codex) is the
scarce resource. Usage is rationed and long sessions stall on limits long
before they stall on difficulty. Every minute it spends reading, typing or
sweeping is a minute a cheaper model could have spent.

> **The rule.** The big model designs, splits, briefs, judges and
> integrates. Everything a cheaper worker does equally well goes to the
> cheapest worker that clears the bar. The big model does mundane work
> itself only when it takes 1–2 minutes, or when it is reading code it is
> about to edit anyway.

Binds every orchestrator on every host. Rung names differ per host; the rule
does not.

## 1. Do it yourself, or delegate

| Situation | Do |
|---|---|
| Mundane, 1–2 minutes of work | Yourself. Brief + review would cost more. |
| Reading one small file at a known path | Yourself. |
| Reading code you are about to edit | Yourself. Those bytes must sit in your context anyway. |
| Design, trade-off, root cause unknown, final verify | Yourself. This is what you are for. |
| Recon across many files, "where is X" | Delegate to a cheap repo-tool worker. |
| Mechanical edits, renames, boilerplate, test-writing from a spec | Delegate. |
| Summaries, classification, draft-from-spec with context in the prompt | Delegate, text-only ladder. |
| Independent pieces of a bigger job | Delegate in parallel, one message. |

Delegation has a fixed overhead: splitting, briefing, reviewing. Below it,
do the work. Above it, doing mundane work on the big model is waste, not
thoroughness.

## 2. Split first — this is the launcher's real job

A good split is the whole game. Each piece must:

- fit one of its worker's time boxes (§5),
- name the files, commands and done-criteria, so the worker never has to
  rediscover what you already know,
- be independent of the others, or be ordered explicitly,
- return a distilled answer (`file:line`, a diff, a verdict), never a dump.

If a piece cannot fit its row's largest box, it is several pieces. Split
again before launching.

## 3. Pick the worker

Split by whether the job touches the repo, then pick the rung.

| Job needs… | Ladder (cheap → dear) |
|---|---|
| **Repo tools** (recon, file reads, edits, running commands) | local Ollama explorer or worker → cheap cloud subagent → mid cloud subagent |
| **Self-contained text** (context is all in the prompt) | local one-shot → third-party cloud (opencode) → cheap cloud → mid cloud |

A local one-shot model has no tools: no files, no shell, no web. It sees only
the prompt and can never do recon.

Rungs per host:

| Host | Mechanical | Standard | Hard |
|---|---|---|---|
| Claude Code | Haiku | Sonnet | Opus |
| Codex | gpt-5.6-luna, low | gpt-5.6-terra, medium | gpt-6-astra, high |
| Third-party cloud via opencode | DeepSeek Flash, retry on MiniMax | not used | not used |
| Local Ollama (`rjv-codex-ollama-subagents`) | gemma explorer or worker; qwen coder one-shot | not used | not used |

- **Ask Jev.** `rjv-jev-decisions`' `jev-model-pick.sh` returns the tier, the
  model per host, and the time boxes. Its hooks fill in a model when you
  forget.
- **Always set the model explicitly.** A subagent that silently inherits the
  parent's model is the most common leak. In Codex only a fresh sub-agent
  (`fork_turns` `"none"` or a number) can take a model; a full-history fork
  rejects the override.
- **Unsure means one rung up.** A failed cheap attempt costs more than the
  saving.
- **Stakes raise the floor.** Money, data, production, security: at least the
  standard rung, and keep even the draft on a cloud model, not local or
  third-party.
- **Some work never leaves the host's own cloud models** (standard rung or
  higher): anything touching secrets, credentials, customer data, approval
  or access-control logic, migrations, the harness, or anything where a
  quiet mistake reaches production. No local or third-party model sees it.
- **A forwarder goes cheapest.** A subagent whose only job is one shell call
  to another agent runs on the cheapest rung; the quality is the other
  agent's.

## 4. Write the brief

The worker sees only the brief. Write it the way you would hand work to a
new colleague:

```text
Goal:    one sentence, what done looks like
Where:   exact files / dirs / commands allowed
Know:    facts you already have, so it does not rediscover them
Do not:  what to leave alone
Return:  the distilled shape you want back (file:line list, diff, verdict)
Budget:  10 min
```

A vague brief is the usual cause of an overrun.

## 5. Pick a time budget — a box, per task

Before each launch, judge how long this task should take and pick one box
from the worker's row. Put it in the brief and enforce it with the host's
timeout or a wakeup. Minutes are wall clock, launch to report.

| Worker | Boxes to pick from |
|---|---|
| Claude subagent (Haiku, Sonnet, Opus) · Codex sub-agent (Luna, Terra, Astra) | 5 · 10 · 15 min |
| Third-party cloud via opencode or similar | 2 · 5 min |
| Local Ollama, one-shot text | 5 · 10 min |
| Local Ollama with repo tools (explorer or worker) | 10 · 20 · 30 min |

The task picks the box, not the model. A Haiku sweep over many files can
need 10; an Opus design question can fit 5. Pick the smallest box you expect
it to finish in.

Why the rows differ: third-party models are fast and get only mechanical
work, so a slow run means looping. Local models are slower and Ollama queues
parallel calls, so their boxes are larger, but still closed.

**Over the box is the launcher's failure, not the worker's.** The task was
not split small enough, or the brief left the worker to discover what the
launcher should have told it.

1. Stop the worker. Do not extend the clock or wait it out.
2. Keep what it finished; check it like any other output.
3. Split the rest smaller with tighter briefs, and relaunch.
4. Record the overrun where the work is tracked (the `rjv-work-plan` plan):
   task, box picked, actual, how you re-split.

Never move a running task to a bigger box.

## 6. Run in parallel when pieces are independent

Launch independent pieces in one message so they run together. Local Ollama
queues concurrent calls, so parallel local runs save tokens, not wall clock.
Do not also do a delegated search yourself while it runs; wait for it.

## 7. Check what comes back

- **You check it.** A cheap worker's own PASS can be wrong. Run the tests,
  read the diff, try a case the worker never saw.
- **Keep or escalate.** `rjv-jev-decisions`' `jev-verify.sh` checks a report
  against its acceptance items; escalate one rung only when something is
  missing.
- **Never let a cheap worker be the gate.** Review, bug-hunting and approval
  stay on the big model or an independent reviewer (`rjv-gated-build`).
- **Name the model** when you launch and when you report what came back.
- **No model provenance in artifacts.** No "generated by" lines or AI
  trailers in commits, PRs, docs or code.

## Related

- `rjv-jev-decisions` — the model picker and spawn hooks.
- `rjv-codex-ollama-subagents` — the local runners.
- `rjv-gated-build` — who authors and who reviews on high-stakes builds.
