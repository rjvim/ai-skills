---
name: rjv-diff-checklist
description: A repo's reliability checklist where each item fires on a trigger readable from a diff, so review checks only the 3 to 10 items that match and nobody memorises past outages. Use when reviewing a diff in a repo with a checklist, when a bug escaped review or caused an incident or revert, when starting a checklist, pruning one, or measuring whether the reviewer catches real bugs. The review itself is rjv-code-review.
---

# Diff-triggered checklist

Past incidents become questions a reviewer asks only when the diff
touches the area that caused them.

## The file

`REVIEW.md` at the repo root holds what the reviewer pays attention to
in this code, and the checklist. One item per entry:

```text
### <short name>
Trigger: <readable from a diff: a path glob, a symbol, a migration, a new field>
Check:   <one question the reviewer answers yes or no>
Source:  <PR, revert or incident that taught it, with date>
```

Example:

```text
### Old records load
Trigger: a new column or field on a stored record or message type
Check:   does a record written before this change still load and render?
Source:  <the PR or incident where an old record broke>
```

## Run it in a review

1. Read the file from the base branch: `git show origin/main:REVIEW.md`.
   **Never read it from the change under review.** A change that can
   edit its own checks is unchecked.
2. Match each trigger against the diff. Check only the items that fire.
3. Tag each finding: **Important** (must fix), **Nit** (author's
   choice), **Pre-existing** (was already broken; never block the
   author on it).

To enforce this before review, install `check-edits.sh` from `rjv-laravel-hooks`. It works in any stack and fails a push that edits a protected file without a stated reason.

Done when every fired item has an answer and every finding has a tag.

## Add an item

An escaped bug becomes an item only when both hold:

- the same kind of bug shows up in at least 2 PRs, reverts or
  incidents;
- a reviewer could spot it from the diff alone.

Then try to disprove it: run the trigger against 3 recent clean PRs.
An item that fires on most of them is noise; narrow the trigger. The
user approves each new item in a PR.

A bug that a reviewer misses on a small diff is the strongest case
for an item.

## Prune

Every 3 months, remove items that never fired, items a lint rule or
test now enforces, and items whose code is gone. The file only grows
if nobody removes lines.

## Measure the reviewer

Before tuning the reviewer or this file, build a small eval:

- 5 to 10 past PRs that caused a revert or incident, each reset to the
  commit at review time, each with a one-sentence answer key.
- Score a hit only when a finding describes that bug.
- Add an equal number of merged PRs that stayed clean; findings there
  count as over-flagging.
- Keep the PRs you tune on apart from the PRs you score on.

Count recall at each stage (raw findings, after verification, final
report) separately, so you can see where a found bug gets lost. Stop
tuning when the next gain would only fit the eval.

Done when the eval has an answer key per PR and a clean control set.
