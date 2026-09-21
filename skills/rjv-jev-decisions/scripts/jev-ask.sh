#!/usr/bin/env bash
# Ask Jev (TypeSafe System One) a set of typed questions about one state.
# Prints {model, answers, usage} as JSON on stdout.
#
# usage: jev-ask.sh QUESTIONS.json [STATE_FILE | -]
#   QUESTIONS.json  a TypeSafe `questions` map (see ../decisions/*.json)
#   STATE           text or JSON; read from stdin when omitted or "-"
#
# env:
#   TYPESAFE_API_KEY   required unless JEV_DRY_RUN or JEV_FAKE_RESPONSE is set
#   JEV_MODEL          default jev-latest; pin e.g. jev-1.13.0 once thresholds are tuned
#   JEV_DRY_RUN=1      print the request body and exit, nothing is sent
#   JEV_FAKE_RESPONSE  path to a saved response; used instead of calling the API
#
# Exit 0 on an answer, 2 on usage error, 3 when the API call fails.
# Callers must treat exit 3 as "no decision" and fall back, never block work.
set -euo pipefail

if [ $# -lt 1 ] || [ ! -f "$1" ]; then
  sed -n '2,17p' "$0" >&2
  exit 2
fi
questions_file="$1"
state_src="${2:--}"

state_raw=$(cat "$state_src")
# JSON state goes as structure, anything else as a string.
if printf '%s' "$state_raw" | jq -e 'type == "object" or type == "array"' >/dev/null 2>&1; then
  state=$(printf '%s' "$state_raw" | jq -c .)
else
  state=$(printf '%s' "$state_raw" | jq -Rs .)
fi

body=$(jq -n \
  --argjson state "$state" \
  --slurpfile questions "$questions_file" \
  --arg model "${JEV_MODEL:-jev-latest}" \
  '{state: $state, model: $model, questions: $questions[0]}')

if [ -n "${JEV_DRY_RUN:-}" ]; then
  printf '%s\n' "$body"
  exit 0
fi

if [ -n "${JEV_FAKE_RESPONSE:-}" ]; then
  response=$(cat "$JEV_FAKE_RESPONSE")
else
  if [ -z "${TYPESAFE_API_KEY:-}" ]; then
    echo "jev-ask: TYPESAFE_API_KEY is not set" >&2
    exit 3
  fi
  # 10s ceiling: a decision that takes longer than the work it routes is not worth waiting for.
  if ! response=$(curl -sS --fail-with-body -m 10 --retry 2 --retry-delay 1 \
      https://api.typesafe.ai/v1/systemone \
      -H "Authorization: Bearer $TYPESAFE_API_KEY" \
      -H "Content-Type: application/json" \
      -d "$body"); then
    echo "jev-ask: API call failed: $response" >&2
    exit 3
  fi
fi

printf '%s' "$response" | jq '{model, answers, usage}'
