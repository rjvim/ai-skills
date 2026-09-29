---
name: rjv-jev-decisions
description: "Hand small, closed-set decisions in a Claude Code or Codex session to Jev (TypeSafe's System One model) instead of spending flagship tokens on them. Main use: before spawning a subagent or Codex worker, ask Jev which model tier the task needs (haiku/sonnet/opus, gpt-5.6-luna/terra or gpt-6-astra with effort, or local Ollama) with confidence and stakes gates. Ships PreToolUse hooks for Claude Code and Codex that fill in the model when a subagent is spawned without one, and a decision log for tuning. Also: check a cheap worker's report against its acceptance items and escalate only when something is missing, and score a branch goal for rjv-work-plan's Build mode. Triggers: 'use jev', 'typesafe', 'which model for this subagent', 'pick the model', 'cheaper model routing', 'model selection', 'save tokens on delegation', 'should I escalate', 'did the worker finish', 'cascade', 'build mode check', 'jev hook', 'model pick log'."
---

# Jev decisions — cheap, fast judgments for coding agents

Jev is TypeSafe's System One model. It reads a state and answers typed
questions — Choice (one of a set), Noul (probability of yes), Score (a level)
— with probabilities and a confidence. It does not generate text.

Why it fits a coding session: many decisions an agent makes are closed-set
("which model?", "is this done?", "is this risky?"). A flagship spends a
thinking turn on each. Jev answers in about a second for about
$0.00002 a call (input tokens only, $0.042 per million; output is free).

```text
agent is about to decide something from a fixed set
        │
        ├── code can decide it exactly (count, compare, lookup) ──> code, not Jev
        │
        ├── needs reasoning, several hops, or generating text ────> the agent itself
        │
        └── one semantic judgment over a short state ─────────────> Jev
                                                                     │
                            confidence high ──> act on the answer    │
                            confidence low  ──> go one step safer <──┘
```

## Setup

- `TYPESAFE_API_KEY` in the environment (keys: console.typesafe.ai/keys).
- `curl` and `jq`. No SDK needed.
- Scripts live in `scripts/`; question sets in `decisions/`.

If the key is missing or the call fails, every script exits 3. **Exit 3 means
"no decision", never "stop".** Fall back to the manual ladder below and carry on.

## 1. Pick the model for a delegated task (the main use)

Run before every subagent spawn or Codex worker you would otherwise route by
gut feel:

```sh
scripts/jev-model-pick.sh "Rename getUser to fetchUser across the repo and update call sites"
```

```json
{"tier": "mechanical", "claude": "haiku",
 "codex": {"model": "gpt-5.6-luna", "reasoning_effort": "low"},
 "local_text_only": null, "why": "jev said mechanical at confidence 0.9", "jev": {...}}
```

Spawn with that model, explicitly. `budget_boxes` lists the time budgets
you pick from; Jev picks the model, you pick the box (`rjv-subagents`).

What happens inside, so you can trust or override it:

1. One request, three questions: `tier` (Choice: mechanical / standard /
   hard), `high_stakes` (Noul: money, data, production, security),
   `needs_repo` (Noul: must it touch files or run commands).
2. Code, not Jev, applies the policy from `decisions/routes.json`:
   - confidence below 0.6 → one tier up. A failed cheap attempt costs more
     than the saving.
   - high stakes → at least `standard`, whatever the tier said.
   - `local_text_only` is offered only when the task needs no repo. A local
     Ollama model has no tools (see `rjv-codex-ollama-subagents`).
3. The tier → model mapping is per host in `routes.json`. Edit it there when
   plans or prices change; the question set does not change.

Write the task the way you would brief the worker: what to change, where,
and what done looks like. Jev reads it literally. A vague one-liner gets a
vague, low-confidence tier, which then moves up a tier.

Skip the call when `rjv-subagents` says do it yourself. When Jev is
unreachable (exit 3), pick from the rungs table in `rjv-subagents`.

In Codex, pass both `model` and `reasoning_effort` from the picker's
`codex` field, on a fresh sub-agent (`fork_turns` `"none"` or a number).

## Automatic: the spawn hooks

`hooks/jev-route-hook.sh` is one PreToolUse hook for both hosts. When a
subagent is about to start with no model set, it runs the picker and fills
the model in. The agent sees one line saying what Jev chose and why.

```text
subagent spawn ──> model already set? ──yes──> leave it, log "explicit model"
                         │ no
                         ▼
           Claude fork, custom agent type,  ──yes──> leave it, log why
           or Codex full-history fork?
                         │ no
                         ▼
           Jev picks ──> hook rewrites the spawn with the model
                  │
                  └── Jev unreachable ──> spawn goes ahead unchanged
```

It fails open: no key, a timeout or any error leaves the spawn exactly as
written. An explicit model always wins, so the hook never overrides a
deliberate choice.

