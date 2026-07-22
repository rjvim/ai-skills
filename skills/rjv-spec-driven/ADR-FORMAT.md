# ADR format — decisions + why

ADRs record *that* a decision was made and *why* — the thing you can't rederive from
code on a big system. Adapted from mattpocock/skills `domain-modeling`.

Live in `docs/adr/` (or `<area>/docs/adr/` in a multi-context repo), numbered
`0001-slug.md`, `0002-slug.md`. `ls` is the index. Create the dir lazily on the
first ADR. Scan for the highest number and increment.

## Template

```md
# {Short title of the decision}

{1-3 sentences: the context, what we decided, and why.}
```

That's it — an ADR can be one paragraph. The value is recording the decision and its
reason, not filling sections.

**Optional sections** (only when they add value; most ADRs skip them):
- `Status:` frontmatter (`proposed | accepted`) — set when the ADR is created; do
  not mutate it later.
- **Considered options** — only when the rejected alternatives are worth remembering.
- **Consequences** — only when non-obvious downstream effects need calling out.

## Immutability — committed ADRs are append-only history

An ADR may be corrected while it is a new, uncommitted file. After its first
commit, **never edit, rename, replace, or delete it**—including on the same feature
branch. Before touching an existing ADR, check `git log -- <path>`; any history
means it is immutable.

When a decision changes or an old ADR is wrong, create the next numbered ADR and
link the old one without modifying it:

```md
# {New decision}

Supersedes: [ADR NNNN](./NNNN-old-decision.md)

{What changed, the new decision, and why.}
```

The successor carries the current decision; the original remains evidence of what
was decided at that point in time. Corrections of historical facts use the same
successor pattern. If a human explicitly requests a history rewrite, stop and get
confirmation that they intend to break ADR immutability.

## When to write one — all three must hold

1. **Hard to reverse** — changing your mind later costs something real.
2. **Surprising without context** — a future reader will wonder "why this way?".
3. **A real trade-off** — genuine alternatives existed and you picked one for reasons.

Miss any one → skip it. Easy to reverse? you'll just reverse it. Not surprising?
nobody wonders. No alternative? nothing to record.

**Qualifies:** architectural shape, integration patterns between contexts,
technology lock-in (DB, bus, auth), boundary/ownership decisions, deliberate
deviations from the obvious path, constraints invisible in code (compliance, a
partner's latency SLA), non-obvious rejected alternatives.

**Real-time, on the branch.** Decision made → write the ADR now, as a branch commit
that merges with the code. A mid-branch reversal creates and commits a new,
numbered successor ADR; it never edits the committed original.
