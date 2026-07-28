# The anchor document — the build's real memory

Read this when setting up a gated build's plan sections, when deciding where a fact
belongs, or when the plan is approaching the ceiling and needs compressing.

One compressed working-memory doc **per build** — a repo has many. No single
global RESUME.md: use `rjv-work-plan`'s layout (`.plans/<branch>.md` per branch,
archived under `.plans/shipped/` after merge) so several gated builds run in
parallel, each hydrated by its branch name. The sections below live INSIDE that plan.
Conversation is disposable; the anchor doc is not. "The spec is the only artifact
that earns its tokens" (cavekit).

**Owned sections** — each phase writes only its own:

| Section | Owner | Holds |
|---|---|---|
| GOAL | human + orchestrator | one paragraph, the point, never forget |
| CONSTRAINTS / VOCAB | human | agreed words, dead words, hard limits |
| EVIDENCE LEDGER | orchestrator | live results as design constraints — refuted ideas marked "do not resurrect" |
| INVARIANTS | grill rounds | iron rules that emerged, each traceable to a round or corpse |
| DESIGN vN | spec-grill loop | current design + the grill trail (v1 → v2 → …, who objected, what was accepted on merit) |
| TASKS / PLAN | orchestrator | phases with active durable-spec criterion IDs; every idea gets a HOME or gets killed |
| BUGS / CORPSES | implementation | failures studied at the lowest level, taxonomized |
| TOMBSTONES | orchestrator | resolved questions kept visible "so nobody re-opens them" |
| OPEN | anyone | genuinely undecided items, flagged USER where the human must decide |

**Register rule — compress by audience:**

- **Agents read** (this doc, RESUME, grill prompts, memory) → caveman register:
  facts, file:line, imperatives. "register order BEFORE send (sync fill drop →
  oversell)", not prose. For a reader with no context and 10 seconds. ~75% cheaper
  per re-read, and re-reads are the recurring cost.
- **Humans read** (replies, user docs) → prose, concrete examples with numbers.
  Comprehension failures cost more than output tokens.
- Explicit split: agent notes graduate to user-facing docs only when concrete +
  agreed.

**The no-later rule.** Never file anything "later". Every idea gets a home in a
named phase (with why) or gets killed. Source build: "later" hid the single most
valuable experiment — it became the FIRST build item once surfaced. Only
acceptable deferral = a stated structural dependency.

**Compression maintenance — bounded, not "periodic".** Anchor + memory files are
re-read every resume — recurring INPUT cost, the expensive kind, and it grows
*super-linearly*: each resume re-reads the trail it just appended to. "Periodic /
on bloat" never fires because nothing defines bloat — so a live build's anchor
silently reached 2,000+ lines / 130KB (~33K tokens re-read EVERY reconcile) and
became the run's token sink. Enforce a ceiling, don't trust judgment:

- **Hard ceiling: ~400 lines / ~20KB.** Over it, compression is not optional —
  collapse BEFORE acting (it is a step in reconcile-on-open). A working doc
  re-read every turn is a few hundred lines, not thousands. 2,000+ lines means
  facts that belonged in `_docs/` never graduated — see the promotion mandate.
- **Promotion mandate — what collapses, and to where:** superseded DESIGN vN →
  one-line TOMBSTONE; closed grill rounds → `round + verdict + what-changed` (drop
  the prose transcript); durable facts (now-permanent INVARIANTS, third-party API
  behavior, established patterns) → **promote to `_docs/`**, the plan keeps only a
  link. The grill trail is the usual balloon — collapse it hardest. Truth moves to
  `_docs/`; the plan stays a thin working memory.
- **Register:** rewrite in caveman register — strip prose, keep facts. Never touch
  numbers, identifiers, file:line, code, commands, error text (byte-exact); never
  compress the EVIDENCE LEDGER's meaning — a lost nuance re-opens a refuted idea.
