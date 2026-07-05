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
| [`rjv-feature-workflow`](./skills/rjv-feature-workflow/SKILL.md) | Per-feature durable working memory: `.plans/<name>.md` per piece of work + `_docs/` as source of truth, roadmap contract, reconcile-on-open resume ritual, promotion before deletion. Invoke with a feature name to hydrate everything and resume. Multiple features in flight, multiple agents sharing the same files. |
| [`rjv-gated-build`](./skills/rjv-gated-build/SKILL.md) | Adversarial multi-agent construction for long, high-stakes builds — an independent reviewer grills every step to an explicit APPROVED. Role casting across models, spec-grilled-before-code, compressed anchor document (a `rjv-feature-workflow` plan), crash/compaction durability, model economy. Distilled from a live financial-systems build. |
| [`rjv-codex-ollama-subagents`](./skills/rjv-codex-ollama-subagents/SKILL.md) | Configure Codex native subagents to use local Ollama/Qwen: GPT-5.5 main orchestrator, `qwen-explorer` for cheap read-only repo exploration, `qwen-worker` for scoped local edits, hybrid profile launch, Ollama serve tuning, and mixed OpenAI-mini + local-Qwen routing. |
| [`rjv-ollama-delegate`](./skills/rjv-ollama-delegate/SKILL.md) | Legacy one-shot local Ollama runner: complete prompt in, text out, no repo tools. Keep only for raw local HTTP generation. For Codex subagents, repo reading, or scoped edits, use `rjv-codex-ollama-subagents`. |
| [`rjv-pr-descriptions`](./skills/rjv-pr-descriptions/SKILL.md) | Write/update GitHub PR descriptions in a tight "Current way / New way + What To Test" format — preserves checked checkboxes and author content on update; embeds screenshots via `rjv-github-image-upload`. |
| [`rjv-github-image-upload`](./skills/rjv-github-image-upload/SKILL.md) | Upload local images to GitHub and embed in PRs/issues/comments — canonical `user-attachments` URLs (private repos stay private), via the `gh-image` CLI extension. Full prerequisite checks + SSO/cookie troubleshooting table. |

## Philosophy

Skills here are evidence-backed: each one records what was actually
verified (and what failed) rather than aspirational instructions.

## Codex + local Qwen quick start

If this machine has Codex and Ollama, install the Codex hybrid profile and local
Qwen agents:

```sh
skills/rjv-codex-ollama-subagents/scripts/install-codex-qwen-profile.sh
```

The installer checks for `codex`, `ollama`, and expected local Qwen models. Run
it only when you want to configure the current machine. Existing files are
skipped; use `FORCE=1` to overwrite/update them:

```sh
FORCE=1 skills/rjv-codex-ollama-subagents/scripts/install-codex-qwen-profile.sh
```

Run Ollama in a controlled terminal session when you want local Qwen agents:

```sh
OLLAMA_NUM_PARALLEL=2 OLLAMA_MAX_QUEUE=8 OLLAMA_CONTEXT_LENGTH=32768 OLLAMA_KEEP_ALIVE=30m ollama serve
```

Launch Codex with the hybrid profile:

```sh
codex --profile hybrid-qwen
```

Then ask Codex to spawn `qwen-explorer` or `qwen-worker` subagents. Use
`rjv-codex-ollama-subagents` for this native-subagent workflow; use
`rjv-ollama-delegate` only for one-shot local text generation without repo tools.

## License

MIT
