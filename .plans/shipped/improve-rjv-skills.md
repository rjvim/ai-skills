# Plan: rjv-writing-skills, then improve every rjv skill with it
Branch: improve-rjv-skills
Build mode: simple
Status: shipped

## Goal
Add `rjv-writing-skills` (write, review, test agent instructions). Use its REVIEW.md to audit and improve all 14 existing rjv skills. Later: apply to other projects' internal skills.

## Cast
Orchestrator: claude-code @ opus-5.5 (main session) ← writes the skill, judges every diff
Author:       opus subagents, one per skill group ← edits in place, no commits
Lint:         opencode (deepseek flash) ← hedge/em-dash/negation/duplicate inventory per skill
Human gates:  commit + push; any description change; open decisions below

## Decisions
- New skill is model-invoked: must fire when editing skills in any repo.
- Sources: Pocock writing-for-agents (MIT), Emil writing-skills, Rajiv house rules (global CLAUDE.md section E, smoke-test memory).
- Negation conflict (Emil "never" vs Pocock "state positive"): positive target first; prohibition only as paired hard guardrail.

## Open Questions
- rjv-work-plan: plan file on `Build mode: simple`? Unresolved since 2026-07-28. Do not resolve in text.
- rjv-spec-driven GAP gate: user evolving it. Leave alone.

## Current State
- skills/rjv-writing-skills/{SKILL.md,REVIEW.md,TESTING.md} written, untested.
- All 14 skills edited by 5 Opus reviewers; orchestrator read every group diff. No description changed.
- New disclosed files: rjv-code-review/ROUNDS.md, rjv-codex-ollama-subagents/SETUP.md.
- Reverted: invented 25% free-memory gate on local-codex-agent.sh (only opencode-local.sh has it).
- Merged to main 2026-11-04; Codex subagents now capped at 5 running at once (user N6).

## Next Steps
>>> RESUME HERE <<<
Step: activation-test — open
Do next: in a fresh session, run TESTING.md activation test on rjv-writing-skills
Must-read first: skills/rjv-writing-skills/REVIEW.md
<<< END RESUME >>>
1. Judge each group diff; revert edits that drop facts or guardrails.
2. README table: add rjv-writing-skills row; sync rows for changed descriptions.
3. Activation smoke test for any changed description (TESTING.md).
4. Ask user: commit, push, install.

## Regression Guard
- Keep skill names, sibling file names, hook references, script behaviour.
- Keep every number, date, command, verified failure.

## Out of Scope
- Other projects' skills (next branch).
- Script code changes.

## Source of Truth
- skills/rjv-writing-skills/SKILL.md, REVIEW.md, TESTING.md
