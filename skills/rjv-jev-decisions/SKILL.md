---
name: rjv-jev-decisions
description: "Hand small, closed-set decisions in a Claude Code or Codex session to Jev (TypeSafe's System One model) instead of spending flagship tokens on them. Main use: before spawning a subagent or Codex worker, ask Jev which model tier the task needs (haiku/sonnet/opus, gpt-5.4-mini/gpt-5.5 effort, or local Ollama) with confidence and stakes gates. Also: check a cheap worker's report against its acceptance items and escalate only when something is missing, and score a branch goal for rjv-work-plan's Build mode. Triggers: 'use jev', 'typesafe', 'which model for this subagent', 'pick the model', 'cheaper model routing', 'model selection', 'save tokens on delegation', 'should I escalate', 'did the worker finish', 'cascade', 'build mode check'."
---

# Jev decisions — cheap, fast judgments for coding agents

Jev is TypeSafe's System One model. It reads a state and answers typed
questions — Choice (one of a set), Noul (probability of yes), Score (a level)
— with probabilities and a confidence. It does not generate text.

Why it fits a coding session: many decisions an agent makes are closed-set
("which model?", "is this done?", "is this risky?"). A flagship spends a
thinking turn on each. Jev answers in about half a second for about
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
{"tier": "mechanical", "claude": "haiku", "codex": "gpt-5.4-mini",
 "local_text_only": null, "why": "jev said mechanical at confidence 0.9", "jev": {...}}
```

Then spawn with that model, explicitly. Never let a subagent inherit the
parent's model silently.

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

Skip the call when the answer is obvious (a one-file read: do it yourself;
a design decision: it stays with you), or when the task is below the
break-even size in `rjv-gated-build`'s model economy.

**Manual ladder when Jev is unavailable:** mechanical → haiku / gpt-5.4-mini,
scoped change → sonnet / gpt-5.5 medium, design or unknown-cause debugging
→ opus / gpt-5.5 high. Stakes raise the floor to the middle rung.

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
do not paste the file.

## Evidence

- Built 2026-09-21 against the live TypeSafe docs (jev-1.13).
- Verified offline: request bodies match the documented API shape; the
  routing rules give the expected tier for confident, unsure and high-stakes
  answers; verify escalates on a missing item; a missing key exits 3.
- **Not yet verified:** a live call. No key was set on the building machine.
  The thresholds (0.6, 0.5, 0.7) are starting points, not tuned values. Log
  Jev's answers next to what the task actually needed for a week, then tune.
- Outside reports: a four-tier routing test measured about 0.65s and
  $0.000026 a call, all 40 calls routed correctly, and borderline middle-tier
  prompts came back at confidence 0.57–0.67. That is why low confidence
  moves up a tier here.

## Other decisions people give Jev in coding agents

Not built here. Candidates for the next question set:

- Tool-call gate: is this shell command destructive? (PreToolUse hook)
- Stop gate: does the transcript show the task finished? (Stop hook)
- Which skill fits this turn, or none? (TypeSafe skill-suggestion cookbook)
- Which files are relevant to this task, ranked by a per-file Noul.
- Which old tool outputs can be pruned from context.
