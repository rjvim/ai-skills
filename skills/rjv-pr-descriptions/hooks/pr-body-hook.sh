#!/usr/bin/env bash
# PreToolUse hook for Claude Code (Bash tool).
# When a command is about to create or edit a GitHub PR or a GitLab MR,
# remind the agent to write the body with rjv-pr-descriptions.
#
# Fails open: any error or unrelated command prints nothing and exits 0,
# so the command runs exactly as the agent wrote it.
set -uo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null) || exit 0
[ "$tool" = "Bash" ] || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

if printf '%s' "$cmd" | grep -Eq 'gh +pr +(create|edit)|glab +mr +(create|update)|merge_request\.(create|description)'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: "This command writes a PR or MR body. If rjv-pr-descriptions is not loaded in this session, load it and write the body to its shape: \"Test in the UI\" and \"Needs code or environment setup\" sections, both always present."
    }
  }'
fi
exit 0
