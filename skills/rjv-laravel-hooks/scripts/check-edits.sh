#!/usr/bin/env bash
# check-edits.sh BASE [HEAD]
#
# Fails when the range BASE..HEAD edits a file that judges changes (tests
# config, baselines, specs, hooks, REVIEW.md) and no commit in the range
# explains it with a line starting "This changes a check because".
#
# The protected list is read from BASE, never from the change itself, so a
# change cannot unprotect a file in the same push. Stack-neutral: works in
# any git repo that keeps a .protected-paths file on its base branch.
#
# .protected-paths: one glob per line, # comments allowed. Globs use bash
# pattern matching against repo-relative paths (** is not special; * matches
# across slashes).
#
# Exit 0: nothing protected changed, or every such change is explained.
# Exit 1: a protected file changed without an explanation.
# Exit 2: usage error.

set -euo pipefail

base="${1:-}"; head="${2:-HEAD}"
[[ -n "$base" ]] || { echo "usage: check-edits.sh BASE [HEAD]" >&2; exit 2; }

globs="$(git show "$base:.protected-paths" 2>/dev/null | sed -e 's/#.*//' -e 's/[[:space:]]*$//' | grep -v '^$' || true)"
if [[ -z "$globs" ]]; then
    echo "check-edits: no .protected-paths on $base, skipping"
    exit 0
fi

hits=()
while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    while IFS= read -r glob; do
        # shellcheck disable=SC2053
        if [[ "$file" == $glob ]]; then hits+=("$file"); break; fi
    done <<< "$globs"
done < <(git diff --name-only "$base...$head")

[[ ${#hits[@]} -gt 0 ]] || { echo "check-edits: no protected file changed"; exit 0; }

if git log --format=%B "$base..$head" | grep -q '^This changes a check because'; then
    echo "check-edits: protected files changed, explained in a commit body:"
    printf '  %s\n' "${hits[@]}"
    exit 0
fi

echo "check-edits: these files judge changes and were edited:" >&2
printf '  %s\n' "${hits[@]}" >&2
echo "Fix the code instead, or move this edit to its own commit whose body" >&2
echo "has a line starting: This changes a check because" >&2
exit 1
