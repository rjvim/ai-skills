# Model economy — cost-routing is a HARD RULE, every agent

Read this before delegating anything, and whenever you are about to pick a model
for a subagent. The one-line rule is in `SKILL.md`; this file holds the ladders and
the break-even bounds.

Binds **every** orchestrator that runs this skill — Claude, Codex, any host — not
just the flagship you're reading on. Long runs stall on budget/rate limits before
difficulty, so:

> **HARD RULE.** The flagship (top tier) is reserved for judgment: design, grill
> triage, final verify, synthesis. Any work a cheaper tier does equally well —
> recon, mechanical edits, test-writing, boilerplate, summarization — MUST route
> to the cheapest capable tier. Cheap-tier work on the flagship is waste, not
> thoroughness. (One bound: break-even below — don't route out a trivial task
> whose spec+review overhead exceeds the saving.)

Rung NAMES differ per host (Claude haiku/sonnet/opus; local gemma/qwen; Codex
spark/low-effort vs full) — the RULE is identical: cheapest tier that clears the bar.

## Two ladders — pick by whether the job touches the repo

Biggest routing mistake: sending repo work to a model that can't reach the repo.
Split the work FIRST, then pick the rung:

| Job needs… | Ladder (cheap → dear) | Note |
|---|---|---|
| **Repo tools** — recon, file reads, in-place edits | Explore/subagent @ cheap tier → @ mid tier | CLOUD/host-agent ONLY. A local model has **no tools** and cannot play here at all. |
| **Self-contained text** — draft-from-spec, classify, summarize (context is IN the prompt) | local (gemma → qwen) → cheap cloud → mid cloud | Local rungs cost $0; the axis between them is speed/quality, not price. Escalate a rung only when quality falls short. |

Hard fact behind the left column: a local model in one-shot mode
(`rjv-codex-ollama-subagents`, the "no repo tools" section) is a
one-shot text function — NO filesystem/shell/web, sees only the prompt. It can
NEVER do recon or read your repo; the cheapest agent that reads files is a
cheap-tier Explore/subagent.

Ground-level:
- "Where is the retry logic?" → cheap Explore subagent. NEVER a local model.
- "Write this pure function to this signature + these 3 cases" → local (context is in the prompt).
- A recon subagent must **distill** (return the `file:line`), never dump file contents — a dump re-bills the flagship for the read it was meant to avoid.
- Don't spawn to read ONE small known-path file — read it yourself; spawn overhead > saving.
- Don't delegate the read of code you're about to edit — those bytes must sit in the flagship's context anyway.

Other frugality rules:
- **Reserve the flagship** for design, synthesis, final judgment, the grill.
- **Set the model EXPLICITLY per subagent** — never default-inherit the expensive
  parent (the silent inherit is the most common leak).
- **The forwarder goes cheapest.** A reviewer forwarder is one bash call returning
  stdout — the grill's quality is the REVIEWER's model, not the forwarder's.
- **Delegation has a break-even size.** Spec+review overhead is fixed; below it (a
  4-line fix) do it yourself. Delegate the BIG mechanical steps, not tiny ones.
- **Stakes raise the drafting floor, not just the review floor.** Casting already
  puts a strong REVIEWER on high-stakes work; also raise who may AUTHOR.
  Live-money / high-blast-radius → draft on a cloud mid-tier (Sonnet), not local —
  a subtly-wrong local draft costs more in review than it saved. Local drafting is
  for ordinary feature work.

## Time budgets — the launcher picks a box

Binds every orchestrator on every host. Before each spawn, the launcher
judges how long the task should take and picks one box from the worker's
row. Write it into the brief ("budget: 10 min") and enforce it with the
host's timeout or a wakeup. Minutes are wall clock, launch to report.

| Worker | Boxes to pick from |
|---|---|
| Claude subagent (Haiku, Sonnet, Opus) · Codex sub-agent (Luna, Terra, Astra) | 5 · 10 · 15 min |
| Third-party cloud via opencode or similar (DeepSeek Flash, MiniMax, Grok, Kimi) | 2 · 5 min |
| Local Ollama, one-shot text (`ollama-chat.sh`) | 5 · 10 min |
| Local Ollama with repo tools (explorer or worker) | 10 · 20 · 30 min |

The model does not fix the box; the task does. A Haiku sweep over many
files can need 10; an Opus design question can fit 5. Pick the smallest box
you expect the task to finish in. If none fits, the task is too big: split
it before launching.

Why the rows differ: cheap third-party models are fast and only get
mechanical work, so a slow run means looping. Local models are slower and
Ollama queues parallel calls, so their boxes are larger, but still closed.

**Over the box is the launcher's failure, not the worker's.** The task was
not split small enough, or the brief left the worker to discover what the
launcher should have told it. So:

1. Stop the worker. Do not extend the clock or wait it out.
2. Keep what it finished; check it like any other output.
3. Split the rest into smaller tasks with tighter briefs, and relaunch.
4. Record the overrun in the plan: task, box picked, actual, how you re-split.

Never move a running task to a bigger box. The largest box in a row is the
ceiling; a task that cannot fit it is several tasks.
