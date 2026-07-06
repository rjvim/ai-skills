# Requirements & Acceptance Criteria — format

The artifact this skill produces. It is BOTH the driving-spec (written before/with
the build) AND the source of truth for what's live today (via per-section status).
Produce EXACTLY this structure. Do not invent sections, do not switch to prose
narrative, do not renumber IDs.

## Hard rules

1. **Preamble, near-verbatim.** State: this is the source of truth for how
   <component> behaves; each numbered item is an acceptance criterion backed by a
   passing test; it "passes" only when every criterion holds in code.
2. **Plain language + concrete numbers.** "up to 10MB", not "a size limit". A
   domain human must be able to read and agree to it, section by section.
3. **Group by flow/behaviour.** Each group gets a LETTER PREFIX; criteria are
   `<PREFIX><n>` (U1, U2, …). IDs are permanent handles: append-only, NEVER
   renumbered, retired ones tombstoned (`U3 — RETIRED: …`), never reused.
4. **Anatomy of a criterion (MUST).** A bold `**<ID> — <short title>.**` handle,
   then a `scenario → outcome` statement: trigger + the state that matters on the
   left, the observable result with concrete values on the right. The arrow IS the
   "then" — drop `given`/`when`/`then`/`should`/`the system`; multiple outcomes as
   `;`-clauses. Add `so that <why>` when the outcome's purpose isn't obvious, and a
   `(parenthetical)` for a boundary or exclusion. **Scale richness to subtlety:** a
   simple criterion is a bare-arrow line and can skip the title; a subtle one gets
   the title + why + caveat. It may wrap 2–3 lines — one *statement*, not literally
   one line. Compression = no Gherkin ceremony, NOT telegram brevity: a human
   co-author must read and agree to it. **That right-hand outcome IS the one
   acceptance test** — passes = met, no passing test = GAP; can't put a concrete
   observable result on the right → not a criterion yet. (Pure invariant with no
   trigger = rare exception, a flat assertion.)
5. **"What it does NOT do" is mandatory.** Name the scope boundary and who owns the
   excluded behaviour. This is where scope creep dies.
6. **Status block per group = the reconcile output, DERIVED from the suite.**
   `verified <YYYY-MM-DD>`, then `Met + tested: <ids>`, then each `GAP` on its own
   line with a one-line why. Reconcile is near-mechanical: run suite → map IDs to
   pass/fail → regenerate. Updated ONLY at reconcile, never as live scratch. The
   criteria are durable; the status is a verified snapshot.
7. **No file paths or code in criteria** — behaviour only; paths/code go stale.
8. **The ID is the join key** — the test carries it (default: in the name,
   `test_U2_rejects_oversize`; escape hatch: a tag like `@spec("U2")`), GAPs
   reference it, humans say "U2". This is what lets reconcile map suite → status.

## Template

```md
# <Component> — Requirements & Acceptance Criteria

Co-authored, reviewed section by section. Plain language, concrete numbers. This is
the source of truth for how <component> behaves. Each numbered item (<P>1, <P>2, …)
is an acceptance criterion the component must satisfy, backed by a passing test. It
"passes" only when every criterion here holds in code.

## What it is
<one paragraph, plain language — the point of this component>

## What it DOES
1. <capability>

## What it does NOT do (<who owns it>)
- <excluded behaviour> — <who's responsible instead>

---

## <Flow name> — <one line>
Example: <one concrete, numeric scenario>.

- <P>1. <scenario> → <observable outcome, concrete numbers>.        ← simple: bare arrow
- **<P>2 — <short title>.** <scenario> → <outcome> so that <why>.   ← subtle: title + why
  (<boundary / exclusion caveat>.)

<Flow> status (verified <YYYY-MM-DD>):
- Met + tested: <ids>.
- <id> (<short name>) — GAP: <what's missing / why>.
```

## Worked example (agnostic, abridged)

# File Upload — Requirements & Acceptance Criteria

Co-authored, reviewed section by section. Plain language, concrete numbers. This is
the source of truth for how upload behaves. Each numbered item (U1, U2, …) is an
acceptance criterion the component must satisfy, backed by a passing test. It
"passes" only when every criterion here holds in code.

## What it is
Accepts a file from the caller, stores it, and returns a stable handle.

## What it DOES
1. Accept an upload and store it.
2. Return a stable handle for a stored file.

## What it does NOT do (the caller's job)
- Decide who may upload — auth is the caller's gate.

---

## Upload — the happy path and its edges
Example: upload a 3MB PNG.

- U1. File ≤10MB → stored, handle returned.
- U2. File >10MB → rejected "too large"; nothing stored.
- U3. Duplicate upload (same bytes) → existing handle returned, no second copy.
- **U4 — Resume an interrupted upload.** A chunked upload drops mid-transfer and
  retries with the same upload-id → resumes from the last received chunk, not from
  zero, so a large file survives a flaky connection. (A fresh upload-id with no
  prior chunks starts at zero.)

Upload status (verified 2026-01-15):
- Met + tested: U1, U2.
- U3 (dedupe) — GAP: duplicates create a second copy; content-hash not wired yet.
- U4 (resume) — GAP: a dropped upload restarts from zero; chunk-offset not tracked.
