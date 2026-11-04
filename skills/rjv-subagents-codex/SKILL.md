---
name: rjv-subagents-codex
description: "Codex only; in Claude Code use rjv-subagents-claude. Use at the start of any task with legwork (searching across files, reading logs, reviews, QA passes, screenshots, waiting on builds) and before launching any Codex sub-agent, opencode run or local Ollama run. Owns when to do it yourself, how to split, which model, the brief, time boxes, unattended-run limits and checking results. Triggers: delegate, spawn a subagent, fan out, which model, save tokens, time budget, opencode, local model, waiting on CI or a deploy, blocked main thread, overnight run, instruction bloat."
---

# Subagents: spend the big model on judgment

The big model (Astra or Sol) is the
scarce resource. Usage is rationed and long sessions stall on limits long
before they stall on difficulty. Every minute it spends reading, typing or
sweeping is a minute a cheaper model could have spent.

> **The rule.** The big model designs, splits, briefs, judges and
> integrates. Everything a cheaper worker does equally well goes to the
> cheapest worker that clears the bar. The big model does mundane work
> itself only when it takes 1–2 minutes, or when it is reading code it is
> about to edit anyway.

> **Never block the main thread.** The main thread is where the user
> talks to you. Anything slow (a preview deploy, CI, a long build, a full
> test suite, a remote job) runs in the background or under a watcher on
> the cheapest rung (§7), while you keep working or keep talking.

Binds every orchestrator in Codex. Claude Code has its own copy,
`rjv-subagents-claude`.

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
| Waiting on a deploy, CI, a build or a remote job | Background it or hand it to a watcher (§7). |

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
| **Repo tools** (recon, file reads, edits, running commands) | local Ollama explorer or worker → Luna → Terra |
| **Self-contained text** (context is all in the prompt) | local one-shot → opencode → Luna → Terra |

A local one-shot model has no tools: no files, no shell, no web. opencode
reads files and runs shell commands in its working directory even without
`--auto`, so launch it only through `rjv-opencode-agents`, which sandboxes
text work and watches every run. The local one-shot model sees only the
prompt and can never do recon.

| Rung | Mechanical | Standard | Hard |
|---|---|---|---|
| Codex sub-agent | gpt-5.6-luna, low | gpt-5.6-terra, medium | gpt-6-astra, high |
| opencode | DeepSeek Flash, retry on MiniMax | not used | not used |
| Local Ollama (`rjv-codex-ollama-subagents`) | gemma explorer or worker; qwen coder one-shot | not used | not used |

- **Ask Jev.** `rjv-jev-decisions`' `jev-model-pick.sh` returns the tier, the
  model, and the time boxes. Its hooks fill in a model when you
  forget.
- **Codex reviews.** Use `gpt-6.1-sol` at low effort, including when the
  picker is unavailable. An explicit user model choice takes precedence.
- **Always set the model explicitly.** A subagent that silently inherits the
  parent's model is the most common leak. Only a fresh sub-agent
  (`fork_turns` `"none"` or a number) can take a model; a full-history fork
  rejects the override.
- **Unsure means one rung up.** A failed cheap attempt costs more than the
  saving.
- **Stakes raise the floor.** Money, data, production, security: at least the
  standard rung, and keep even the draft on the host's own cloud models.
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

A vague brief is the usual reason a worker runs long.

## 5. Size each task with a time box

Before each launch, judge how long this task should take and pick one box
from the worker's row. Put it in the brief so the worker knows the expected
size. The box is for sizing; no timer enforces it. Minutes are wall clock,
launch to report.

| Worker | Boxes to pick from |
|---|---|
| Codex sub-agent (Luna, Terra, Astra) | 5 · 10 · 15 min |
| opencode | 2 · 5 min |
| Local Ollama, one-shot text | 5 · 10 min |
| Local Ollama with repo tools (explorer or worker) | 10 · 20 · 30 min |

Size the box by the task alone. A Luna sweep over many files can
need 10; an Astra design question can fit 5. Pick the smallest box you expect
it to finish in.

Why the rows differ: third-party models are fast and get only mechanical
work, so a slow run means looping. Local models are slower and Ollama queues
parallel calls, so their boxes are larger.

A worker that runs well past its box was given too much, or too little
to go on. Let it finish, then split the next one smaller or brief it
better. Stop a worker only when it is clearly stuck: no new output for
several minutes, or looping on the same step.

## 6. Run in parallel when pieces are independent

Launch independent pieces in one message so they run together. Local Ollama
queues concurrent calls, so parallel local runs save tokens and take as
long as running them one after another.
While a delegated search runs, leave it to the worker: do other work, or
talk with the user, until it reports.

**At most 5 sub-agents running at once.** More pieces than that run in
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

- **Fewer at once.** At most 2 sub-agents running at once. Run them in
  waves.
- **No nesting.** A sub-agent never launches its own sub-agents. Say so in
  every brief.
- **Cheapest rungs for legwork.** Local Ollama first, since slow is fine
  overnight, then Luna. No Astra sub-agents unless the piece is hard by §3.
- **A run budget.** Write the total sub-agent count for the run in the plan
  before starting. Hitting it means stop delegating and finish solo.
- **Morning check.** Report spend at the end: sub-agents launched, per
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
  reviewer, the same as Codex.
- **Name the model** when you launch and when you report what came back.
- **No model provenance in artifacts.** No "generated by" lines or AI
  trailers in commits, PRs, docs or code.

## 10. Keep the instructions themselves small

Every line in global instructions (`~/.codex/AGENTS.md`)
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
- `rjv-codex-ollama-subagents`: the local runners.
- `rjv-gated-build`: who authors and who reviews on high-stakes builds.
- `rjv-writing-skills`: how to write, review and prune a skill.
