---
name: rjv-gated-build
description: >
  Use for long, high-stakes, multi-step builds (financial systems, money
  paths, prod infrastructure) where an INDEPENDENT reviewer agent must
  grill and approve each step before it ships — Claude+Codex,
  Codex+Claude, or any author/reviewer pair. Covers the gated loop, the
  anchor document (compressed working memory that survives context loss),
  resume/crash durability, role casting across multiple models, and model
  economy. Trigger phrases: "gated build", "grill each step", "adversarial
  review loop", "long autonomous build", "overnight run", "high-stakes
  build".
---

# Gated build — adversarial multi-agent construction

For work where being *plausibly wrong* is expensive. One agent — however
disciplined — cannot reliably catch its own errors: the blind spot that
produced the bug reviews the bug. Quality comes from **independence**: a
second agent whose job is to say NO-AGREE, grilling every step until it
earns an explicit APPROVED.

The economics: compress everything agents read (specs, notes, grill
prompts), so you can afford a second agent to disagree. Efficiency funds
redundancy.

## 1. Casting the roles

Three roles: **Orchestrator** (holds the anchor doc, casts the others,
integrates), **Author** (drafts code/design), **Reviewer** (grills to
APPROVED). Cast by task, not by habit:

| Author | Reviewer | When |
|---|---|---|
| Frontier agent (full repo context) | Cross-vendor frontier agent | Design-heavy, high-stakes builds — the core pattern |
| External CLI agent (e.g. Codex) | Orchestrator itself | Mechanical bulk typing; orchestrator has the context + judgment |
| Local model (Ollama-class) | Orchestrator | Zero-cost function-level drafting from a tight spec |
| Cheap-tier subagent | Flagship-tier | Intra-family economy: cheap hands, expensive judge |

**Execution bindings** — each cast needs a concrete transport in your
harness; use what exists rather than inventing plumbing:

- Local-model Author → the `rjv-ollama-delegate` skill (bundled runner,
  prompt-writing rules, verification mandate).
- External CLI Author/Reviewer (Codex-class) → its agent plugin or a
  thin Bash forwarder subagent (e.g. the Codex rescue subagent in
  Claude Code) — one call in, stdout back, cheapest possible model on
  the forwarder itself.
- Intra-family cheap Author → subagent spawn with the model set
  explicitly (see §7).

**Record the cast in the plan.** Casting happens ONCE, at build start,
and is written to the anchor plan's `## Cast` section (see
`rjv-feature-workflow`): orchestrator, author, reviewer, subagent tiers,
human gates — with models named explicitly. Every resume reads the Cast
and plays its role; the gated loop never re-negotiates who approves.
Recasting is a logged Decision with a why.

**Two hard casting rules** (evidence-backed, do not bend):

1. **The reviewer must be at least as strong as the author.** Reviewer
   strength is where quality comes from; author strength is just typing
   speed. A weak model reviews nothing — tested: asked to find a real bug
   in shipped code, a 35B local model said "no bugs".
2. **Prefer cross-vendor for the grill.** Different model families miss
   different failure modes; same-family review inherits the author's
   blind spots.

**The human is also a reviewer.** In a real run, the user caught a hole
(broker latency) that BOTH frontier models had missed through four grill
rounds. Surface designs to the human at phase boundaries; their domain
experience outranks model priors — when their live evidence contradicts
your design, the design updates immediately and says so.

## 2. Grill the SPEC before any code

The highest-leverage grill happens before implementation. In the source
project, the reviewer's round-1 verdict on the *design* was "not
buildable as written" — 10 ranked attack scenarios, 8 valid. Fixing them
pre-code cost a rewrite of a document; post-code it would have cost the
build.

- Send the spec/design to the reviewer with: "ATTACK this design. List
  ranked failure scenarios. Verdict: AGREE / NO-AGREE with blockers."
- Iterate spec → attack → amend until AGREE. Record each round in the
  anchor doc (v1 → v2 → v2.1 …), noting which objections were accepted
  *on merit* and which were rejected with reasons.
- A reviewer that never says NO-AGREE is not reviewing. If every round
  approves instantly, sharpen the prompt (see §4) or recast.

## 3. The gated loop (per implementation step)

```
spec checkpoint → implement → self-review + smoke → REVIEWER GRILL → fix → re-grill … → APPROVED → commit → next
```

