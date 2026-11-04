---
name: rjv-subagents-claude
description: "Claude Code only; in Codex use rjv-subagents-codex. Use at the start of any task with legwork (searching across files, reading logs, reviews, QA passes, screenshots, waiting on builds) and before launching any subagent or opencode run. Owns when to do it yourself, how to split, which model, the brief, time boxes, unattended-run limits and checking results. Triggers: delegate, spawn a subagent, fan out, which model, save tokens, time budget, opencode, waiting on CI or a deploy, blocked main thread, overnight run, instruction bloat."
---

# Subagents: spend the big model on judgment

The big model (Opus or Fable) is the
scarce resource. Usage is rationed and long sessions stall on limits long
before they stall on difficulty. Every minute it spends reading, typing or
sweeping is a minute a cheaper model could have spent.

> **The rule.** The big model designs, splits, briefs, judges and
> integrates. Everything a cheaper worker does equally well goes to the
> cheapest worker that clears the bar. The big model does mundane work
> itself only when it takes 1–2 minutes, or when it is reading code it is
> about to edit anyway.

> **Never block the main thread.** The main thread is where the user
> talks to you. Waiting on something slow is never the big model's job.
> Anything slow (a preview deploy, CI, a long build, a full
> test suite, a remote job) runs in the background or under a watcher on
> the cheapest rung (§7), while you keep working or keep talking.

Binds every orchestrator in Claude Code. Codex has its own copy,
`rjv-subagents-codex`. Claude Code cannot run local Ollama models.

## 1. Do it yourself, or delegate

| Situation | Do |
|---|---|
| Mundane, 1–2 minutes of work | Yourself. |
| Reading one small file at a known path | Yourself. |
| Reading code you are about to edit | Yourself. Those bytes must sit in your context anyway. |
| Design, trade-off, root cause unknown, final verify | Yourself. This is what you are for. |
| Recon across many files, "where is X" | Delegate to a cheap repo-tool worker. |
| Mechanical edits, renames, boilerplate, test-writing from a spec | Delegate. |
| Summaries, classification, draft-from-spec with context in the prompt | Delegate, text-only ladder. |
| Independent pieces of a bigger job | Delegate in parallel, one message. |
| Waiting on a deploy, CI, a build or a remote job | Never yourself. Background it or hand it to a watcher (§7). |

Delegation has a fixed overhead: splitting, briefing, reviewing. Below
that overhead, do the work yourself. Above it, mundane work on the big
model is waste.

## 2. Split first

The split is the launcher's main job; a bad split wastes every worker
after it. Each piece must:

- fit one of its worker's time boxes (§5),
- name the files, commands and done-criteria, so the worker never has to
  rediscover what you already know,
- be independent of the others, or be ordered explicitly,
- return a distilled answer (`file:line`, a diff, a verdict) of a few
  lines.

If a piece cannot fit its row's largest box, it is several pieces. Split
again before launching. Done when every piece passes all four checks.

## 3. Pick the worker

Split by whether the job touches the repo, then pick the rung.

| Job needs… | Ladder (cheap → dear) |
|---|---|
| **Repo tools** (recon, file reads, edits, running commands) | Haiku → Sonnet → Opus |
| **Self-contained text** (context is all in the prompt) | opencode → Haiku → Sonnet |

opencode runs DeepSeek Flash and retries on MiniMax. Give it only work
whose context fits in the prompt. `repo` mode (the repo under `--auto`)
only when the user asks for an opencode run on the repo in this session;
never start one on your own. It reads files and runs shell commands
in its working directory even without `--auto`, so launch it only through
`rjv-opencode-agents`, which runs text work in an empty directory and
watches every run. opencode's shell still reaches the whole account, so a
brief never names a secret, a credential or customer data.

| Rung | Mechanical | Standard | Hard |
|---|---|---|---|
| Model | Haiku | Sonnet | Opus |
| opencode | DeepSeek Flash, retry on MiniMax | not used | not used |

- **Ask Jev.** `rjv-jev-decisions`' `jev-model-pick.sh` returns the tier, the
  model, and the time boxes. Its hooks fill in a model when you
  forget.
- **Codex reviews.** The user relays them by hand through the brief and
  result files in `rjv-code-review`. Start Codex yourself only when the
  user asks or the plan's Cast names it; then use `gpt-6.1-sol` at low effort unless they name a model.
- **Always set the model explicitly.** A subagent that silently inherits the
  parent's model is the most common leak.
- **Unsure means one rung up.** A failed cheap attempt costs more than the
  saving.
- **Stakes raise the floor.** Money, data, production, security: at least the
  standard rung, and keep even the draft on Claude.
- **Some work never leaves Claude** (Sonnet or higher): anything touching
  secrets, credentials, customer data, approval or access-control logic,
  migrations, the harness, or anything where a quiet mistake reaches
  production. opencode never sees it. Do not run `jev-model-pick.sh` on its
  brief either; the picker sends the brief to TypeSafe.
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

