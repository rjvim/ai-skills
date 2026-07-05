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
| [`rjv-ollama-delegate`](./skills/rjv-ollama-delegate/SKILL.md) | Delegate mechanical coding/text work to local Ollama models — the local model types, the main agent specs and reviews. Includes a clean non-TTY runner script and spike-verified guidance on what local models can and can't be trusted with. |
| [`rjv-pr-descriptions`](./skills/rjv-pr-descriptions/SKILL.md) | Write/update GitHub PR descriptions in a tight "Current way / New way + What To Test" format — preserves checked checkboxes and author content on update; embeds screenshots via `rjv-github-image-upload`. |
| [`rjv-github-image-upload`](./skills/rjv-github-image-upload/SKILL.md) | Upload local images to GitHub and embed in PRs/issues/comments — canonical `user-attachments` URLs (private repos stay private), via the `gh-image` CLI extension. Full prerequisite checks + SSO/cookie troubleshooting table. |

## Philosophy

Skills here are evidence-backed: each one records what was actually
verified (and what failed) rather than aspirational instructions.

## License

MIT
