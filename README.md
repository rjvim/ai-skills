# ai-skills

Agent skills following the open [Agent Skills](https://agentskills.io)
standard (`SKILL.md`) — usable with Claude Code, OpenAI Codex, Cursor,
and any agent that reads the format.

## Install

With the [skills CLI](https://skills.sh) — pick your agents:

```sh
# Claude Code + Codex, globally
npx skills@latest add rjvim/ai-skills -g -a claude-code -a codex

# or interactively (detects installed agents)
npx skills@latest add rjvim/ai-skills
```

Or as a Claude Code plugin:

```
/plugin marketplace add rjvim/ai-skills
/plugin install ai-skills@ai-skills
```

Or manually: copy `skills/<name>/` into `~/.claude/skills/` (Claude
Code), `~/.codex/skills/` (Codex), or your agent's skills directory.

## Skills

| Skill | What it does |
|---|---|
| [`rjv-work-plan`](./skills/rjv-work-plan/SKILL.md) | Branch-scoped working memory: one committed `.plans/<branch>.md` per branch is the plan — what we're doing, where we stopped, how to resume. Deterministic resume via `git branch → plan → RESUME HERE` block (no RESUME.md — git branches are the index), reconcile-on-open, ~400-line ceiling, real-time promotion of settled facts to `_docs/`, plan deleted before merge. The always-on backbone. |
| [`rjv-spec-driven`](./skills/rjv-spec-driven/SKILL.md) | The proportional durable-truth layer on top of `rjv-work-plan`. Authors a Requirements & Acceptance-Criteria spec that drives the build and doubles as source-of-truth via per-item **test-backed status** (`Met`/`GAP`, derived from the suite by criterion ID). Owns the glossary (`CONTEXT.md`) and decision records (ADRs) with bundled format files, plus a two-axis (Spec + Standards) diff review. Steals from mattpocock/skills, stripped of issue-tracker coupling. |
| [`rjv-gated-build`](./skills/rjv-gated-build/SKILL.md) | Adversarial multi-agent construction for long, high-stakes builds — an independent reviewer grills every step to an explicit APPROVED. Role casting across models, spec-grilled-before-code, compressed anchor document (a `rjv-work-plan` plan), crash/compaction durability, model economy. Distilled from a live financial-systems build. |
| [`rjv-codex-ollama-subagents`](./skills/rjv-codex-ollama-subagents/SKILL.md) | Put local Ollama models to work two ways: (a) Codex native subagents with repo tools — GPT-5.5 orchestrator, Qwen/Gemma explorers for cheap read-only exploration, Qwen/Gemma workers for scoped edits, `hybrid-ollama` profile, Ollama serve tuning, mixed OpenAI-mini + local routing; and (b) one-shot local text generation with no repo tools via the bundled `ollama-chat.sh` runner — draft-from-spec, test-writing, classify, summarize, with prompt rules, a verify mandate, and spike evidence. |
| [`rjv-pr-descriptions`](./skills/rjv-pr-descriptions/SKILL.md) | Write/update GitHub PR descriptions in a tight "Current way / New way + What To Test" format — preserves checked checkboxes and author content on update; embeds screenshots via `rjv-github-image-upload`. |
| [`rjv-github-image-upload`](./skills/rjv-github-image-upload/SKILL.md) | Upload local images to GitHub and embed in PRs/issues/comments — canonical `user-attachments` URLs (private repos stay private), via the `gh-image` CLI extension. Full prerequisite checks + SSO/cookie troubleshooting table. |

## Philosophy

Skills here are evidence-backed: each one records what was actually
verified (and what failed) rather than aspirational instructions.

## Codex + local Ollama quick start

If this machine has Codex and Ollama, install the Codex hybrid profile and local
Ollama agents:

```sh
skills/rjv-codex-ollama-subagents/scripts/install-codex-ollama-profile.sh
```

The installer checks for `codex`, `ollama`, and expected local models. Run
it only when you want to configure the current machine. Existing files are
skipped; use `FORCE=1` to overwrite/update them:

```sh
FORCE=1 skills/rjv-codex-ollama-subagents/scripts/install-codex-ollama-profile.sh
```

Run Ollama in a controlled terminal session when you want local agents:

```sh
OLLAMA_NUM_PARALLEL=2 OLLAMA_MAX_QUEUE=8 OLLAMA_CONTEXT_LENGTH=32768 OLLAMA_KEEP_ALIVE=30m ollama serve
```

Launch Codex with the hybrid profile:

```sh
codex --profile hybrid-ollama
```

Then ask Codex to spawn `qwen-explorer`, `gemma-explorer`, `qwen-worker`, or
`gemma-worker` subagents. `rjv-codex-ollama-subagents` covers both this
native-subagent workflow and one-shot local text generation without repo tools
(the bundled `ollama-chat.sh` runner).

## License

MIT
