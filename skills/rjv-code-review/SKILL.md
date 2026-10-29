---
name: rjv-code-review
description: "Review a code change, a proposed fix or a design for behavioral regressions, especially when a prior review missed a bug. Also runs the round-numbered review loop: Claude writes a brief file for Codex, the user relays it, Codex writes a result file, every path absolute. Use for PR reviews, design reviews, follow-up review rounds, writing a review brief, reading a review result, and claims that a fix is clean. Works in Claude Code and Codex."
---

# Code review: prove the neighboring behavior

Review the behavior users can reach. A passing test and a plausible diff do not prove that an old path still works. Use the repository's domain and product review skills alongside this one when they apply. Honor read-only limits.

A stated scope limits what you report on. It does not limit what you read. When an existing rule, producer or feature the change depends on sits outside the scope, read it anyway and report the gap as a finding: "the brief put X out of scope, and the change depends on it". Never return a clean verdict that rests on code the scope told you to skip.

## Before judging the diff

1. State the behavior the change promises and the old behavior it must preserve.
2. Trace each changed route or entry point through its caller, state read, decision, write, and downstream reader. Include unchanged files that are load-bearing in that chain, including any outside the requested scope.
3. Search for an existing feature that already does part of the job: shows, hides, prefills, skips, defaults or verifies the same value or step. Search by behavior (the field, the step, the status), not by the diff's own names. A new path should build on that feature or state why not. A second, parallel rule for the same decision is a finding.
4. Find the domain's existing predicate or policy for every new condition. Compare the new condition with all callers of the old one. Check legal boundary values such as `null`, empty string, missing key, incomplete record, and stale record. A display status is not automatically the authority for an access or redirect decision.
5. For every changed write, list all current producers and owners of that value: user input, signup identity, imported or prefilled data, provider response, existing record, and configuration where relevant. Read the existing precedence and preservation rules before approving a new source or overwrite.
6. Check the order of existing guards and migrations. A new fast path at the start of a route must not write before a completed-state guard, ownership check, or lazy migration that the old path reached first.

## Try to disprove the change

Choose concrete, reachable states at the intersections the diff creates:

- new record, resumed record, edited record, and record created before the switch or fix;
- default and enabled configuration, including tenant or account modes that alter field ownership;
- missing, partially verified, fully verified, and previously verified values from a different source;
- first visit, reload, direct link, and the path after a failed submission where relevant.

For each chosen state, follow the resulting route, visible fields, stored values, verification state, and downstream payload. Compare a new fast path with the existing form or workflow it replaces. Check that a field's hide or skip decision refers to the same value the form or fast path will submit; a verified account column does not validate stale step data. If the old workflow deliberately lets the user edit a value, an automatic fill must not silently remove that choice. If an existing producer marks a value verified, do not assume signup is its only source.

Do not treat facts supplied in a review brief as proof of the conclusion. Verify the facts that carry the decision and look for a legal state they omit. Tests are evidence for their exact fixture only: inspect whether the fixture covers the competing producer, boundary value, and old feature. A test that asserts the new implementation's output can still encode the wrong product contract.

## Follow-up rounds

Review the new commits against the last reviewed SHA. First check whether each old finding is fixed. Then treat every new branch, read, write, and call site introduced by the fix as a fresh change. Re-run the preservation states; a fix that solves the reported fixture can break an adjacent path. Withdraw a prior finding only with the specific code evidence that disproves it.

## The review loop

The user runs it by hand. Claude writes a brief file, the user pastes its
path into Codex, Codex writes a result file, the user pastes that path
back. **Never start Codex yourself** unless the user asks in this session.

```
~/.reviews/<project>/<topic>/round-1-brief.md    Claude writes
~/.reviews/<project>/<topic>/round-1-result.md   Codex writes
~/.reviews/<project>/<topic>/round-2-brief.md    Claude writes after fixing
...
```

Review files live outside the repo, so they never show up in git status or
a commit. `<project>` is the repo folder's name.

- `<topic>` is short and stable for the whole loop: `pr-4335`,
  `checkout-mandate-design`. Every round of one review shares it.
- Rounds count 1, 2, 3, ... Each round is its own pair of files. Never
  overwrite or append to an earlier round.
- **Every path you print is absolute**, from `/`. Expand `~` to the home
  directory; never print a relative path or `~`.
  The user copies it straight into the other tool.
- In Claude Code, gather the facts (diff, SHAs, prior art, callers) with
  cheap subagents per `rjv-subagents-claude`. The big model writes the
  brief.