- **Spec first.** Write the step's acceptance criteria to the anchor doc
  BEFORE coding it. Grading yourself against a spec invented mid-code is
  how bugs get blessed.
- **Self-review + throwaway smoke test** before handing over — catch the
  dumb bugs cheaply so the reviewer's rounds go to the subtle ones.
- **Grill until an explicit APPROVED.** One round-trip is not review.
- **Park, never rubber-stamp.** Cap grill rounds per step (~6). Still
  blocked → write the open blockers into the anchor doc and STOP that
  step. A deliberate "parked, here's why" beats a faked approval —
  non-negotiable when money or safety is at stake.
- **Living plan / reach-backs.** When a grill invalidates an EARLIER
  approved step: reopen it, fix, re-test, re-grill, LOG the reach-back.
  A locked-in wrong step is worse than a reopened one.

## 4. Driving the reviewer — prompt rules

- **REVIEW ONLY.** First line: "REVIEW ONLY — do not modify files, do
  not implement." The reviewer reads, reasons, votes.
- **You run the tests, not the reviewer.** Reviewer sandboxes hang on
  execution. Run the suite yourself, paste results into the prompt
  ("suite already run: N passed — review by reading the code"). Reading
  files is fine; executing is not.
- **Name the failure modes.** Point at exact files, the spec section,
  and a numbered hunt-list. For money code: double-exposure, oversell,
  lost/duplicated intent across restart, ordering races, idempotency,
  fees/precision, the specific risky path just written. Vague prompts
  get vague reviews.
- **Bound every grill; cancel-first on timeout.** Background it with a
  wall-clock cap (~12–15 min). On timeout: cancel the job FIRST, verify
  nothing running, relaunch fresh. Kill orphan processes. Cap relaunches
  (~3); persistent no-verdict = tooling failure → park, don't fake.

## 5. The anchor document (the build's real memory)

One compressed working-memory doc **per build** — and a repo has many
builds. Don't keep a single global RESUME.md: use the `rjv-feature-workflow`
skill's layout (`.plans/<name>.md` per piece of work, linked from the
feature's roadmap), so several gated builds can be in flight and each is
hydrated by name. The sections below live INSIDE that plan file. The
conversation is disposable; the anchor doc is not. "The spec is the only
artifact that earns its tokens" (cavekit).

**Owned sections** — each loop phase writes only its own:

| Section | Owner | Holds |
|---|---|---|
| GOAL | human + orchestrator | one paragraph, the point, never forget |
| CONSTRAINTS / VOCAB | human | agreed words, dead words, hard limits |
| EVIDENCE LEDGER | orchestrator | live results as design constraints — refuted ideas marked "do not resurrect" |
| INVARIANTS | grill rounds | iron rules that emerged, each traceable to a round or corpse |
| DESIGN vN | spec-grill loop | current design + the grill trail (v1 → v2 → …, who objected, what was accepted on merit) |
| TASKS / PLAN | orchestrator | phases with acceptance criteria; every idea gets a HOME or gets killed |
| BUGS / CORPSES | implementation | failures studied at the lowest level, taxonomized |
| TOMBSTONES | orchestrator | resolved questions kept visible "so nobody re-opens them" |
| OPEN | anyone | genuinely undecided items, flagged USER where the human must decide |

**Register rule — compress by audience:**

- Everything **agents read** (this doc, RESUME, grill prompts, memory):
  caveman register. Facts, file:line, imperatives. "register order
  BEFORE send (sync fill drop → oversell)" — not prose. Written for a
  reader with no context and 10 seconds. ~75% cheaper on every re-read,
  and re-reads are the recurring cost.
- Everything **humans read** (replies, user-facing docs): normal prose,
  concrete examples with numbers. Comprehension failures cost more than
  output tokens.
- Two-audience split is explicit: agent notes graduate to user-facing
  docs only when concrete + agreed.

**The no-later rule.** Never file anything as "later". Every idea gets a
home in a named phase (with why there) or gets killed. In the source
project, "later" hid the single most valuable experiment — it became the
FIRST build item once surfaced. Only acceptable deferral = a real
structural dependency, stated.

