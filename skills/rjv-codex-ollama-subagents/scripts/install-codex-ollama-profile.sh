#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCAL_HOME=${LOCAL_CODEX_HOME:-$HOME/.codex-ollama}

command -v codex >/dev/null 2>&1 || { echo "missing required command: codex" >&2; exit 1; }
command -v ollama >/dev/null 2>&1 || { echo "missing required command: ollama" >&2; exit 1; }

mkdir -p "$LOCAL_HOME"
cat > "$LOCAL_HOME/config.toml" <<'EOF'
model_reasoning_effort = "low"

[features]
apps = false
plugins = false
recommended_plugins = false

[sandbox_workspace_write]
network_access = false
EOF

chmod +x "$SCRIPT_DIR/local-codex-agent.sh"

cat <<EOF
Installed the local Codex harness at $LOCAL_HOME.

Run from a repository:
  LOCAL_AGENT_MINUTES=10 $SCRIPT_DIR/local-codex-agent.sh gemma-explorer "Read package.json and report its name."
EOF
