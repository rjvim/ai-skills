# Plan lifecycle — merge, maintenance, timeline, roadmap

Read this when a branch is landing, when work arrives against something already
live, or when someone asks what shipped and when. Not needed to start or resume a
branch.

## Merge — the plan ships, it is never deleted

In the final PR commit, **archive the plan; don't delete it**:

```
git mv .plans/<name>.md .plans/shipped/<YYYY-MM-DD>-<name>.md
# then in that file: Status: shipped · Shipped: <date> · Next Steps → what's left to watch
```

Merge is still the promotion backstop ("anything un-promoted? — rare"), and the
plan still stays under the ceiling — archiving is not permission to fatten it.
What it buys: a durable record of what was built, when, by which cast, and which
decisions were live at the time — the thing git log alone doesn't tell you.

Invariants, both guardable in CI:
- **Top-level `.plans/*.md` = in-flight only.** A plan whose branch is merged and
  still sitting at top level is drift.
- **Every file in `.plans/shipped/` has `Status: shipped | maintenance | closed`
  and a `Shipped:` date.**

The resume grep is unaffected — `.plans/*.md` doesn't recurse, so archived plans
never collide with an active branch.

## Maintenance — the phase after prod

`shipped` is not the end state. Once it's live, the plan moves to `maintenance` and
stays the landing pad for that piece of work:

- A hotfix or follow-up branch gets its **own** plan (one plan per branch, always),
  whose Source of Truth links back to the shipped plan; the shipped plan gets a
  one-line back-link under Current State.
- Prod findings, incidents, and known-gaps go under Current State as one-liners with
  dates — **facts only**. Anything that turns into real work becomes a roadmap item
  or a new branch, not a growing to-do list here.
- When nothing is outstanding, set `closed`. A closed plan is read-only history.

Same ceiling applies. If maintenance notes push a plan toward it, that is the signal
the work belongs in `_docs/` or the roadmap, not in the plan.

## Timeline — reading the plan record back

Because plans are dated, statused, and kept, the archive answers "what did we ship,
when, and why did we build it that way":

```
ls .plans/shipped/                                    # chronological by filename
grep -H "^Status:\|^Shipped:\|^Branch:" .plans/shipped/*.md   # one-line-per-plan timeline
git log --diff-filter=A --format='%ad %s' --date=short -- .plans/  # when each plan opened
```

Read a plan's **Decisions** section for the reasoning that was live at ship time,
and its Source of Truth links for where that truth lives now. When asked for a
delivery timeline, build it from `Started:`/`Shipped:` — not from commit archaeology.

## Roadmap — the backlog (durable)

A branch usually implements a backlog item. Keep a durable backlog in
`_docs/features/<area>/roadmap.md` (or `_docs/architecture/roadmap.md` for
cross-cutting): items with `[planned] | [in-progress] | [shipped]`, tech + product
debt under their own sections. On branch start, set the item `[in-progress]` → link
the branch; on merge, `[shipped]` → link the archived plan. The roadmap is the
forward-looking "what's next"; `.plans/shipped/` is the backward-looking record of
how each item actually got built.