Install, pointing at the synced copy in `~/.agents/skills`:

- Claude Code, `~/.claude/settings.json`:
  `"PreToolUse": [{"matcher": "Agent|Task", "hooks": [{"type": "command", "command": "<skill>/hooks/jev-route-hook.sh", "timeout": 15}]}]`
- Codex, `~/.codex/config.toml`:
  ```toml
  [[hooks.PreToolUse]]
  matcher = "collaborationspawn_agent|spawn_agent"

  [[hooks.PreToolUse.hooks]]
  type = "command"
  command = "<skill>/hooks/jev-route-hook.sh"
  timeout = 15
  ```
  Codex runs a new hook only after you approve it in the Codex app or TUI.
  Codex 0.155 names the tool `collaborationspawn_agent`; a matcher of
  `spawn_agent` alone never fires.

**Codex hides the brief from hooks.** Codex 0.155 passes the sub-agent's
message to hooks already encrypted, so the hook judges from the task name
alone (`payout_reconciliation_debug` still reads as hard). For a better pick,
add this to `~/.codex/AGENTS.md`: before `spawn_agent` with `fork_turns`
`"none"`, run `jev-model-pick.sh` on the full brief and pass `model` and
`reasoning_effort` explicitly. The hook then sees an explicit model and
stays out of the way. Claude Code hooks see the whole prompt, so no
instruction is needed there.

## The decision log

Every pick, skip and failure is appended to
`~/.local/state/rjv-jev/model-pick.jsonl` (set `JEV_LOG`, or `off`). Each
line has the time, host, the first 500 characters of the task, Jev's raw
answers and the model chosen.

```sh
scripts/jev-log-review.sh 7     # last 7 days
```

It counts picks per host and tier, how often low confidence or high stakes
moved a task up, and lists the borderline picks worth reading by hand.
Tune `thresholds` in `routes.json` from what those borderline tasks
actually needed. Inside Codex's sandbox the picker may not be allowed to
write the log; the hook, which runs outside the sandbox, still logs every
spawn.

## 2. Keep or escalate a cheap worker's result

The cascade: cheap model does the work, Jev checks it, a strong model redoes
it only when the check fails. TypeSafe's own extraction cascade used this
shape (see their SDE cascade cookbook).

```sh
echo '{"task": "Add retry to the payout client",
       "acceptance": ["retries 3 times with backoff", "has a test for the retry"],
       "report": "<the worker'\''s final message or a diff summary>"}' \
  | scripts/jev-verify.sh
```

```json
{"escalate": true, "weakest": {"item": "has a test for the retry", "done": 0.2}, "items": [...]}
```

One Noul per acceptance item. Any item below `JEV_DONE_MIN` (default 0.7)
means escalate: hand the weakest item to the next tier up, or fix it
yourself if it is small.

This checks what the report *says*. It does not run tests. A worker that
claims a passing test it never ran will pass this check. Keep running the
tests yourself on anything that matters.

## 3. Build mode for rjv-work-plan

`rjv-work-plan` says Build mode is `spec-driven` when any listed condition
holds, and gated when money, production or independent review is involved.
That rule is a set of yes/no conditions, which is what Nouls are for:

```sh
echo '{"branch_goal": "Add a Stripe refund webhook that updates order status"}' \
  | scripts/jev-ask.sh decisions/build-mode.json
```

Combine in your head or in code: any of the first three above 0.5 →
`spec-driven`; `money_or_production` or `independent_review` above 0.5 →
`gated + spec-driven`; none → `simple`. rjv-work-plan's rule stays the
authority. Use this as a second opinion when the call feels borderline.

## Writing your own decision

`scripts/jev-ask.sh QUESTIONS.json` takes any TypeSafe `questions` map and a
state on stdin. `JEV_DRY_RUN=1` prints the request without sending it.
Rules that keep Jev accurate, from TypeSafe's own list of known weak spots:

- One judgment per question. Two dimensions → two questions, same request.
- Put the meaning in the question text. Question ids are never sent.
- Point at state by name: "`task`", "`acceptance[2]`".
- Keep the state short and on topic. Unrelated text lowers accuracy.
- No arithmetic, counting, or date comparison. Do those in code.
- Keep thresholds and combining rules in code, so they can change without
  re-asking.
- A Noul threshold does not carry over to a Choice, or to a reworded Noul.

## Privacy

Every call sends the state to api.typesafe.ai. Never put secrets, customer
data, or credentials in a task description you route. Describe the change;
do not paste the file. With the hooks installed, the first 2000 characters
of every Claude Code subagent prompt go to TypeSafe automatically, and the
log keeps the first 500 on disk.

## Evidence

Live test results, and ideas for the next questions to hand Jev, are in
[`EVIDENCE.md`](./EVIDENCE.md). Read it before changing a threshold or the
high-stakes wording.
