#!/usr/bin/env bash
# Check a cheap worker's report against the task's acceptance items, and say
# whether to keep the cheap result or escalate to a stronger model.
#
# usage: jev-verify.sh INPUT.json      (or the JSON on stdin)
#   INPUT.json: {"task": "...", "acceptance": ["...", "..."], "report": "..."}
#   report is the worker's final message, or a short diff summary.
#
# Prints {escalate, weakest, items: [{item, done}]}.
# Exit 3 when Jev is unreachable: review the report yourself.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
DONE_MIN="${JEV_DONE_MIN:-0.7}"   # untuned; below this an item counts as not shown done

input=$(cat "${1:--}")
count=$(printf '%s' "$input" | jq '.acceptance | length')
if [ "$count" -eq 0 ]; then
  echo "jev-verify: acceptance list is empty" >&2
  exit 2
fi

# One Noul per acceptance item, all in one request.
questions=$(printf '%s' "$input" | jq '
  [range(0; .acceptance | length) as $i
   | {key: "item_\($i)",
      value: {type: "noul",
              instructions: "Does `report` show that `acceptance[\($i)]` was actually done, rather than skipped, stubbed, or only planned?"}}]
  | from_entries')
qfile=$(mktemp); trap 'rm -f "$qfile"' EXIT
printf '%s' "$questions" > "$qfile"

if ! answer=$(printf '%s' "$input" | "$here/jev-ask.sh" "$qfile" -); then
  exit 3
fi
if [ -n "${JEV_DRY_RUN:-}" ]; then
  printf '%s\n' "$answer"
  exit 0
fi

printf '%s' "$answer" | jq --argjson input "$input" --argjson min "$DONE_MIN" '
  [range(0; $input.acceptance | length) as $i
   | {item: $input.acceptance[$i], done: .answers["item_\($i)"].noul}] as $items
  | {
      escalate: ($items | any(.done < $min)),
      weakest: ($items | min_by(.done)),
      items: $items
    }'
