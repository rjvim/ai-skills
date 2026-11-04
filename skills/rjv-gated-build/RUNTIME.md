# Runtime: surviving drops, and driving a Codex reviewer

Read this when starting a long or overnight run, after a compaction/drop/wake, or
when a grill hangs. `SKILL.md` §6 has the summary; this is the full drill.

## Staying alive: the run must survive drops

Two failure modes WILL hit a long run: the reviewer hangs, and your own connection
drops mid-response. Same defense: **keep all state on disk.**

- **Resume pointer + reconcile-on-open.** Rewrite the anchor doc's
  `>>> RESUME HERE <<<` block (format in `rjv-work-plan`) at the END of every
  step, adding the hard rules for the step. Every resume (post-compaction, drop or
  wake) FIRST runs `rjv-work-plan`'s reconcile-on-open: **VERIFY each "done"
  against real code/db**, and compress if over the ceiling, before acting. A drop
  may have lost the edit a checkbox claims.
- **Commit each approved step immediately.** A drop then loses at most the
  in-flight edit.
- **Schedule your own wakeups.** Handing off to a bounded grill → schedule a
  self-wake (~15 min) to ACTIVELY return; passive "job re-invokes me" watches can
  die silently.
- **Idempotent steps.** You may re-enter mid-step after a drop, so make side effects
  replay-safe (dedup keys, upserts, already-done checks).

## Appendix: reviewer = OpenAI Codex CLI

- **Cancel-first.** Grill timeout → cancel → verify none running → relaunch
  `--fresh`. Do NOT "reattach to preserve its work": the reattach can die
  silently and orphan runs for hours.
- **pkill orphans.** Cancelled/hung jobs leave `codex app-server`, `codex resume`,
  `app-server-broker`; `pkill -9 -f` them so they don't pile up.
- **Its sandbox can't run your tests** (no writable temp dir; hangs "verifying").
  This is why the you-run-the-tests rule exists. Reading files (grep/sed/cat) in its
  sandbox is fine.
- **Writes files but can't run git.** Commit from the orchestrator after it finishes.
- Session/thread ids are resumable (`--resume-last` / by id) for follow-up grills
  needing prior context, subject to cancel-first.
