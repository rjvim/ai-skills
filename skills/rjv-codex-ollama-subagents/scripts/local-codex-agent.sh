#!/bin/sh
set -eu

if [ "$#" -lt 2 ]; then
  echo "usage: $0 ROLE PROMPT" >&2
  exit 2
fi

ROLE=$1
shift
PROMPT=$*
LOCAL_CODEX_HOME=${LOCAL_CODEX_HOME:-$HOME/.codex-ollama}

case "$ROLE" in
  gemma-explorer) MODEL='gemma4:26b'; SANDBOX='read-only'; REASONING='low' ;;
  gemma-worker) MODEL='gemma4:26b'; SANDBOX='workspace-write'; REASONING='low' ;;
  *) echo "unknown local role: $ROLE" >&2; exit 2 ;;
esac
# Time budget the caller picks per task: 10, 20 or 30 minutes.
# Over it, the task was split badly: re-split, do not extend.
case "${LOCAL_AGENT_MINUTES:-}" in
  10|20|30) MINUTES=$LOCAL_AGENT_MINUTES ;;
  *) echo "set LOCAL_AGENT_MINUTES to 10, 20 or 30 (the time budget for this run)" >&2; exit 2 ;;
esac

case "$SANDBOX" in
  read-only) ROLE_PROMPT='Act as a read-only repository explorer. Do not edit files.' ;;
  workspace-write) ROLE_PROMPT='Act as a scoped coding worker. Edit only files named in the task. Preserve unrelated changes. Verify your work. The apply_patch tool is unavailable; use shell or Python file edits.' ;;
esac

mkdir -p "$LOCAL_CODEX_HOME"
if [ ! -e "$LOCAL_CODEX_HOME/config.toml" ]; then
  cat > "$LOCAL_CODEX_HOME/config.toml" <<'EOF'
model_reasoning_effort = "low"

[features]
apps = false
plugins = false
recommended_plugins = false
EOF
fi

exec timeout "${MINUTES}m" env CODEX_HOME="$LOCAL_CODEX_HOME" codex exec \
  --oss \
  --local-provider ollama \
  --model "$MODEL" \
  --cd "$PWD" \
  --sandbox "$SANDBOX" \
  --disable apps \
  --disable plugins \
  --enable skip_host_skill_discovery \
  --config model_context_window=32768 \
  --config model_auto_compact_token_limit=24000 \
  --config model_reasoning_effort="$REASONING" \
  "$ROLE_PROMPT

$PROMPT"
