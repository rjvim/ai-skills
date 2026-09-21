#!/usr/bin/env bash
# Summarise the model-pick log, to tune the thresholds in routes.json.
#
# usage: jev-log-review.sh [DAYS]      (default 7)
#
# Prints counts per host and tier, how often each rule moved a task up,
# and the borderline decisions worth reading by hand: low confidence,
# or a high-stakes score near the floor.
set -euo pipefail
log="${JEV_LOG:-$HOME/.local/state/rjv-jev/model-pick.jsonl}"
days="${1:-7}"
[ -f "$log" ] || { echo "no log yet at $log"; exit 0; }

jq -s --argjson days "$days" '
  (now - $days * 86400) as $since
  | map(select((.ts | fromdateiso8601) >= $since)) as $all
  | ($all | map(select(.tier))) as $picked
  | {
      window_days: $days,
      decisions: ($picked | length),
      skipped: ($all | map(select(.skipped)) | group_by(.skipped) | map({(.[0].skipped): length}) | add),
      errors: ($all | map(select(.error)) | length),
      by_host_and_tier: ($picked | group_by(.host) | map({(.[0].host): (group_by(.tier) | map({(.[0].tier): length}) | add)}) | add),
      moved_up_for_low_confidence: ($picked | map(select(.why | test("low confidence"))) | length),
      raised_for_high_stakes: ($picked | map(select(.why | test("high stakes"))) | length),
      read_these_by_hand: ($picked
        | map(select(.jev.confidence < 0.75 or (.jev.high_stakes > 0.35 and .jev.high_stakes < 0.65)))
        | map({tier, why, high_stakes: .jev.high_stakes, task: .task[0:120]}))
    }' "$log"
