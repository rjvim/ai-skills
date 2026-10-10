#!/usr/bin/env bash
# Set up a Claude Code profile (a CLAUDE_CONFIG_DIR) so it gets the same
# settings, hooks, status line, skills and plugins as the base ~/.claude.
#
#   scripts/claude-profile.sh <name|dir> [--base <dir>] [--dry-run]
#
#   <name>  a bare name maps to ~/.claude-<name>; anything with a slash is a dir.
#
# Safe to re-run. What it does:
#   settings.json  base settings deep-merged under the profile's own; the
#                  profile wins on conflicts, permission allow/deny lists are
#                  unioned. The old file is kept as settings.json.bak.<time>.
#   skills/        links every base skill the profile does not already have.
#   keybindings.json, agents/, commands/
#                  linked from the base when the profile has none.
#   plugins        adds the base's marketplaces and installs its user-scope
#                  plugins that are enabled in base settings.
#
# Not linked: CLAUDE.md. Claude Code reads ~/.claude/CLAUDE.md in every
# profile already, so a link would load it twice.
# Hooks and the status line point at $HOME/.claude/... in the merged settings,
# so they keep working without copying their scripts.
set -euo pipefail

usage() { sed -n 2,8p "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

base="$HOME/.claude"
dry=0
target=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -h|--help) usage ;;
    -*) echo "unknown flag: $1" >&2; usage 1 ;;
    *) target="$1"; shift ;;
  esac
done
[ -n "$target" ] || usage 1
case "$target" in */*) profile="$target" ;; *) profile="$HOME/.claude-$target" ;; esac
profile="${profile%/}"
base="${base%/}"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
[ -d "$base" ] || { echo "base not found: $base" >&2; exit 1; }
[ "$profile" != "$base" ] || { echo "profile and base are the same dir" >&2; exit 1; }

run() { if [ "$dry" = 1 ]; then echo "would: $*"; else "$@"; fi; }
say() { echo "• $*"; }

run mkdir -p "$profile/skills"

# settings.json
if [ -f "$base/settings.json" ]; then
  current="$profile/settings.json"
  [ -f "$current" ] || current=/dev/null
  merged=$(jq -n --slurpfile b "$base/settings.json" --slurpfile p <(cat "$current" 2>/dev/null || echo '{}') '
    ($b[0] // {}) as $b | ($p[0] // {}) as $p |
    ($b * $p)
    | .permissions.allow = ((($b.permissions.allow // []) + ($p.permissions.allow // [])) | unique)
    | .permissions.deny  = ((($b.permissions.deny  // []) + ($p.permissions.deny  // [])) | unique)
    | if (.permissions.allow | length) == 0 then del(.permissions.allow) else . end
    | if (.permissions.deny  | length) == 0 then del(.permissions.deny)  else . end
    | if .permissions == {} then del(.permissions) else . end')
  if [ -f "$profile/settings.json" ] && [ "$merged" = "$(jq . "$profile/settings.json")" ]; then
    say "settings.json already up to date"
  elif [ "$dry" = 1 ]; then
    say "would write merged settings.json:"; echo "$merged"
  else
    [ -f "$profile/settings.json" ] && cp "$profile/settings.json" "$profile/settings.json.bak.$(date +%Y%m%d%H%M%S)"
    printf '%s\n' "$merged" > "$profile/settings.json"
    say "settings.json merged from $base"
  fi
fi

# skills
linked=0
if [ -d "$base/skills" ]; then
  for d in "$base"/skills/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    [ -e "$profile/skills/$name" ] || [ -L "$profile/skills/$name" ] && continue
    run ln -s "$base/skills/$name" "$profile/skills/$name"
    linked=$((linked + 1))
  done
fi
say "skills: linked $linked new"

# other shared files
for f in keybindings.json agents commands; do
  if [ -e "$base/$f" ] && [ ! -e "$profile/$f" ] && [ ! -L "$profile/$f" ]; then
    run ln -s "$base/$f" "$profile/$f"
    say "linked $f"
  fi
done

# plugins
if command -v claude >/dev/null; then
  if [ -f "$base/plugins/known_marketplaces.json" ]; then
    jq -r 'to_entries[] | select(.value.source.source == "github") | "\(.key) \(.value.source.repo)"' \
      "$base/plugins/known_marketplaces.json" |
    while read -r name repo; do
      if [ -f "$profile/plugins/known_marketplaces.json" ] &&
         jq -e --arg n "$name" 'has($n)' "$profile/plugins/known_marketplaces.json" >/dev/null; then
        continue
      fi
      say "marketplace $name"
      run env CLAUDE_CONFIG_DIR="$profile" claude plugin marketplace add "$repo" </dev/null || say "marketplace $name failed"
    done
  fi
  if [ -f "$base/plugins/installed_plugins.json" ]; then
    jq -r --slurpfile s "$base/settings.json" '
      .plugins | to_entries[]
      | select(any(.value[]; .scope == "user"))
      | select(($s[0].enabledPlugins // {})[.key] == true) | .key' \
      "$base/plugins/installed_plugins.json" |
    while read -r plugin; do
      if [ -f "$profile/plugins/installed_plugins.json" ] &&
         jq -e --arg p "$plugin" '.plugins | has($p)' "$profile/plugins/installed_plugins.json" >/dev/null; then
        continue
      fi
      say "plugin $plugin"
      run env CLAUDE_CONFIG_DIR="$profile" claude plugin install "$plugin" </dev/null || say "plugin $plugin failed"
    done
  fi
else
  say "claude not on PATH, skipped plugins"
fi

say "done: $profile"
