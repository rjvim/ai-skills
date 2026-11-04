# The anchor document: the build's real memory

Read this when setting up a gated build's plan sections, when deciding where a fact
belongs, or when the plan is approaching the ceiling and needs compressing.

One compressed working-memory doc **per build**, and a repo has many. Use
`rjv-work-plan`'s layout (`.plans/<branch>.md` per branch, archived under
`.plans/shipped/` after merge) so several gated builds run in parallel, each
hydrated by its branch name. The sections below live INSIDE that plan.
Conversation is disposable; the anchor doc is not. "The spec is the only artifact
that earns its tokens" (cavekit).

**Owned sections.** Each phase writes only its own:

| Section | Owner | Holds |
|---|---|---|
| GOAL | human + orchestrator | one paragraph, the point, never forget |
| CONSTRAINTS / VOCAB | human | agreed words, dead words, hard limits |
| EVIDENCE LEDGER | orchestrator | live results as design constraints; refuted ideas marked "do not resurrect" |
| INVARIANTS | grill rounds | iron rules that emerged, each traceable to a round or corpse |
| DESIGN vN | spec-grill loop | current design + the grill trail (v1 → v2 → …, who objected, what was accepted on merit) |
| TASKS / PLAN | orchestrator | phases with active durable-spec criterion IDs; every idea gets a HOME or gets killed |
| BUGS / CORPSES | implementation | failures studied at the lowest level, taxonomized |
| TOMBSTONES | orchestrator | resolved questions kept visible "so nobody re-opens them" |
| OPEN | anyone | genuinely undecided items, flagged USER where the human must decide |

**Register rule: compress by audience.**

- **Agents read** (this doc, RESUME, grill prompts, memory) → caveman register:
  facts, file:line, imperatives, e.g. "register order BEFORE send (sync fill drop →
  oversell)". Write for a reader with no context and 10 seconds. ~75% cheaper
  per re-read, and re-reads are the recurring cost.
- **Humans read** (replies, user docs) → prose, concrete examples with numbers.
  Comprehension failures cost more than output tokens.
- Explicit split: agent notes graduate to user-facing docs only when concrete +
  agreed.

**The no-later rule.** Every idea gets a home in a named phase (with why) or gets
killed; "later" is not a home. Source build: "later" hid the single most
valuable experiment; it became the FIRST build item once surfaced. The only
acceptable deferral is a stated structural dependency.

**Compression maintenance: bounded by a number.** Anchor and memory files are
re-read every resume. That is recurring INPUT cost, the expensive kind, and it
grows *super-linearly*: each resume re-reads the trail it just appended to. A
"periodic / on bloat" rule never fires because nothing defines bloat. A live
build's anchor silently reached 2,000+ lines / 130KB (~33K tokens re-read EVERY
reconcile) and became the run's token sink. Enforce the ceiling:

- **Hard ceiling: ~400 lines / ~20KB**, the plan ceiling owned by
  `rjv-work-plan`. Over it, collapse BEFORE acting (it is a step in
  reconcile-on-open). 2,000+ lines means facts that belonged in `_docs/` never
  graduated; apply the promotion mandate.
- **Promotion mandate: what collapses, and to where.** superseded DESIGN vN →
  one-line TOMBSTONE; closed grill rounds → `round + verdict + what-changed` (drop
  the prose transcript); durable facts (now-permanent INVARIANTS, third-party API
  behavior, established patterns) → **promote to `_docs/`**, the plan keeps only a
  link. The grill trail grows fastest; collapse it hardest. Truth moves to
  `_docs/`; the plan stays a thin working memory.
- **Register:** rewrite in caveman register: strip prose, keep facts. Keep
  numbers, identifiers, file:line, code, commands and error text byte-exact.
  Keep the EVIDENCE LEDGER's full meaning, because a lost nuance re-opens a
  refuted idea.