**Compression maintenance.** The anchor doc and memory files are re-read
on every resume — they are recurring INPUT cost, the expensive kind.
Periodically (end of a phase, or when the doc bloats) rewrite them in
the register: strip prose, keep facts. Compression rules: never touch
numbers, identifiers, file:line refs, code, commands, or error text
(byte-exact); never compress the EVIDENCE LEDGER's meaning — a lost
nuance there re-opens a refuted idea. Superseded design sections shrink
to one-line tombstones; the grill trail keeps only round + verdict +
what changed.

## 6. Staying alive — the run must survive drops

Two failure modes WILL happen on a long run: the reviewer hangs, and
your own connection drops mid-response. Defense is the same: **never
hold state only in the live conversation.**

- **Resume pointer + reconcile-on-open.** The anchor doc's Next Steps
  section is rewritten at the END of every step: current step + status,
  exact next action, must-read files, hard rules. On every resume —
  post-compaction, post-drop, scheduled wake — FIRST act is the
  `rjv-feature-workflow` reconcile ritual: read the plan → **VERIFY each
  "done" claim against real code/db** → note drift → rewrite Next Steps
  → stamp Last reconciled → then act. Never trust a stale checkbox; a
  drop may have lost the edit that a checkbox claims.
- **Commit early and often.** Every approved step commits immediately. A
  drop then loses at most the in-flight edit, not a night's work.
- **Schedule your own wakeups.** When handing off to a bounded grill,
  schedule a self-wake (~15 min) so you ACTIVELY return — passive
  "job will re-invoke me" watches can die silently.
- **Idempotent steps.** You may re-enter mid-step after a drop; make
  side effects safe to replay (dedup keys, upserts, already-done checks).

## 7. Model economy — don't burn the flagship on everything

Long runs stall on budget/rate limits before they stall on difficulty.
Completion depends on frugality:

- **Default cheap.** Small/fast model for mechanical subagents (the
  reviewer FORWARDER is one bash call — go cheapest; the grill's quality
  is the REVIEWER's model, not the forwarder's). Mid-tier for routine
  code and analysis.
- **Local models for spec-implementable functions** — zero cost, and
  from a tight spec they hit ~90% production quality. Never as
  reviewers (hard rule 1). See the `rjv-ollama-delegate` skill.
- **Reserve the flagship** for design, synthesis, final judgment, and
  the grill itself.
- Set the model EXPLICITLY per subagent — never default-inherit the
  expensive parent.

## 8. Scope honesty — especially for financial systems

State plainly what "done" means. "Reviewer-APPROVED through step N" ≠
"validated against the real world" if the run only exercised a
simulator/paper path. Keep dangerous gates — live trading, prod deploys,
destructive ops — **physically off** until a separate, explicit
validation phase with its own gate (paper-parity, fill-ratio bands,
fail-closed thresholds). Never let "approved" read as "safe to ship."

## Appendix — when the reviewer is OpenAI Codex CLI

Hard-won operational specifics for driving Codex as the grill:

- **Cancel-first, never reattach.** On a grill timeout, do NOT "reattach
  to preserve its work" — the reattach can die instantly and silently,
  leaving you with no watch while the orphaned job runs for hours.
  Always: cancel the job → verify none running → relaunch `--fresh`.
- **pkill the orphans.** Cancelled/hung jobs leave `codex app-server`,
  `codex resume`, and `app-server-broker` processes behind; `pkill -9
  -f` them during cleanup so they don't pile up across a long run.
- **Its sandbox can't run your tests** (often no writable temp dir; it
  hangs "verifying" forever) — this is WHY §4's you-run-the-tests rule
  exists. Reading files (grep/sed/cat) inside its sandbox is fine.
- **It can write files but not run git** — commit from the orchestrator
  session after it finishes.
- Session/thread ids from its output are resumable (`--resume-last` /
  resume by id) — useful for follow-up grills that need the prior
  round's context, subject to the cancel-first rule above.

---

**One-line invariant:** independent reviewer + compressed on-disk state
+ scheduled self-wakes = a run that converges to correct and survives
every hang, drop, and compaction along the way.

*Provenance: distilled from a live high-stakes build (options trading
bot, 2026-07: 6+ grill rounds, real NO-AGREEs, a human-caught design
hole, losses studied at tick level) and a verified local-model
delegation spike. Register + spec-section ideas credited to the
caveman/cavekit family (github.com/juliusbrussee).*
