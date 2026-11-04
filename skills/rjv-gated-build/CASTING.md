# Casting the roles

Read this at build start, when the human asks who should drive, or when a recast is
on the table. Once `## Cast` is recorded in the plan, every resume obeys what is
written there and skips this file. The three roles are defined in `SKILL.md` §1.

**Orchestrator: the human casts it at launch. ASK them.** The human starts the
run, so the human picks the driver. Choose by run length and stakes:

| Orchestrator | Pick when | Reviewer it then requires |
|---|---|---|
| **Opus** (flagship) | short / interactive, or design-heavy where the driver's own judgment carries the loop | may self-review MECHANICAL steps only; high-stakes still gets an independent cross-vendor reviewer |
| **Sonnet** (mid) | long autonomous / overnight: the all-night loop at ~1/5 Opus per-turn cost | never self-reviews non-trivial work → cast an **Opus** reviewer; live-money adds a **Codex** cross-grill |
| **Codex** (external CLI) | repo-heavy mechanical drives; or when you want the **zero-cost cheap-lane only Codex has** (local-Ollama agents *with* repo tools) | casts its reviewer cross-vendor via a forwarder/bridge (execution bindings below); high-stakes → Claude/Opus reviewer |

**Reviewer floor: stakes first, orchestrator tier second.** The reviewer is at
least as strong as the orchestrator. Above mechanical work, independence is
mandatory: a separate agent, cross-vendor where available. Self-review ≠
independent review, even at flagship.

**The local lane is free.** Local Ollama explorers (read-only recon) and workers
(scoped mechanical edits) are the Author lane at $0, runnable from any host through
`rjv-codex-ollama-subagents`. High-stakes authoring never goes there
(`rjv-subagents-claude` / `rjv-subagents-codex`).

| Author | Reviewer | When |
|---|---|---|
| Frontier agent (full repo context) | Cross-vendor frontier agent | Design-heavy, high-stakes builds: the core pattern |
| External CLI agent (e.g. Codex) | Orchestrator itself | Mechanical bulk typing; orchestrator has the context + judgment |
| Local model (Ollama-class) | Orchestrator | Zero-cost function-level drafting from a tight spec |
| Cheap-tier subagent | Flagship-tier | Intra-family economy: cheap hands, expensive judge |

**Execution bindings.** Each cast needs a transport; use what exists:

- Local Author → a runner from `rjv-codex-ollama-subagents`, never an
  `Agent`/subagent `model:` (that field takes only cloud aliases).
- External CLI Author/Reviewer (Codex-class) → its plugin or a thin Bash forwarder
  subagent (e.g. Codex rescue in Claude Code): one call in, stdout back.
- Intra-family cheap Author → subagent spawn, model set explicitly.

**Record the cast in the plan.** At build start, fill the anchor plan's `## Cast`
section (format in `rjv-work-plan`): orchestrator, author, reviewer, subagent
tiers, human gates, models named.

**Two hard casting rules** (evidence-backed; apply them as written):

1. **Reviewer ≥ author strength.** Reviewer strength is where quality comes from;
   author strength is just typing speed. A weak model reviews nothing. Tested:
   asked to find a real bug in shipped code, a 35B local model said "no bugs".
2. **Prefer cross-vendor for the grill.** Different families miss different
   failure modes; same-family review inherits the author's blind spots.

**The human is also a reviewer.** In a real run the user caught a hole (broker
latency) that BOTH frontier models missed across four grill rounds. Surface
designs to the human at phase boundaries. Their domain experience outranks model
priors: when their live evidence contradicts the design, update the design
immediately and say so.
