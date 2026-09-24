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
| [`rjv-work-plan`](./skills/rjv-work-plan/SKILL.md) | Branch-scoped working memory: one committed `.plans/<branch>.md` per branch is the plan — what we're doing, where we stopped, how to resume. Deterministic resume via `git branch → plan → RESUME HERE` block (no RESUME.md — git branches are the index), reconcile-on-open, ~400-line ceiling, real-time promotion of settled facts to `_docs/`, no AI-generated signatures. Classifies `Build mode` (`simple` / `spec-driven` / `gated + spec-driven`) at creation and every reconcile, which decides whether the other two skills load. Plans are never deleted — on merge they archive to `.plans/shipped/` with a true status (`shipped → maintenance → closed`) and dates, giving a readable delivery timeline. The always-on backbone. |
| [`rjv-spec-driven`](./skills/rjv-spec-driven/SKILL.md) | The durable-truth layer on top of `rjv-work-plan` — mandatory for any branch classified `spec-driven` or `gated + spec-driven`, not a judgement call. Authors a Requirements & Acceptance-Criteria spec that drives the build and doubles as source-of-truth via per-item **test-backed status** (`Met`/`GAP`, derived from the suite by criterion ID). Owns the glossary (`CONTEXT.md`) and immutable-after-first-commit decision records (ADRs) with bundled format files, plus a two-axis (Spec + Standards) diff review and a `check_spec_coverage.py` mapping check. Steals from mattpocock/skills, stripped of issue-tracker coupling. |
| [`rjv-gated-build`](./skills/rjv-gated-build/SKILL.md) | Adversarial multi-agent construction for long, high-stakes builds — an independent reviewer grills every step to an explicit APPROVED. Role casting across models, spec-grilled-before-code, compressed anchor document (a `rjv-work-plan` plan), crash/compaction durability, model economy. Distilled from a live financial-systems build. |
| [`rjv-codex-ollama-subagents`](./skills/rjv-codex-ollama-subagents/SKILL.md) | Run local Ollama models two ways. (a) With repo tools, as separate Codex or opencode processes: `gemma-explorer` for read-only recon, `gemma-worker` for scoped edits. (b) As a one-shot text function with no tools, via the bundled `ollama-chat.sh`: draft-from-spec, tests, classify, summarize. Covers install, Ollama serve tuning, runner time-budget flags, prompt rules, a verify mandate, and spike evidence. |
| [`rjv-pr-descriptions`](./skills/rjv-pr-descriptions/SKILL.md) | Write/update GitHub PR descriptions in a tight "Current way / New way + What To Test" format — hard caps on sections and checkboxes, every test step traced to a diff hunk so nothing is invented; preserves checked checkboxes and author content on update; embeds screenshots via `rjv-github-image-upload`. |
| [`rjv-github-image-upload`](./skills/rjv-github-image-upload/SKILL.md) | Upload local images to GitHub and embed in PRs/issues/comments — canonical `user-attachments` URLs (private repos stay private), via the `gh-image` CLI extension. Full prerequisite checks + SSO/cookie troubleshooting table. |
| [`rjv-replica-screenshot`](./skills/rjv-replica-screenshot/SKILL.md) | Before/after PR visual when the real screen won't render locally (broken dev build, feature flag, unstageable state, backend-only change). Rebuild the actual component in HTML using the **real dumped server payload** strings, screenshot it, label it as payload-rendered. An honesty contract (real data only, faithful markup, explicit label) keeps it evidence, not a fabricated mockup. Pairs with `rjv-github-image-upload` + `rjv-pr-descriptions`. |
| [`rjv-agent-browser-notes`](./skills/rjv-agent-browser-notes/SKILL.md) | Field notes layered on the vendor `agent-browser` skill — the failures it doesn't name, each one paid for in a real debugging session. A liveness probe for the dead session that returns `✓ Done` while no input reaches the page (`doctor` passes anyway), the interaction ladder for Radix/shadcn triggers that ignore `.click()`, the native-setter dance for react-hook-form inputs, and the read-state mistakes that produce false bug reports. Load it alongside `agent-browser`. |
| [`rjv-jev-decisions`](./skills/rjv-jev-decisions/SKILL.md) | Hand closed-set decisions in a Claude Code or Codex session to Jev, TypeSafe's System One model, for about a second and a fraction of a cent each. Main use: pick the model tier for a delegated task (haiku/sonnet/opus, gpt-5.6-luna/terra or gpt-6-astra with effort, or local Ollama), with confidence and stakes gates applied in code. PreToolUse hooks for Claude Code and Codex fill in the model when a subagent is spawned without one, and every pick is logged for tuning. Also a keep-or-escalate check on a cheap worker's report, and a Build mode second opinion for `rjv-work-plan`. curl + jq scripts, exit 3 means fall back, never block. |
| [`rjv-subagents`](./skills/rjv-subagents/SKILL.md) | How to delegate so the big model (Opus/Fable, Astra/Sol) is spent only on judgment. It does mundane work itself only when that takes 1–2 minutes. The launcher splits the work so each piece fits, picks the cheapest capable worker (repo-tool vs text-only ladder, Jev picker), writes the brief, and picks a time-budget box per task: 5 / 10 / 15 min for cloud subagents, 2 / 5 for third-party cloud, 5–30 for local Ollama. A worker over its box is stopped and the rest re-split, never extended. Then the launcher checks what comes back itself. |
| [`rjv-monochart`](./skills/rjv-monochart/SKILL.md) | Draw a system as a terminal-native text diagram — box-drawing rails + `▼` arrows + 🟩🟦 state markers — for READMEs, comments, and chat. Topology or flow. Forces a PLAN→DRAW→VERIFY habit (no zero-shot misaligned drafts) and a house style so every diagram reads as one hand. Cheap, diffable, renders anywhere monospace does. |

## Philosophy

Skills here are evidence-backed: each one records what was actually
verified (and what failed) rather than aspirational instructions.

## Notes

- [Cost discipline for Claude Code](./docs/cost-discipline.md) — where the
  money actually goes on long sessions, and the global config setup to keep
  it down (re-applyable on a fresh machine).

## Local Ollama quick start

If this machine has Codex and Ollama, set up the local Codex home once:

```sh
skills/rjv-codex-ollama-subagents/scripts/install-codex-ollama-profile.sh
```

Run Ollama in a controlled terminal session when you want local agents:

```sh
OLLAMA_NUM_PARALLEL=2 OLLAMA_MAX_QUEUE=8 OLLAMA_CONTEXT_LENGTH=32768 OLLAMA_KEEP_ALIVE=30m ollama serve
```

Then run a local explorer or worker from the target repository, with a time
budget of 10, 20 or 30 minutes:

```sh
LOCAL_AGENT_MINUTES=10 skills/rjv-codex-ollama-subagents/scripts/local-codex-agent.sh \
  gemma-explorer "Read package.json and report its name."
```

## License

MIT
