# Three extensions, written to travel

Derived in one repo, written here so the next one inherits them. Source
reasoning in `four-borrowed-frameworks.md`; this file is the portable form.

Each says what it needs, so a repo can tell at a glance whether it applies.
None of them is stack-specific. Two of the three need a data source the repo
may not have, and that is stated up front rather than discovered halfway.

---

## A. The rung — universal, needs nothing

**Applies to:** every repository. No telemetry, no runtime, no billing.

**The idea.** A rule's strength is what it costs to violate. Right now an index
of rules shows advice and hard blocks looking identical, which is the single
most common way a harness rots: a rule slides from enforced to advisory and the
index still lists it.

**The ladder.**

| Rung | Enforcement | Cost of violating |
|---|---|---|
| 5 | Refused by a commit hook, push hook, or a guard on a destructive command | Impossible without deliberate override |
| 4 | Fails CI | A red branch |
| 3 | Fails the per-edit gate | A failed turn |
| 2 | Ratcheted — cannot grow, existing debt allowed | Nothing today, blocked tomorrow |
| 1 | Prose only | Nothing |

**The data.** Each rule declares two fields, in the repo's rules data file or in
the guide's front matter:

```
rung:    1..5     what actually enforces it today
blast:   1..5     the minimum rung its consequences demand
```

**The check.** `rung >= blast`, for every rule. That is the whole thing.

**Assigning blast is a human judgement, once per rule.** The defaults that held
up:

- Anything touching production data, money, credentials, or one customer's
  access to another's data → 5.
- Anything that silently produces a wrong number, or wrong output a reader
  cannot eyeball → 4.
- Anything that only costs rework → 3.
- Anything cosmetic, or carrying pre-existing debt → 2.

**Why it is worth the ceremony.** It turns "is this rule real?" from a code
question into a data question, and it makes a downgrade visible. A check
disabled during an incident and never re-enabled drops a rung, and the next run
says so.

Do this one first. It costs an afternoon and it audits every rule that already
exists.

---

## B. The unused ratchet — needs an inventory and a usage signal

**Applies to:** any repository with a declared inventory whose items cost
something merely by existing.

Every ratchet in the standard harness counts *bad* things and refuses growth:
lint errors, oversized files, unverified overrides. None counts *dead* things.
This is the other direction.

**The pattern.** Two sources and a window:

```
inventory   what is declared to exist, and when each item was born
usage       a per-item count over a window
window      the grace period before absence means anything
```

An item older than the window with no usage in the window fails. The remedy is
deletion, or a recorded exemption carrying a reason and a review date. An
exemption with no date is not an exemption.

**Where it earns its keep.** Rank candidates by whether the item costs anything
while idle:

- **Costs continuously while idle → strongest case.** Agent tool definitions
  are the clearest example: every definition is read on every turn whether it is
  called or not, so a dead one is a per-turn tax that compounds with traffic. A
  feature flag branch, a scheduled job, and a published API version behave the
  same way.
- **Costs only maintenance → weaker case.** Exported components, translation
  keys, database indexes. Worth a report, not a failure.
- **Costs nothing → skip it.** Not every unused thing is debt.

**The trap that makes this backfire.** Absence of usage has two causes: nobody
wants it, or nobody can reach it. Deleting the second kind is a mistake and it
is invisible in the telemetry. So the exemption path must be cheap and the
failure message must ask which one it is.

**When the repo has no usage signal**, this degrades to an inventory report with
birth dates, which is still worth having and costs nothing to build.

---

## C. Contribution per unit — needs a price and a variable cost

**Applies to:** repositories that bill for what they serve. Skip otherwise.

**The idea.** Contribution = price − variable cost per unit served. Not total
cost, not a threshold alert. Per unit.

**What it decides**, and this is the part that is hard to get from a cost
dashboard:

| Contribution | Meaning | Action |
|---|---|---|
| Negative | Every call loses money | Do not scale it. Fix the unit first. |
| Positive, low volume | The model works, it is under-exposed | Expose it further, spend more |
| Positive, at volume | Past break-even | Defend the margin |

**The middle row is the one that is always got wrong.** A cheap-but-quiet unit
looks like an unpopular feature in every dashboard, and the instinct is to cut
it. It is the one to promote.

**The data.** One price and every variable term per unit. Whatever the runtime
already reports — invocations, database reads, inference tokens, egress —
attributed to the unit that caused them. The attribution point is wherever
metering already happens; if metering happens in more than one place, fix that
first or the number is fiction.

**Why this belongs in the harness rather than in a dashboard.** It is the only
honest answer to the cost criterion that no repository can close from the
inside. Cost lives in the runtime; contribution can be computed from what the
runtime already returns on each call, and stored next to the metering record.

**The pure case worth stating.** Anything served with zero variable cost has
contribution bounded below by zero at any volume. That is a strong argument for
keeping a compute path out of a free tier, expressed as one number rather than
as a principle.

---

## Order to add them

1. **A, the rung.** Universal, cheap, and it audits every rule already written.
2. **B, the unused ratchet**, if there is an inventory that bills while idle.
3. **C, contribution**, only once metering exists and happens in one place.

None of these belongs in the first pass on a repository. Build the gate, the
ratchets, the boundary and the guides first. These are what a harness grows
into once its rules are all enforced.
