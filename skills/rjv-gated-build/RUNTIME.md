# Runtime — surviving drops, and driving a Codex reviewer

Read this when starting a long or overnight run, after a compaction/drop/wake, or
when a grill hangs. The three-line summary is in `SKILL.md`; this is the full drill.

## Staying alive — the run must survive drops

Two failure modes WILL hit a long run: the reviewer hangs, and your own connection
drops mid-response. Same defense: **never hold state only in the live conversation.**

- **Resume pointer + reconcile-on-open.** Rewrite the anchor doc's
  `>>> RESUME HERE <<<` block at the END of every step: current step + status,
  exact next action, must-read files, hard rules. Every resume
  (post-compaction/drop/wake) → FIRST run the `rjv-work-plan` reconcile:
  read plan → **VERIFY each "done" against real code/db** → note drift → rewrite
  Next Steps → stamp Last reconciled → **if over the `ANCHOR-DOC.md` ceiling,
  compress before acting** → act. Never trust a stale checkbox; a drop may have lost
  the edit it claims.
- **Commit early and often.** Each approved step commits immediately. A drop then
  loses at most the in-flight edit, not a night's work.
- **Schedule your own wakeups.** Handing off to a bounded grill → schedule a
  self-wake (~15 min) to ACTIVELY return; passive "job re-invokes me" watches can
  die silently.
- **Idempotent steps.** You may re-enter mid-step after a drop — make side effects
  replay-safe (dedup keys, upserts, already-done checks).

## Appendix — reviewer = OpenAI Codex CLI

- **Cancel-first, never reattach.** Grill timeout → do NOT "reattach to preserve
  its work" (the reattach can die silently, orphan runs for hours). Cancel →
  verify none running → relaunch `--fresh`.
- **pkill orphans.** Cancelled/hung jobs leave `codex app-server`, `codex resume`,
  `app-server-broker`; `pkill -9 -f` them so they don't pile up.
- **Its sandbox can't run your tests** (no writable temp dir; hangs "verifying") —
  WHY the you-run-the-tests rule exists. Reading files (grep/sed/cat) in its
  sandbox is fine.
- **Writes files but can't run git** — commit from the orchestrator after it finishes.
- Session/thread ids are resumable (`--resume-last` / by id) for follow-up grills
  needing prior context — subject to cancel-first.
