---
name: rjv-codex-ollama-subagents
description: "How to run local Ollama models: as separate Codex or opencode processes with repository tools (gemma-explorer, gemma-worker), or as a one-shot text function with no tools (ollama-chat.sh). Covers install, Ollama serve tuning, the runners and their time-budget flags, prompt rules and verifying the output. When to delegate at all and which worker to pick is rjv-subagents-codex. Triggers: local Ollama, local model, gemma-explorer, gemma-worker, ollama-chat, local-codex-agent, opencode-local, one-shot local model."
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

**Which mode:** if the model must read files or edit through the harness, use (a),
a local Codex process. If you can hand it a complete self-contained prompt and it needs
nothing else from the repo, use (b), the one-shot runner. If you find yourself wishing
a (b) run could "check the other file", the job needs repo tools: route it to (a).

Mode (a) runs as separate processes because native subagents spawned by an OpenAI
parent inherit its provider in Codex 0.155.1, so those roles cannot switch to Ollama.

## Setup

When the user asks to configure this machine (install the `~/.codex-ollama` profile),
or wants to run local Gemma agents now and Ollama is not yet serving with the tuned
flags, read [`SETUP.md`](SETUP.md). It holds the installer, the `ollama serve`
flags and the expected model-load evidence.

## Recommended model routing

| Work | Agent |
|---|---|
| Planning, review, final decision | main OpenAI model |
| Bounded repository exploration | `gemma-explorer` (`gemma4:26b`) |
| Scoped edits and tests | `gemma-worker` (`gemma4:26b`) |
| Fast second check with exact supplied context | one-shot `qwen2.5-coder:14b-instruct` |

Local Ollama models save main-model tokens and context. Expect no wall-clock gain
from running several at once: Ollama queues concurrent requests.

## Time budgets

Every runner needs a time budget and refuses to start without one:

| Run | Boxes | Flag |
|---|---|---|
| One-shot text (`ollama-chat.sh`) | 5 · 10 min | `OLLAMA_CHAT_MINUTES` |
| Explorer or worker with repo tools | 10 · 20 · 30 min | `LOCAL_AGENT_MINUTES` |

How to pick the box: `rjv-subagents-codex`.

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
`LOCAL_AGENT_MINUTES`. It refuses to start below `OPENCODE_MIN_FREE_PCT` free
memory (default 25), and unloads every other model when more than
`OPENCODE_MAX_LOADED` (default 2) are resident.

## One-shot local text generation (no repo tools)

Mode (b): a single local HTTP call, `complete prompt in → local text out`. No
Codex, no subagents, no harness. **The local model types; you spec and review.**
From a tight spec a 30B-class model produces ~90% production-quality code at zero
token cost. It misses subtle bugs in its own and others' output, so you review and
test every result before it ships.

**Hard limits.** It is a one-shot text function. When a job needs any of the
following, use mode (a):

- It sees only the pasted prompt: no file reads, shell, web or filesystem.
- One prompt in, one answer out; no multi-turn self-correction.
- Its context is only what the prompt holds: the code, signature, conventions.
- It is weak at judgment and misses subtle and platform bugs. It is never the
  reviewer.

When a local draft is worth it at all, and why high-stakes drafts stay on a
cloud model: `rjv-subagents-codex`.

**How to run.** Use the bundled runner (relative to this skill dir). `ollama run`
emits TTY escape codes into stdout even when redirected, so it is the wrong tool here.

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

**Writing the prompt.** Quality is won here. The model sees only the prompt file:

1. The spec, decided by you first: algorithms, edge cases, API shapes. Ask it to
   implement your design.
2. Real code context inline: the route, function or schema it must fit, plus file
   conventions (imports, error shapes, validation style). Copy actual snippets.
3. An exact output contract: "Output ONLY the code, no markdown fences." Models
   ignore the fences rule ~50% of the time, so strip fences on receipt.
4. For tests: harness conventions verbatim (imports, seeding, how to invoke).

**Verify the output yourself, every time.**

- Run it: type-check, lint, and tests with known expected values. Reading clean
  proves nothing; a spike RFC-2047 decoder read cleanly and failed 3/9 vectors.
- Review for subtle platform bugs, the class local models miss. Example: SQLite
  `LIKE` needs an explicit `ESCAPE`, and many ORMs' `like()` don't emit one.
- Keep final review and open-ended bug-hunting on the main OpenAI model. A local
  checker may challenge exact supplied code; the main model owns the conclusion.
