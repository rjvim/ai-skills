#!/usr/bin/env bash
# Pick the cheapest model tier for one delegated coding task.
# Jev judges the task; the rules below and routes.json turn that into a model.
#
# usage: jev-model-pick.sh "task description"      (or the task on stdin)
#
# Prints one JSON object:
#   {tier, claude, codex, local_text_only, why, jev: {tier, confidence, high_stakes, needs_repo}}
# Exit 3 when Jev is unreachable: fall back to the ladder in SKILL.md by hand.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
decisions="$here/../decisions"

if [ $# -gt 0 ]; then task="$*"; else task=$(cat); fi
if [ -z "$task" ]; then
  echo "jev-model-pick: no task given" >&2
  exit 2
fi

state=$(jq -n --arg task "$task" '{task: $task}')
if ! answer=$(printf '%s' "$state" | "$here/jev-ask.sh" "$decisions/model-tier.json" -); then
  exit 3
fi
if [ -n "${JEV_DRY_RUN:-}" ]; then
  printf '%s\n' "$answer"
  exit 0
fi

printf '%s' "$answer" | jq --slurpfile routes "$decisions/routes.json" '
  $routes[0] as $r
  | ["mechanical", "standard", "hard"] as $ladder
  | .answers as $a
  | ($ladder | index($a.tier.choice)) as $picked
  # Unsure means go one tier up: a wasted cheap attempt costs more than the saving.
  | (if $a.tier.confidence < $r.thresholds.confidence_min then [$picked + 1, 2] | min else $picked end) as $after_conf
  # Stakes raise the floor: never hand risky work to the cheapest tier.
  | (if $a.high_stakes.noul >= $r.thresholds.high_stakes_floor then [$after_conf, 1] | max else $after_conf end) as $final
  | $ladder[$final] as $tier
  | ($a.needs_repo.noul >= $r.thresholds.needs_repo_min) as $repo
  | {
      tier: $tier,
      claude: $r.claude[$tier],
      codex: $r.codex[$tier],
      # A local model has no repo tools, so it is only an option for text-only work.
      local_text_only: (if $repo then null else $r.local_text_only[$tier] end),
      why: ([
        "jev said \($a.tier.choice) at confidence \($a.tier.confidence)",
        (if $after_conf != $picked then "low confidence, moved up a tier" else empty end),
        (if $final != $after_conf then "high stakes, raised to at least standard" else empty end)
      ] | join("; ")),
      jev: {
        model: .model,
        tier: $a.tier.choice,
        confidence: $a.tier.confidence,
        high_stakes: $a.high_stakes.noul,
        needs_repo: $a.needs_repo.noul
      }
    }'
