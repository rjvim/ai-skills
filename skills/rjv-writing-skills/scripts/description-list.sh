#!/usr/bin/env bash
# description-list.sh <skills-dir> [git-ref]
# Print one "name: description" line per skill under <skills-dir>, as the
# agent's skill list would show them. With a git ref, read each SKILL.md
# at that ref instead of the working tree (for an old-vs-new routing check).
set -eu
dir=$1 ref=${2:-}
for f in "$dir"/*/SKILL.md; do
  name=$(basename "$(dirname "$f")")
  if [ -n "$ref" ]; then
    body=$(git -C "$(dirname "$f")" show "$ref:./SKILL.md" 2>/dev/null) || continue
  else
    body=$(cat "$f")
  fi
  desc=$(printf '%s\n' "$body" | awk '/^description:/{sub(/^description:[ ]*/,""); gsub(/^"|"$/,""); print; exit}')
  printf -- '- %s: %s\n' "$name" "$desc"
done
