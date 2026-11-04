# The review loop: round files

The loop branch of [`rjv-code-review`](SKILL.md). Read it when you write
a round brief, read a round result, or clean up after a review.

Claude writes a brief file and the reviewer writes a result file. Two
reviewers take the same files:

| Reviewer | Who sends the brief | How |
|---|---|---|
| Codex | the user, by hand | the user pastes the brief path into Codex and the result path back. Start Codex yourself only when the user asks in this session. |
| opencode | Claude | launch it through `rjv-opencode-agents` in `repo` mode, as below. |

Use opencode when the user asks for it or names it as a round's
reviewer. An opencode round is a cheap second opinion: its `CLEAN` does
not approve a gated, money or production change alone
(`rjv-subagents-claude` §9).

```
~/.reviews/<project>/<topic>/round-1-brief.md    Claude writes
~/.reviews/<project>/<topic>/round-1-result.md   the reviewer writes
~/.reviews/<project>/<topic>/round-2-brief.md    Claude writes after fixing
...
```

Review files live outside the repo, so they never show up in git status
or a commit. `<project>` is the repo folder's name.

- `<topic>` is short and stable for the whole loop: `pr-4335`,
  `checkout-mandate-design`. Every round of one review shares it.
- Rounds count 1, 2, 3, ... Each round is its own pair of files. Write
  every round to new files and leave earlier rounds unchanged.
- **Every path you print is absolute**, from `/`. Expand `~` to the home
  directory, so no printed path is relative or starts with `~`.
  The user copies it straight into the other tool.
- In Claude Code, gather the facts (diff, SHAs, prior art, callers) with
  cheap subagents per `rjv-subagents-claude`. The big model writes the
  brief.
- End the reply with the brief's absolute path on its own line.

The review is **done** when a round comes back `CLEAN` or the user ends
the loop.

## Brief file

Fill it by the rules in "Writing a brief for another reviewer" in
`SKILL.md`.

```markdown
# <Code | Design> review: <topic>, round <N>

Repo: <absolute repo path>
Branch / PR: <branch>, PR <number or none>
Range: <base SHA>..<head SHA>          (code review)
Design doc: <absolute path>            (design review)
Previous result: <absolute path of round N-1 result, or none>

## What changed and what must still work
<the promised behavior; the old behavior it must preserve>

## Claim to disprove
<the claim the change makes; leave your own conclusion out>

## Prior art
<existing features, predicates, producers and modes in the area, with
file paths; each fact marked "checked in code" or "not checked">

## Old findings (round 2 onward)
<each round N-1 finding, its status, and the commit that claims to fix it>

## Scope
<what to report on. Only code the change cannot reach is out of scope.>

## How to reply
1. Read <absolute path of the installed rjv-code-review SKILL.md, e.g.
   /Users/<you>/.agents/skills/rjv-code-review/SKILL.md> and follow it.
   This is a read-only review: edit, stage or commit nothing in the
   repo. The only file you write is the result file below.
2. Write your result to <absolute path of round-N-result.md>.
3. First line: `Round <N>: CLEAN | FINDINGS | INCONCLUSIVE`.
4. Round 2 onward: list each old finding as FIXED, OPEN or WITHDRAWN,
   with the code evidence.
5. Each new finding as its own block: WHAT, WHERE (file:line), SEVERITY
   (LOW | MEDIUM | HIGH), STATE (the reachable state that breaks), FIX.
6. Say what you inspected and what you did not run.
7. End your reply with the result file's absolute path on its own line.
```

## Sending a round to opencode

Write the brief, then start the watcher from `rjv-opencode-agents` with
the repo as its directory and a one-line launch prompt in a file:

```text
Read the code review brief at <absolute brief path> and do exactly what it says.
```

```sh
opencode-watch.sh <repo> <launch-prompt-file> <absolute result path> 60 repo
```

Reviews read a lot of code, so give them a 60 minute cap; the watcher
still kills a run that goes silent. Keep working while it runs. When it
reports `DONE`:

- `tree=CHANGED`: the reviewer touched the repo. Discard the round,
  restore the tree, and tell the user.
- The result's first line is not `Round <N>: CLEAN | FINDINGS |
  INCONCLUSIVE`: treat the round as failed and follow
  `rjv-opencode-agents` §5.
- Otherwise read it as below. Say which model wrote it; the `DONE` line
  names it.

## Reading a result

Read the round N result. Fix or dispute each finding, then write the
round N+1 brief that lists every old finding with its fixing commit.
Repeat until the review is done.

## Results stay in files until the review is done

A loop can run 10 to 20 rounds. Keep every round in the brief and
result files only. Posting each round to the PR or the issue buries the
thread and slows the loop.

When the review is done, write one summary in the place the project
records reviews (for example one PR comment with the head SHA, the
reviewers, the round count, what ran and any accepted risk). If the
project asks for none, write none.

## Cleaning up

- As soon as the review is done and its summary is written, delete
  `~/.reviews/<project>/<topic>/` and say so in one line. The summary is
  the record; the round files are not kept.
- Also delete the folder when the PR merges or closes.
- When you start a new loop, delete every topic folder under
  `~/.reviews/` whose PR has merged or closed. A folder for a still-open
  PR that sat 14 days is a stalled review: keep it and say so.

Done when: the summary is written (or the project asks for none) and
the topic folder is gone.
