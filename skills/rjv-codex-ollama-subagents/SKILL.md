---
name: rjv-codex-ollama-subagents
description: "Use for any local-Ollama delegation: (a) Codex native subagents with repo tools — GPT-5.5 orchestrator, qwen/gemma explorers for read-only exploration, qwen/gemma workers for scoped edits, hybrid-ollama profile, Ollama serve tuning, mixed OpenAI-mini + local routing; and (b) one-shot local text generation (no repo tools) via the bundled ollama-chat.sh runner — draft-from-spec, tests, classify, summarize. Triggers: 'Codex local Ollama subagents', 'hybrid-ollama', 'qwen-explorer', 'gemma-explorer', 'qwen-worker', 'gemma-worker', 'ollama-chat', 'one-shot local model', 'draft from spec locally', 'save Codex tokens with local models'."
---

# Codex + local Ollama

Two ways to put a local Ollama model to work — pick by whether the job needs the repo:

```text
(a) Codex native subagents WITH repo tools  → most work; the bulk of this skill
    main Codex GPT-5.5 = orchestrator / reviewer
    qwen-explorer / gemma-explorer = local read-only repo scouts
    qwen-worker / gemma-worker     = local scoped mechanical edit workers
    optional OpenAI mini           = fast cheap explorer when latency matters

(b) One-shot local text function, NO repo tools  → see the last section
    complete prompt in → local Ollama text out (draft-from-spec, tests, classify)
```

**Which mode:** if the model must read files or edit through the harness → (a),
Codex subagents. If you can hand it a complete self-contained prompt and it needs
nothing else from the repo → (b), the one-shot runner. The tell you picked wrong
for (b): you wish it could "check the other file" — that's a subagent job, route
it to (a).

## Optional install: hybrid Codex profile

Only run the installer when the user explicitly wants this machine configured.
Do not run it just because the skill loaded.

Prereqs:

- `codex` installed
- `ollama` installed
- local models available, for example `qwen3:8b`, `qwen3.6:35b`, and `gemma4:26b`

From this skill directory:

```sh
scripts/install-codex-ollama-profile.sh
```

Reruns are safe: existing files are skipped. To update existing profile/agent
files from this skill, run:

```sh
FORCE=1 scripts/install-codex-ollama-profile.sh
```

It installs:

```text
~/.codex/hybrid-ollama.config.toml
~/.codex/agents/qwen-explorer.toml
~/.codex/agents/qwen-worker.toml
~/.codex/agents/gemma-explorer.toml
~/.codex/agents/gemma-worker.toml
```

Launch Codex with:

```sh
codex --profile hybrid-ollama
```

The installer removes the old `~/.codex/hybrid-qwen.config.toml` profile if it
exists. Local model agents now use the generic provider name `ollama-local`.

If models are named differently, edit:

```text
~/.codex/agents/qwen-explorer.toml
~/.codex/agents/qwen-worker.toml
~/.codex/agents/gemma-explorer.toml
~/.codex/agents/gemma-worker.toml
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
| Token-saving repo exploration | `qwen-explorer` (`qwen3:8b`) or `gemma-explorer` (`gemma4:26b`) |
| Scoped local mechanical edits | `qwen-worker` (`qwen3.6:35b`) or `gemma-worker` (`gemma4:26b`) |
| Speed-sensitive parallel exploration | OpenAI mini explorer |

Local Ollama models save main-model tokens/context. They may not improve wall-clock time
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

## POC: OpenAI mini + Qwen + Gemma

Use this to prove three model families can run in one Codex fan-out:

```text
Demo mixed OpenAI + Qwen + Gemma subagents.

You are main Codex on GPT-5.5.

Spawn 3 subagents in parallel:

1. Use a cheap OpenAI mini explorer, preferably gpt-5.4-mini.
Task: read _docs/architecture/frontend.md only.
Do not edit files.
Return 5 concise bullets.

2. Use qwen-explorer.
Task: read _docs/architecture/backend.md only.
Do not edit files.
Return 5 concise bullets.

3. Use gemma-explorer.
Task: read _docs/architecture/multi-tenancy.md only.
Do not edit files.
Return 5 concise bullets.

Wait for all 3 agents.

