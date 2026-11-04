# Plan lifecycle: merge, maintenance, timeline, roadmap

Read this when a branch is landing, when work arrives against something already
live, or when someone asks what shipped and when. Starting or resuming a branch
needs only `SKILL.md`.

## Merge: the plan ships with the code, it is never deleted

In the final PR commit, archive the plan:

```
git mv .plans/<name>.md .plans/shipped/<YYYY-MM-DD>-<name>.md
# then in that file: Status: shipped · Shipped: <date> · Next Steps → what's left to watch
```

Merge is the promotion backstop: check for anything un-promoted (rare). The
archived plan stays under the same ceiling. The archive records what was built,
when, by which cast, and which decisions were live at the time, which git log
alone does not tell you.

Invariants, both guardable in CI:
- **Top-level `.plans/*.md` = in-flight only.** A plan whose branch is merged
  and still sits at top level is drift.
- **Every file in `.plans/shipped/` has `Status: shipped | maintenance | closed`
  and a `Shipped:` date.**

The resume grep is unaffected: `.plans/*.md` does not recurse, so archived plans
never collide with an active branch.

## Maintenance: the phase after prod

Once the work is live, the plan moves to `maintenance` and stays the landing
pad for that piece of work:

- A hotfix or follow-up branch gets its **own** plan, whose Source of Truth links
  back to the shipped plan. The shipped plan gets a one-line back-link under
  Current State.
- Prod findings, incidents and known gaps go under Current State as dated
  one-liners, **facts only**. Anything that turns into real work becomes a
  roadmap item or a new branch.
- When nothing is outstanding, set `closed`. A closed plan is read-only history.

Maintenance notes that push a plan toward the ceiling signal that the work
belongs in `_docs/` or the roadmap.

## Timeline: reading the plan record back

Plans are dated, statused and kept, so the archive answers "what did we ship,
when, and why did we build it that way":

```
ls .plans/shipped/                                    # chronological by filename
grep -H "^Status:\|^Shipped:\|^Branch:" .plans/shipped/*.md   # one-line-per-plan timeline
git log --diff-filter=A --format='%ad %s' --date=short -- .plans/  # when each plan opened
```

Read a plan's **Decisions** section for the reasoning that was live at ship
time, and its Source of Truth links for where that truth lives now. Build a
delivery timeline from `Started:`/`Shipped:` fields.

## Roadmap: the durable backlog

When a branch implements a backlog item, track it in
`_docs/features/<area>/roadmap.md` (or `_docs/architecture/roadmap.md` for
cross-cutting work): items marked `[planned] | [in-progress] | [shipped]`, with
tech and product debt under their own sections. On branch start, set the item
`[in-progress]` and link the branch. On merge, set `[shipped]` and link the
archived plan. The roadmap looks forward; `.plans/shipped/` records how each
item actually got built.
