---
name: rjv-verify-skill
description: Write or harden a repo's own `verify` skill - the smoke harness that boots, drives and inspects the running app before a commit. Use when a repo has an app but no verify skill, when a verify run is slow or flaky, or when asked to make an agent able to test its own changes end to end. When to run it lives in rjv-verify.
---

# Writing a repo's verify skill

A verify skill gives an agent hands and eyes on the running app. It
lives in the repo, next to the code it checks, and every agent runs it
before a commit.

## 1. Place and name it

| Repo | Skill |
|---|---|
| one app | `.claude/skills/verify/SKILL.md` |
| several apps | one per app: `.claude/skills/verify-<app>/SKILL.md` |

Codex reads the same files when the repo's `AGENTS.md` points to them.
An existing local-test skill (for example `carnelian-local-test`) is a
verify skill already: harden it, never add a second one.

## 2. Write five sections

1. **Boot**: the exact command, port, env file, and the ready line to
   wait for. Reuse a server that is already running; check the port
   first. Seed data with one command.
2. **Drive**: the tool for this kind of app. Web: `agent-browser` with
   `rjv-agent-browser-notes`. Mobile: the simulator or emulator MCP.
   Backend: `curl` or the API harness. Desktop: computer use.
3. **Feature map**: each user flow as path, selectors or calls, and
   the expected result. This is the rubric the agent grades against.
4. **Inspect**: what counts as proof for each flow: a screenshot at a
   named width, a response body, a log line, a row in the database.
5. **Teardown**: kill every server, browser and emulator the run
   started.

## 3. Make it fast and reliable

It is the smoke harness for every change, so a slow or flaky one gets
skipped.

- Time each section. Boot to ready stays under 2 minutes; one flow
  under 1 minute.
- Run it cold 3 times in a row from a fresh session. Fix every
  failure that was not a real bug before shipping it.
- Each failure the skill hits later becomes a fix in the skill, in the
  same commit as the change that exposed it.

Done when a fresh session runs it cold 3 times in a row, each pass
under 5 minutes, and teardown leaves no process behind.
