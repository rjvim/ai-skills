---
name: rjv-advisor-fable
description: Claude Code only. When to consult the Fable advisor in a session started with `claude --advisor fable`, so Fable is spent only on decisions while Opus or Sonnet does the work. Use when the session has an advisor tool, when the user says advisor, Fable advisor or "ask Fable", or asks how to turn the advisor on for one session. Which model does delegated work stays with rjv-subagents-claude.
---

# Fable advisor, per session

The advisor is a Claude Code server tool. With it on, the main model
can call a stronger model that reads the whole conversation and
returns guidance. Here the main model stays whatever the user runs
(usually Opus) and Fable is the advisor, for chosen sessions only.

## 1. Check it is on

| You see | Do |
|---|---|
| an `advisor` tool in your tool list | go to step 2 |
| no advisor tool | tell the user to restart with `claude --advisor fable`, and carry on without it |
| the user asks how to turn it on | same answer: `claude --advisor fable` for this session only |

**Never suggest `/advisor fable` or setting `advisorModel`.** Both save
Fable as the advisor for every future session, and the user wants it
per session. To turn it off mid-session, `/advisor off` is fine.

If launch fails asking for Fable usage-credit consent, tell the user:
run `/model fable` once, accept, then `/model opus`.

Done when the advisor is confirmed on, or the user has the restart line.

## 2. When to consult

Consult at exactly these **checkpoints**:

1. **Plan lock**: before the first edit of a task with more than one
   file or more than one way to do it.
2. **Repeat error**: the same error, failed test or rejected approach
   shows up a second time.
3. **Before done**: before you report a task finished, after tests ran.
4. **User asks**: "ask the advisor", "check with Fable".

Skip it for questions, lookups, one-file fixes and anything under
about five tool calls. One call per checkpoint; a second call at the
same checkpoint needs new evidence since the first.

Why the limit: every call rereads the full transcript at Fable rates
with no cache, so calls cost more as the session grows. Late in a long
session, suggest `/compact` to the user before the before-done call.

Done when each checkpoint reached in the task has one advisor call.

## 3. Use the advice

- Apply it, unless your evidence contradicts it (a step fails, a file
  says otherwise). Then tell the user about the conflict in one line.
- Say in one line what the advisor changed, if anything.

## 4. Subagents

Subagents inherit the advisor. A Haiku or Sonnet worker can then spend
Fable tokens on legwork. Add this line to every legwork brief: "Do not
call the advisor." Leave it out only for a subagent doing judgment
work the user wants checked.

Done when every brief sent this session has the line or a reason to
leave it out.
