---
name: rjv-opencode-agents
description: "Launch and watch an opencode run that does delegated work, so a slow or dead run is caught and handled while you keep working. Use whenever you hand a task to opencode (text drafting, summaries, lint passes, read-only repo reviews), when an opencode run is taking longer than its box, or when one died or hung. Owns the launch command, the liveness watcher, the retry and fallback rules, and checking the result. Which tasks go to opencode at all is owned by rjv-subagents-claude / rjv-subagents-codex."
---

# opencode agents: launch, watch, recover

opencode is the cheapest worker (DeepSeek v4.1 Flash, one retry on
MiniMax M3). It is also the one most likely to run long or die
silently. The launcher never waits on it in the foreground: every run
goes through the **watcher**, and you keep working while it reports.

Which tasks go to opencode, and the 2 / 5 minute boxes, are owned by
`rjv-subagents-claude` (Codex: `rjv-subagents-codex`). This skill owns
what happens after you decide.

## 1. Pick the mode

| The task needs... | Mode | Where opencode runs |
|---|---|---|
| only the text in the prompt | `text` | a fresh empty directory the script makes |
| to read a repo (review, recon) | `repo` | the repo, with `--auto` |

**opencode reads files and runs shell commands in its working
directory even without `--auto`** (probe, 2026-11-04: it read a file
and wrote another with no approval). So `text` mode always runs in an
empty directory, and anything that touches secrets, customer data or
production stays on Claude, as `rjv-subagents-claude` §3 says.

In `repo` mode the brief says read-only unless edits are the task. The
watcher fingerprints the git tree before and after. `tree=CHANGED` on a
read-only brief: discard the result, list the paths from `git status
--porcelain` in your report, and never commit them. Revert only when the
user says so.

## 2. Launch through the watcher

Write the brief to a file, then start the watcher. It runs on its own;
you never sit in a foreground wait for it.

```sh
S=<this skill's dir>/scripts/opencode-watch.sh
$S <dir> <brief-file> <result-file> <cap-minutes> text|repo
```

- `<result-file>`: absolute path. In `repo` mode the brief tells
  opencode to write its answer there. In `text` mode the script fills it
  from the run's final text.
- `<cap-minutes>`: the hard ceiling per model attempt. Set it to 3x the
  box (box 2 → cap 6, box 5 → cap 15). The box sizes the task; the cap
  only catches a run that will never finish.

**Claude Code**: start it with the Monitor tool, `timeout_ms` above the
cap times two (both models may run), so each event line arrives as a
notification. **Codex**: run it as a background command and read its
stdout when it exits.

## 3. React to the events

The watcher prints one line per event.

| Event | Meaning | You do |
|---|---|---|
| `START` | an attempt began | keep working |
| `ALIVE` | heartbeat every 2 min, still producing | keep working |
| `STALL silent=N` | one check saw no change in log, result, database or CPU | nothing yet; 4 in a row is a kill |
| `KILL reason=silent` | dead: 4 silent checks (2 min at 30 s) | the watcher retries on MiniMax by itself |
| `KILL reason=cap` | alive but over the cap | the watcher retries; the task is too big, so split it next time |
| `EXIT code=N` | one attempt ended; a retry may follow | wait for `DONE` |
| `DONE status=ok` | result file is non-empty | check it (§4) |
| `DONE status=failed` | both models failed | §5 |

A run that is alive is never killed early. Time past the box means
the task was too big or the brief too thin; let it finish under the
cap, then split the next one smaller.

## 4. Check the result yourself

- Read the result file. opencode's own "done" is a claim.
- Mechanical output (a list, a lint pass): spot-check three items
  against the source.
- `repo` mode: `tree=unchanged` on a read-only brief. `tree=CHANGED` on a
  read-only brief: discard the result, list the paths from `git status
  --porcelain` in your report, and never commit them. Revert only when the
  user says so.
- Report what came back and which model produced it (the `DONE` line
  names it).

## 5. When both models fail

Walk this in order and stop at the first that applies:

1. The brief asked for too much: split it in two and launch both.
2. The brief was unclear (the log shows it asking questions or
   wandering): rewrite the brief and launch once more.
3. Otherwise hand the task to a Haiku subagent (Sonnet if it needs
   judgment), with the same brief.

Never launch the same brief a third time on opencode.

## 6. Tuning and spend

Environment knobs, all optional: `OPENCODE_CHECK_SEC` (30),
`OPENCODE_SILENT_MAX` (4), `OPENCODE_HEARTBEAT_MIN` (2),
`OPENCODE_MODELS` (the two-model list). The JSON event log only grows
at step boundaries, which is why CPU time and the database WAL also
count as signs of life.

After a batch of runs, check spend with
`opencode stats --days 0 --models --cost`.

The per-run log sits beside the result as `<result-file>.log`.

Tested 2026-11-04: a short text task returned in 5 s; a bad model name
fell through to the second model; a 3,000-word essay under a 1 min cap
stayed alive (no STALL) and was killed at the cap; a fake opencode that
hangs with no output was killed after 2 silent checks on both models,
with no orphan processes left.

## Related

- `rjv-subagents-claude` / `rjv-subagents-codex`: which work goes to
  opencode, and the boxes.
- `rjv-codex-ollama-subagents`: local models through
  `opencode-local.sh`, which has its own memory gate.
