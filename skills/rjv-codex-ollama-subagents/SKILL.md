---
name: rjv-codex-ollama-subagents
description: "Use when configuring or using Codex native subagents with local Ollama/Qwen models — GPT-5.5 as orchestrator, qwen-explorer for read-only repo exploration, qwen-worker for scoped edits, hybrid profile launch, Ollama serve tuning, and mixed OpenAI-mini + local-Qwen routing. Triggers: 'Codex local Qwen subagents', 'hybrid-qwen', 'qwen-explorer', 'qwen-worker', 'save Codex tokens with Qwen'."
---

# Codex + local Ollama subagents

Use this when the goal is **Codex native subagents with repo tools**, not a
one-shot Ollama text call.

Pattern:

```text
main Codex GPT-5.5 = orchestrator / reviewer
qwen-explorer = local Qwen read-only repo scout
qwen-worker = local Qwen scoped mechanical edit worker
optional OpenAI mini = fast cheap explorer when latency matters
```

## Do not confuse with rjv-ollama-delegate

`rjv-ollama-delegate` is still useful for one-shot local text/code generation
from a complete prompt. It has no repo tools.

Use this skill when Qwen must be a **Codex subagent** that can read files or edit
through the Codex harness.

If the agent says it will use `rjv-ollama-delegate`, correct it:

```text
Do not use rjv-ollama-delegate.
Use Codex native subagents only.
Use qwen-explorer / qwen-worker from ~/.codex/agents.
```

## Optional install: hybrid Codex profile

Only run the installer when the user explicitly wants this machine configured.
Do not run it just because the skill loaded.

Prereqs:

- `codex` installed
- `ollama` installed
- local models available, usually `qwen3:8b` and `qwen3.6:35b`

From this skill directory:

```sh
scripts/install-codex-qwen-profile.sh
```

Reruns are safe: existing files are skipped. To update existing profile/agent
files from this skill, run:

```sh
FORCE=1 scripts/install-codex-qwen-profile.sh
```

It installs:

```text
~/.codex/hybrid-qwen.config.toml
~/.codex/agents/qwen-explorer.toml
~/.codex/agents/qwen-worker.toml
```

Launch Codex with:

```sh
codex --profile hybrid-qwen
```

If models are named differently, edit:

```text
~/.codex/agents/qwen-explorer.toml
~/.codex/agents/qwen-worker.toml
```

## Ollama serve for predictable local agent runs

Only do this when the user wants to run local Qwen agents now. For controlled
sessions, quit the Ollama macOS app and run Ollama from a terminal:

```sh
OLLAMA_NUM_PARALLEL=2 \
OLLAMA_MAX_QUEUE=8 \
OLLAMA_CONTEXT_LENGTH=32768 \
OLLAMA_KEEP_ALIVE=30m \
ollama serve
```

Expected model-load evidence:

```text
Parallel:2
KvSize:65536
offloaded ... layers to GPU
```

`KvSize:65536` is normal: `32768` context times `2` parallel slots.

## Recommended model routing

| Work | Agent |
|---|---|
| Planning, review, final decision | main GPT-5.5 |
| Token-saving repo exploration | `qwen-explorer` (`qwen3:8b`) |
| Scoped local mechanical edits | `qwen-worker` (`qwen3.6:35b`) |
| Speed-sensitive parallel exploration | OpenAI mini explorer |

Local Qwen saves main-model tokens/context. It may not improve wall-clock time
because Ollama can queue concurrent requests.

## POC: Qwen-only exploration

Use this to prove GPT-5.5 does not read the target docs:

```text
POC: Qwen saves Codex tokens for exploration.

You are main Codex on GPT-5.5.

Spawn 3 qwen-explorer subagents in parallel. They must use local Qwen, not OpenAI models.

Tasks:
1. Explorer A: inspect _docs/architecture/frontend.md only. Return 5 bullets.
2. Explorer B: inspect _docs/architecture/backend.md only. Return 5 bullets.
3. Explorer C: inspect _docs/architecture/multi-tenancy.md only. Return 5 bullets.

Do not edit files.
Wait for all 3 agents.

Then main agent must report:
- agent/model/provider selected for each
- summaries
- whether any OpenAI subagent was used
- whether this saved main GPT-5.5 context/tokens by keeping doc reading off the main thread

Do not commit.
```

Expected:

```text
3 qwen-explorer agents
local qwen3:8b
no file edits
main GPT-5.5 only receives summaries
```

## POC: mixed OpenAI mini + local Qwen

Use this when proving OpenAI and Qwen agents can run in one fan-out:

```text
Demo mixed subagents.

You are main Codex on GPT-5.5.

Spawn 2 subagents in parallel:

1. Use a cheap OpenAI mini explorer, preferably gpt-5.4-mini.
Task: read _docs/architecture/multi-tenancy.md only.
Do not edit files.
Return 5 concise bullets about tenant-safety rules.

2. Use qwen-worker.
Task: edit only .plans/codex-mixed-qwen-demo.md.
Create it if missing.
Add a "Mixed Worker Result" section with 3 bullets.

Wait for both agents.

Then main agent must show:
- which agent/model/provider it selected for each task
- explorer summary
- changed files
- verification commands run

Do not commit.
Do not edit any files except .plans/codex-mixed-qwen-demo.md.
```

Clean up demo files after POCs.
