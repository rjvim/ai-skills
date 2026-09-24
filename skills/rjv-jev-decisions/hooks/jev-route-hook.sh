#!/usr/bin/env bash
# PreToolUse hook for Claude Code (Agent tool) and Codex (spawn_agent).
# When a subagent is about to start without an explicit model, ask Jev
# which tier the task needs and fill in the model before it starts.
#
# Fails open: any error, missing key, or unsupported call prints nothing
# and exits 0, so the spawn goes ahead exactly as the agent wrote it.
#
# An explicit model is always kept. So are Claude forks and custom agent
# types (they carry their own model), and Codex full-history forks (Codex
# rejects a model override on those).
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
pick="$here/../scripts/jev-model-pick.sh"

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
ti=$(printf '%s' "$input" | jq -c '.tool_input // {}')

# Hooks may start without the login shell's environment.
if [ -z "${TYPESAFE_API_KEY:-}" ] && [ -f "$HOME/.zshenv" ]; then
  eval "$(grep -E '^[[:space:]]*export[[:space:]]+TYPESAFE_API_KEY=' "$HOME/.zshenv" | tail -1)"
  export TYPESAFE_API_KEY
fi

case "$tool" in
  Agent|Task)
    host=claude
    skip=$(printf '%s' "$ti" | jq -r '
      if (.model // "") != "" then "explicit model"
      elif (.subagent_type // "general-purpose") | IN("general-purpose", "claude") | not then "custom agent type"
      else "" end')
    # First 2000 characters only: enough to judge, less sent to TypeSafe.
    task=$(printf '%s' "$ti" | jq -r '[.description // "", (.prompt // "")[0:2000]] | join("\n\n")')
    ;;
  spawn_agent|*spawn_agent)
    host=codex
    skip=$(printf '%s' "$ti" | jq -r '
      if (.model // "") != "" then "explicit model"
      elif ((.fork_turns // "all") | tostring) == "all" then "full-history fork"
      else "" end')
    # Codex 0.155 hands hooks the message already encrypted. Jev then has only
    # the task name to judge, so send that alone rather than ciphertext.
    task=$(printf '%s' "$ti" | jq -r '
      (.task_name // "" | gsub("_"; " ")) as $name
      | (.message // "") as $msg
      | if ($msg | test("^gAAAA[A-Za-z0-9_=-]+$")) or $msg == "" then "Task name: \($name)"
        else [$name, $msg[0:2000]] | join("\n\n") end')
    ;;
  *)
    exit 0
    ;;
esac

if [ -n "$skip" ]; then
  JEV_HOST=$host "$pick" --log-skip "$skip" "$task" >/dev/null 2>&1
  exit 0
fi

if ! decision=$(JEV_HOST=$host "$pick" "$task" 2>/dev/null); then
  exit 0
fi

if [ "$host" = claude ]; then
  model=$(printf '%s' "$decision" | jq -r '.claude // empty')
  [ -n "$model" ] || exit 0
  jq -n --argjson ti "$ti" --arg model "$model" --argjson d "$decision" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      updatedInput: ($ti + {model: $model}),
      additionalContext: "Jev set this subagent to \($model) (\($d.tier)): \($d.why). If the brief names no time budget, pick one of \($d.budget_boxes.cloud | map(tostring) | join("/")) min by task size; over it, stop and re-split, never extend."
    }
  }'
else
  model=$(printf '%s' "$decision" | jq -r '.codex.model // empty')
  effort=$(printf '%s' "$decision" | jq -r '.codex.reasoning_effort // empty')
  [ -n "$model" ] || exit 0
  # Codex applies updatedInput only together with an allow decision.
  jq -n --argjson ti "$ti" --arg model "$model" --arg effort "$effort" --argjson d "$decision" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      updatedInput: ($ti + {model: $model, reasoning_effort: $effort}),
      additionalContext: "Jev set this sub-agent to \($model) at \($effort) effort (\($d.tier)): \($d.why). If the brief names no time budget, pick one of \($d.budget_boxes.cloud | map(tostring) | join("/")) min by task size; over it, stop and re-split, never extend."
    }
  }'
fi
exit 0
