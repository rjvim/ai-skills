#!/usr/bin/env bash
# Run one task on a local Ollama model with repo tools, through a shared opencode server.
#
#   opencode-local.sh <provider/model> "<brief>" [dir]
#
# Starts the server on OPENCODE_PORT (default 4096) if it is not up. Before the run it checks
# memory: it refuses below OPENCODE_MIN_FREE_PCT free (default 25) and unloads every other
# model when more than OPENCODE_MAX_LOADED (default 2) are resident. Prints the model's final
# output; the caller reviews the diff itself.
# LOCAL_AGENT_MINUTES (10, 20 or 30) is the time budget the caller picks per task.
set -euo pipefail

model="${1:?model, e.g. ollama/gemma4:26b}"
brief="${2:?brief}"
dir="${3:-$PWD}"
port="${OPENCODE_PORT:-4096}"
min_free="${OPENCODE_MIN_FREE_PCT:-25}"
max_loaded="${OPENCODE_MAX_LOADED:-2}"
name="${model#ollama/}"
case "${LOCAL_AGENT_MINUTES:-}" in
  10|20|30) ;;
  *) echo "opencode-local: set LOCAL_AGENT_MINUTES to 10, 20 or 30 (the time budget for this run)" >&2; exit 2 ;;
esac

free_pct() { memory_pressure | awk -F': ' '/free percentage/ {gsub("%","",$2); print $2}'; }

loaded=$(ollama ps | awk 'NR>1 {print $1}')
if [ "$(printf '%s\n' "$loaded" | grep -c .)" -ge "$max_loaded" ]; then
  printf '%s\n' "$loaded" | grep -vxF "$name" | while read -r m; do [ -n "$m" ] && ollama stop "$m"; done
fi
free=$(free_pct)
if [ "$free" -lt "$min_free" ]; then
  echo "opencode-local: only ${free}% memory free (need ${min_free}%). Loaded: $(ollama ps | awk 'NR>1 {print $1}' | xargs)" >&2
  exit 4
fi

if ! curl -s -o /dev/null "http://localhost:$port"; then
  (cd "$dir" && nohup opencode serve --port "$port" >"${TMPDIR:-/tmp}/opencode-serve-$port.log" 2>&1 &)
  for _ in $(seq 20); do curl -s -o /dev/null "http://localhost:$port" && break; sleep 0.5; done
fi

start=$(date +%s)
timeout "${LOCAL_AGENT_MINUTES}m" opencode run --attach "http://localhost:$port" --dir "$dir" -m "$model" "$brief"
echo "opencode-local: $model took $(( $(date +%s) - start ))s, memory free $(free_pct)%" >&2
