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
