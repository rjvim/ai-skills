#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SKILL_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    return 1
  fi
}

need_cmd codex
need_cmd ollama

if OLLAMA_MODELS_LIST=$(ollama list 2>/dev/null); then
  if ! printf '%s\n' "$OLLAMA_MODELS_LIST" | grep -q 'qwen3:8b'; then
    echo "warning: qwen3:8b not found in ollama list; edit qwen-explorer.toml after install." >&2
  fi

  if ! printf '%s\n' "$OLLAMA_MODELS_LIST" | grep -q 'qwen3.6:35b'; then
    echo "warning: qwen3.6:35b not found in ollama list; edit qwen-worker.toml after install." >&2
  fi

  if ! printf '%s\n' "$OLLAMA_MODELS_LIST" | grep -q 'gemma4:26b'; then
    echo "warning: gemma4:26b not found in ollama list; edit gemma-*.toml after install." >&2
  fi
else
  echo "warning: ollama is installed but not responding; install will continue." >&2
  echo "warning: before running local agents, start Ollama with: ollama serve" >&2
fi

mkdir -p "$CODEX_HOME/agents"

if [ -e "$CODEX_HOME/hybrid-qwen.config.toml" ]; then
  rm "$CODEX_HOME/hybrid-qwen.config.toml"
  echo "removed legacy: $CODEX_HOME/hybrid-qwen.config.toml"
fi

copy_file() {
  src="$1"
  dst="$2"

  if [ -e "$dst" ] && [ "${FORCE:-0}" != "1" ]; then
    echo "skip existing: $dst"
    echo "  set FORCE=1 to overwrite"
    return
  fi

  cp "$src" "$dst"
  echo "installed: $dst"
}

copy_file "$SKILL_DIR/assets/codex/hybrid-ollama.config.toml" "$CODEX_HOME/hybrid-ollama.config.toml"
copy_file "$SKILL_DIR/assets/codex/agents/qwen-explorer.toml" "$CODEX_HOME/agents/qwen-explorer.toml"
copy_file "$SKILL_DIR/assets/codex/agents/qwen-worker.toml" "$CODEX_HOME/agents/qwen-worker.toml"
copy_file "$SKILL_DIR/assets/codex/agents/gemma-explorer.toml" "$CODEX_HOME/agents/gemma-explorer.toml"
copy_file "$SKILL_DIR/assets/codex/agents/gemma-worker.toml" "$CODEX_HOME/agents/gemma-worker.toml"

cat <<EOF

Launch:
  codex --profile hybrid-ollama

Recommended Ollama server:
  OLLAMA_NUM_PARALLEL=2 OLLAMA_MAX_QUEUE=8 OLLAMA_CONTEXT_LENGTH=32768 OLLAMA_KEEP_ALIVE=30m ollama serve
EOF