Then main agent must show:
- which agent/model/provider it selected for each task
- all summaries
- whether any files changed
- whether main GPT-5.5 avoided reading the target docs directly

Do not commit.
```

## One-shot local text generation (no repo tools)

Mode (b): a single local HTTP call, `complete prompt in → local text out`. No
Codex, no subagents, no harness. **The local model types; you spec and review.**
From a tight spec a 30B-class model produces ~90% production-quality code at zero
token cost — but it misses subtle bugs in its own and others' output, so every
result is reviewed and tested by you before it ships. In a `rjv-gated-build`, a
local model can be cast as **Author** for spec-implementable functions — never as
**Reviewer**, never the gate.

**Hard limits (do not design around these).** A one-shot text function, not an agent:
- **No tools. No repo.** No file reads, shell, web, filesystem — it sees ONLY the
  pasted prompt. If the job needs the repo, it's the wrong mode → use (a).
- **One-shot.** One prompt in, one answer out; no multi-turn self-correction.
- **Context must be complete in the prompt** — the code, signature, conventions.
- **Weak at judgment.** Misses subtle/platform bugs; NEVER a reviewer.

**When NOT to use it** (learned on a live build):
- **Below break-even, do it yourself.** Spec + runner prompt + review has fixed
  overhead; for ~a few dozen lines or fewer that exceeds the saving — the spec *is*
  the work. Delegate the big mechanical steps, not the 4-line fix.
- **Stakes raise the drafting floor.** Ordinary feature work: local draft is fine.
  Live-money / high-blast-radius: keep even the DRAFT on a cloud mid-tier (Sonnet)
  — a subtly-wrong local draft costs more in review than it saves.

**How to run.** Use the bundled runner (relative to this skill dir), never
`ollama run` — the CLI emits TTY escape codes into stdout even when redirected:

```sh
scripts/ollama-chat.sh <model> <prompt-file> <out-file> [num_ctx=16384] [keep_alive=2h]
```

It calls `localhost:11434/api/chat` (non-streaming), writes the raw response to
`<out-file>`, and prints timing (`wall / prompt tok/s / output tok/s / load`). Put
prompt files in your scratchpad. `keep_alive=2h` keeps the model resident so only
the first call pays load; check with `ollama ps`.

**Model choice** (`ollama list` to see what's installed):

| Class | Use for |
|---|---|
| Largest available (30B+) | code from spec, test-writing, harder extraction |
| Small/fast (7–9B) | classification, summaries, quick extraction |
| Coder variants | small code transforms |

**Writing the prompt (where quality is won).** The model sees ONLY the prompt file:
1. **The spec, decided by YOU first** — algorithms, edge cases, API shapes. Ask it
   to implement your design, not to design.
2. **Real code context inline** — the route/function/schema it must fit + file
   conventions (imports, error shapes, validation style). Copy actual snippets.
3. **Exact output contract** — "Output ONLY the code, no markdown fences." (Models
   ignore the fences rule ~50% of the time — strip fences on receipt.)
4. For tests: harness conventions verbatim (imports, seeding, how to invoke).

**Non-negotiable: verify the output yourself.**
- **Run it** — type-check, lint, tests with known expected values. "Looks right"
  is not evidence (a spike RFC-2047 decoder read cleanly, failed 3/9 vectors).
- **Review for subtle platform bugs** — the class local models miss (e.g. SQLite
  `LIKE` needs an explicit `ESCAPE`; many ORMs' `like()` don't emit one).
- **Never delegate review or bug-hunting** — asked to find a real bug in shipped
  code, the spike model said "no bugs".
- Note provenance in commits: "drafted by <model>, reviewed + hardened".

**Evidence (spike, 2026-07-05, qwen3.6:35b on Apple Silicon):** ~60 tok/s gen,
~1000 tok/s prompt, ~5s load.

| Task | Result |
|---|---|
| RFC 2047 decoder from spec | 6/9 vectors — Q-decoding dropped literal chars |
| Bug-hunt on real shipped code | FAILED — "no bugs" on a real bug |
| Keyset-pagination API route from spec | ~90% in 21s; added an id tiebreaker unprompted; one LIKE-escape bug caught in review |
| Test suite for that route | 7/7 passed first run (lint nits only) |