A vague brief is the usual reason a worker runs long.

## 5. Size each task with a time box

Before each launch, judge how long this task should take and pick one box
from the worker's row. Put it in the brief so the worker knows the expected
size. The box is for sizing; no timer enforces it. Minutes are wall clock,
launch to report.

| Worker | Boxes to pick from |
|---|---|
| Claude subagent (Haiku, Sonnet, Opus) | 5 · 10 · 15 min |
| opencode | 2 · 5 min |

Size the box by the task alone. A Haiku sweep over many files can
need 10; an Opus design question can fit 5. Pick the smallest box you expect
it to finish in.

opencode gets only mechanical work and is fast, so a slow run means
looping.

A worker that runs well past its box was given too much, or too little
to go on. Let it finish, then split the next one smaller or brief it
better. Stop a worker only when it is clearly stuck: no new output for
several minutes, or looping on the same step.

## 6. Run in parallel when pieces are independent

Launch independent pieces in one message so they run together.
While a delegated search runs, leave it to the worker: do other work, or
talk with the user, until it reports.

**At most 5 subagents running at once.** More pieces than that run in
waves: launch 5, and start the next as each one reports. Usage runs out
fast otherwise.

## 7. Watch slow things off the main thread

Anything that takes minutes and needs no judgment while it runs goes off
the main thread: preview and production deploys, CI runs, long builds,
full test suites, migrations on a remote box, a subagent's own long run.

1. **A command you started** runs as a background command. The host
   re-invokes you when it exits; do not poll it.
2. **Something external** (a CI run, a Vercel or Netlify preview, a
   pipeline) goes to a watcher on the cheapest rung, 5 or 10 min box.
   Brief: what to watch, how to read its state, what counts as done or
   failed, and to return the URL or the failing log lines only.
3. While it runs, carry on with independent work or answer the user.
4. When the watcher reports, you judge the result. You diagnose a
   failure; the watcher only reports it.

Never sit in a foreground sleep, poll loop or blocking wait. If the user
has to say "why are you waiting", the rule was already broken.

## 8. Unattended runs (overnight, away from keyboard)

Nobody is there to stop a runaway, and wall clock is free. Speed is no
longer a reason to fan out; only context hygiene and cheaper rungs are.

- **Fewer at once.** At most 2 subagents running at once. Run them in
  waves.
- **No nesting.** A subagent never launches its own subagents. Say so in
  every brief.
- **Cheap rungs only for legwork.** No Opus subagents unless the piece is
  hard by §3; the big model's own effort covers the judgment.
- **A run budget.** Write the total subagent count for the run in the plan
  before starting. Hitting it means stop delegating and finish solo.
- **Morning check.** Report spend at the end: subagents launched, per
  model, and `opencode stats --days 0 --models --cost` if opencode ran.

## 9. Check what comes back

- **You check it.** A cheap worker's own PASS can be wrong. Run the tests,
  read the diff, try a case the worker never saw.
- **Keep or escalate.** `rjv-jev-decisions`' `jev-verify.sh` checks a report
  against its acceptance items; escalate one rung only when something is
  missing.
- **Never let a cheap worker be the gate.** Review, bug-hunting and approval
  stay on the big model or an independent reviewer (`rjv-gated-build`).
  An opencode round in the `rjv-code-review` loop is an independent
  reviewer, the same as Codex. In a gated build the plan's Cast decides who
  approves; an opencode round is the APPROVED gate only when the Cast names
  it.
- **Name the model** when you launch and when you report what came back.
- **No model provenance in artifacts.** No "generated by" lines or AI
  trailers in commits, PRs, docs or code.

## 10. Keep the instructions themselves small

Every line in global instructions (`~/.claude/CLAUDE.md`)
and in a loaded skill is read by every agent, every session. Long or
conflicting instructions cost tokens and make agents stall or ask.

After any edit to them, and whenever the user asks, check:

1. **One owner per rule.** A rule lives in one file; others point to it.
   Global instructions are personal; skills are what the team sees, so a
   rule the team needs is owned by a skill.
2. **No conflicts.** Two lines that tell an agent opposite things (ask vs
   act, wait vs move on, terse vs plain) are fixed at the source. The
   user's global instructions win.

For the rest of the review (repeats inside a file, no-op lines, history,
house prose) and for any edit to a skill, follow `rjv-writing-skills`:
its `REVIEW.md` is the checklist, including which part a cheap worker may
inventory. Done when every repeated rule has one owner and no two lines
conflict.

## Related

- `rjv-jev-decisions`: the model picker and spawn hooks.
- `rjv-subagents-codex`: the same rules for Codex, with local Ollama.
- `rjv-gated-build`: who authors and who reviews on high-stakes builds.
- `rjv-writing-skills`: how to write, review and prune a skill.
