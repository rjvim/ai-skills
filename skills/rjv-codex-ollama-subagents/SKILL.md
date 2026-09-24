---
name: rjv-codex-ollama-subagents
description: "How to run local Ollama models: as separate Codex or opencode processes with repository tools (gemma-explorer, gemma-worker), or as a one-shot text function with no tools (ollama-chat.sh). Covers install, Ollama serve tuning, the runners and their time-budget flags, prompt rules and verifying the output. When to delegate at all and which worker to pick is rjv-subagents. Triggers: local Ollama, local model, gemma-explorer, gemma-worker, ollama-chat, local-codex-agent, opencode-local, one-shot local model."
---

# Codex + local Ollama

Two ways to put a local Ollama model to work:

```text
(a) Separate Ollama-backed Codex processes WITH repo tools
    main OpenAI Codex = orchestrator / reviewer
    gemma-explorer = local read-only repo scout
    gemma-worker   = local scoped coding worker
(b) One-shot local text function, NO repo tools  → see the last section
    qwen2.5-coder:14b-instruct = fast checker when Codex supplies exact context
```

**Which mode:** if the model must read files or edit through the harness → (a),
a local Codex process. If you can hand it a complete self-contained prompt and it needs
nothing else from the repo → (b), the one-shot runner. The tell you picked wrong
for (b): you wish it could "check the other file" — that's a subagent job, route
it to (a).

## Install the local Codex harness

Only run the installer when the user explicitly wants this machine configured.
Do not run it just because the skill loaded.

Prereqs:

- `codex` installed
- `ollama` installed
- `gemma4:26b` and `qwen2.5-coder:14b-instruct` available in Ollama

From this skill directory:

```sh
scripts/install-codex-ollama-profile.sh
```

It writes one file, `~/.codex-ollama/config.toml`, and rewrites it on every
rerun. The launcher uses `codex exec --oss --local-provider ollama`. Each role gets
Codex filesystem and shell tools. Native subagents spawned by an OpenAI parent
inherit its provider in Codex 0.155.1, so those roles cannot switch to Ollama.

## Ollama serve for predictable local agent runs

Only do this when the user wants to run local Gemma agents now. For controlled
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
| Planning, review, final decision | main OpenAI model |
| Bounded repository exploration | `gemma-explorer` (`gemma4:26b`) |
| Scoped edits and tests | `gemma-worker` (`gemma4:26b`) |
| Fast second check with exact supplied context | one-shot `qwen2.5-coder:14b-instruct` |

Local Ollama models save main-model tokens/context. They may not improve wall-clock time
because Ollama can queue concurrent requests.

## Time budgets

Every runner needs a time budget and refuses to start without one:

| Run | Boxes | Flag |
|---|---|---|
| One-shot text (`ollama-chat.sh`) | 5 · 10 min | `OLLAMA_CHAT_MINUTES` |
| Explorer or worker with repo tools | 10 · 20 · 30 min | `LOCAL_AGENT_MINUTES` |

How to pick the box and what to do on an overrun: `rjv-subagents`.

## Repository-tool examples

Run from the repository root. These are separate Codex processes and can be
started in parallel by the main agent when memory allows.

```sh
RUNNER=~/.agents/skills/rjv-codex-ollama-subagents/scripts/local-codex-agent.sh

LOCAL_AGENT_MINUTES=10 $RUNNER gemma-explorer \
  "Read _docs/architecture/frontend.md. Return five bullets. Do not edit files."

LOCAL_AGENT_MINUTES=10 $RUNNER gemma-worker \
  "Edit only .plans/local-demo.md. Add three findings, read it back, and report changed files."
```

`scripts/opencode-local.sh <provider/model> "<brief>" [dir]` does the same
through a shared opencode server, from any host. It also takes
`LOCAL_AGENT_MINUTES`, and refuses to start when memory is low.

## One-shot local text generation (no repo tools)

Mode (b): a single local HTTP call, `complete prompt in → local text out`. No
Codex, no subagents, no harness. **The local model types; you spec and review.**
From a tight spec a 30B-class model produces ~90% production-quality code at zero
token cost — but it misses subtle bugs in its own and others' output, so every
result is reviewed and tested by you before it ships.

**Hard limits (do not design around these).** A one-shot text function, not an agent:
- **No tools. No repo.** No file reads, shell, web, filesystem — it sees ONLY the
  pasted prompt. If the job needs the repo, it's the wrong mode → use (a).
- **One-shot.** One prompt in, one answer out; no multi-turn self-correction.
- **Context must be complete in the prompt** — the code, signature, conventions.
- **Weak at judgment.** Misses subtle/platform bugs; NEVER a reviewer.

When a local draft is worth it at all, and why high-stakes drafts stay on a
cloud model: `rjv-subagents`.

**How to run.** Use the bundled runner (relative to this skill dir), never
`ollama run` — the CLI emits TTY escape codes into stdout even when redirected:

```sh
OLLAMA_CHAT_MINUTES=5 scripts/ollama-chat.sh <model> <prompt-file> <out-file> [num_ctx=16384] [keep_alive=30m]
```

It calls `localhost:11434/api/chat` (non-streaming), writes the raw response to
`<out-file>`, and prints timing (`wall / prompt tok/s / output tok/s / load`). Put
prompt files in your scratchpad. `keep_alive=30m` keeps the model resident so only
the first call within that window pays load; check with `ollama ps`.

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
- **Never delegate final review or open-ended bug-hunting.** A local checker may
  challenge exact supplied code, but the main OpenAI model owns the conclusion.