- End the reply with the brief's absolute path on its own line.

### Brief file

```markdown
# <Code | Design> review — <topic> — round <N>

Repo: <absolute repo path>
Branch / PR: <branch>, PR <number or none>
Range: <base SHA>..<head SHA>          (code review)
Design doc: <absolute path>            (design review)
Previous result: <absolute path of round N-1 result, or none>

## What changed and what must still work
<the promised behavior; the old behavior it must preserve>

## Claim to disprove
<the claim, not the conclusion>

## Prior art
<existing features, predicates, producers and modes in the area, with
file paths; each fact marked "checked in code" or "not checked">

## Old findings (round 2 onward)
<each round N-1 finding, its status, and the commit that claims to fix it>

## Scope
<what to report on. Only code the change cannot reach is out of scope.>

## How to reply
1. Load `rjv-code-review` and follow it.
2. Write your result to <absolute path of round-N-result.md>.
3. First line: `Round <N>: CLEAN | FINDINGS | INCONCLUSIVE`.
4. Round 2 onward: list each old finding as FIXED, OPEN or WITHDRAWN,
   with the code evidence.
5. Each new finding as its own block: WHAT, WHERE (file:line), SEVERITY
   (LOW | MEDIUM | HIGH), STATE (the reachable state that breaks), FIX.
6. Say what you inspected and what you did not run.
7. End your reply with the result file's absolute path on its own line.
```

### Reading a result

Read the round N result. Fix or dispute each finding, then write the round
N+1 brief that lists every old finding with its fixing commit. Stop when a
round comes back `CLEAN`, or when the user stops the loop.

### Results stay in files until the review is done

A loop can run 10 to 20 rounds. Never post each round to the PR or the
issue; that buries the thread and slows the loop. Rounds live only in the
brief and result files.

When the review is done (a round comes back `CLEAN`, or the user ends the
loop), write one summary where the project records reviews (for example
one PR comment with the head SHA, the reviewers, the round count, what ran
and any accepted risk). If the project asks for none, write none.

### Cleaning up

- As soon as the review is done and its summary is written, delete
  `~/.reviews/<project>/<topic>/` and say so in one line. The summary is
  the record; the round files are not kept.
- Also delete the folder when the PR merges or closes.
- When you start a new loop, delete every topic folder under
  `~/.reviews/` whose PR has merged or closed. A folder for a still-open PR
  that sat 14 days is a stalled review: keep it and say so.

## Design reviews

The same loop and files, with a design doc in place of a commit range. The
reviewer tries to disprove the design before any code exists:

- Search for an existing feature, predicate or producer that already owns
  the decision. A second, parallel rule is a finding.
- Walk the states from "Try to disprove the change" through the design:
  new, resumed and old records; each tenant mode; failed and reloaded paths.
- For every value the design writes, name its current producers and who
  wins.
- Name what the design leaves undecided. An open question that changes
  behavior is a finding, not a footnote.

## Writing a brief for another reviewer

The brief steers the review, so a blind spot in it becomes a blind spot in the review.

- Name the prior art you know: existing features, predicates, producers and modes in the area, with where they live.
- Tell the reviewer to search for more before judging the diff.
- Never put an existing producer, predicate or replaced form out of scope. Scope out only code the change cannot reach.
- Give the claim to disprove, not the conclusion. Label every fact as checked in code, or not checked.
- On a follow-up round, give the last reviewed SHA, each old finding, and the commit that claims to fix it.

## Report

For every finding, give the wrong behavior, reachable caller chain, affected state, severity, and the existing rule it violates. Distinguish observed runtime behavior from code inference. Name what was inspected and what was not run. Say “code review clean” only after the selected preservation states and negative paths have evidence. If runtime or delivery checks were required but unavailable, keep the overall verdict inconclusive; never promote a code-only pass to product approval.

## Escape that shaped this skill

An onboarding review followed a new redirect's derived status string but missed the account's existing `isOnboardingComplete()` rule. An empty provider id made those answers disagree and could send an existing account to the new-account form. A later fix copied verified signup contact over existing account contact, missing provider prefill and the multiple-account mode where contact remains editable. The earliest catch was a canonical-predicate search and a producer/ownership map before accepting either change. On the follow-up review, repeat those checks for the fix itself.

Two review rounds passed the contact fill because the brief put the contact form and its flows out of scope, never named the page's existing rule that hides verified fields, and the reviewer stayed inside the brief. A search for an existing feature that already hides or skips the same fields would have found it in one step.
