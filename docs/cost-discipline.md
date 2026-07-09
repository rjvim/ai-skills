# Cost discipline for Claude Code

Learnings from running long, multi-day Claude Code sessions, and the setup that
follows from them. Written to be re-applied on a fresh machine. Nothing here is
specific to one person — it's how the pricing mechanics work.

## The mental model

Usage limits (the rolling window and the weekly cap) meter **consumption**, not
time or message count. Consumption is roughly:

```
spend  ≈  Σ (tokens × model_rate)
```

Two facts fall out of that formula, and they explain almost every surprise bill:

1. **Model choice dominates.** A premium model can draw the meter ~5× faster per
   token than a mid model, and ~20× faster than a small one. The single biggest
   cost lever is *which model is in the driver's seat*, not how much you delegate.

2. **Context is re-billed every turn.** Each turn resends the whole conversation.
   On a long session, the accumulated context — including large subagent result
   dumps that landed in it — is re-read and re-charged on *every* subsequent turn.
   A big dump at turn 5 is paid again at turns 6…N.

## What actually drives a large bill

In practice, on a long flagship-model session, the spend concentrates in two
lines, both about the main loop being long and chatty:

- **The model's own output tokens.** These are full-rate and *not cacheable*.
  Big status tables and multi-section summaries are real money with no discount.
- **Cache-read of the accumulated context.** Re-reading the conversation every
  turn. Grows without bound in a marathon session; fat subagent dumps sitting in
  context make it worse.

Delegation to cheaper models helps the *work* slice, but on a chatty flagship
loop that slice is often the minority of the bill. Don't over-invest in it.

## The levers, biggest first

1. **Terser output.** Shorter answers, fewer tables. The one line with no hidden
   multiplier and no way to claw back — only not-writing-it works.
2. **Shorter sessions.** `/compact` aggressively; prefer a fresh session per
   unrelated task over one marathon, because every turn pays for the whole
   history.
3. **Terser subagent returns.** Have agents return distilled bullets, not full
   tables/diffs that then sit in context and re-bill every turn.
4. **Cheaper default model.** Default the main loop to a mid model; escalate to
   the premium model deliberately, per task.
5. **Recon delegation.** Push searches/reads to a cheap read-only agent. Real but
   usually the smallest slice — don't mistake it for the main fix.

## Why a rule in a prompt doesn't fix this

A model can't change the harness model it's running on — it can't downgrade or
upgrade itself mid-run. So an instruction like "use a cheaper model" is advisory
at best: it can only move *sub-tasks* to cheaper agents, and only when the model
chooses to. The main-loop cost is untouched. **Cost routing is a config lever,
not a prompt lever** — put it where model selection actually happens.

## The setup (config, not prompts)

All global, all under `~/.claude/` — done once per machine.

**`~/.claude/settings.json`**

```jsonc
{
  "model": "sonnet",        // mid model as default; escalate by hand when needed
  "effortLevel": "medium"   // fewer thinking tokens on routine turns
}
```

- Prefer the plain model id over a large-context variant (e.g. a `[1m]` window)
  unless you routinely work past the standard context — the big window carries a
  standing price premium on every turn.

**`~/.claude/CLAUDE.md`** — loaded automatically at the start of every session in
every project. The right home for always-on behavioral standing-orders (be
terse, no tables unless asked, tell subagents to return bullets, suggest
`/compact` when a task is done). Understand it's a *nudge*, not enforcement —
expect some drift.

**`~/.claude/agents/*.md`** — custom subagent definitions. Pin a cheap `model:`
and instruct them to **return distilled bullets, never raw dumps**. This is the
one lever that mechanizes cleanly: cheap by construction, and it keeps large
result dumps out of the main context (attacking both the model-rate and the
cache-read lines). A read-only `recon` agent (small model) and a scoped `worker`
agent (mid model) cover most delegation.

## What can't be automated

Two levers stay as human discipline — no config or skill binds them:

- **Escalate to the premium model deliberately** at the start of a genuinely hard
  task (the model won't do it for you), and drop back down after.
- **Fresh session per unrelated task.** A skill loads on a trigger word, not at
  conversation start, and can't force a compaction on itself.

## One-line version

Cheap model as default, terse output, short sessions, bullets-not-dumps from
agents — and remember the expensive part is the flagship main loop talking to
itself, which only *your* habits and *config* control, never a prompt.
