# Setup: install the local Codex harness and tune Ollama serve

The setup branch of [`rjv-codex-ollama-subagents`](SKILL.md). Day-to-day runs
do not need this file.

## Install the local Codex harness

Run the installer only when the user explicitly asks for this machine to be
configured. Loading the skill is not that request.

Prereqs:

- `codex` installed
- `ollama` installed
- `gemma4:26b` and `qwen2.5-coder:14b-instruct` available in Ollama

From this skill directory:

```sh
scripts/install-codex-ollama-profile.sh
```

It writes one file, `~/.codex-ollama/config.toml`, and rewrites it on every
rerun. The launcher uses `codex exec --oss --local-provider ollama`. Each role
gets Codex filesystem and shell tools.

## Ollama serve for predictable local agent runs

Do this when the user wants to run local Gemma agents now. For controlled
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

Done when the model-load log shows all three lines above.
