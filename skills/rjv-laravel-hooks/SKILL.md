---
name: rjv-laravel-hooks
description: Install the cheap checks a Laravel repo runs before every push - a guard that stops a change editing the checks that judge it, a database-reset guard, Pint, PHPStan, ratchets and the touched Pest files - in under 60 seconds. Use when a Laravel repo has no pre-push hook, when pushes reach CI untested, when a change weakened its own tests or baselines, or when setting up protected paths. The guard script also works in any stack. When checks run lives in rjv-verify.
---

# Laravel pre-push hooks

Two scripts in `scripts/`:

| Script | Does |
|---|---|
| `pre-push` | runs the steps below on files the push changes, stops at the first failure |
| `check-edits.sh BASE [HEAD]` | fails when the range edits a protected file without an explanation; any stack |

`pre-push` order, cheapest and most decisive first:

check-edits -> database-reset guard -> pint --test -> phpstan -> ratchet-check.sh -> touched Pest files

Each step skips itself when its tool or script is absent. Both scripts
run on macOS bash 3.2.

## 1. Protect the checks first, on the base branch

`check-edits.sh` reads `.protected-paths` from the base branch, never
from the push. A change therefore cannot unprotect a file and edit it
in the same push. So `.protected-paths` lands on main in its own commit
before the hook goes live.

Starter list for a Laravel repo; keep only paths that exist:

```text
# files that judge changes
tests/Pest.php
tests/TestCase.php
phpunit.xml
phpstan*.neon
pint.json
deptrac*.yaml
scripts/ratchet-baseline.txt
scripts/ratchet-check.sh
.githooks/*
.protected-paths
REVIEW.md
.github/*
.gitlab-ci.yml
```

Leave feature specs off the list in a spec-driven repo: most feature
pushes edit their spec, so every one would need the explanation line.

A protected edit passes only when a commit in the push has a body line
starting `This changes a check because`. Put that edit in its own
commit, so the reviewer sees it apart from the code.

Done when `git show origin/main:.protected-paths` prints the list.

## 2. Install the hook

Run every step on a clean checkout of main first. A step that already
fails on main blocks every push from day one. Fix it in its own commit
before the hook goes live; raising a baseline is a protected edit.

1. Copy `scripts/pre-push` and `scripts/check-edits.sh` into the repo's
   `.githooks/`, executable.
2. Run `git config core.hooksPath .githooks`, and add the same command
   to composer.json `post-install-cmd` so every clone gets it.
3. Set what Pest runs. The default is the touched test files with
   `--exclude-group=browser`. When the repo has a no-database group,
   set `PREPUSH_PEST_ARGS="--group=ci-nodb"` in the hook's first lines.
4. The database guard blocks `RefreshDatabase`, `DatabaseTruncation`
   and `DatabaseMigrations` in touched tests and `tests/Pest.php`,
   unless a comment opens before the word. Use `DatabaseTransactions`.

Done when a push that touches one PHP file runs every present step.

## 3. Hold the 60-second budget

The hook prints its time and warns past `PREPUSH_BUDGET` (60 s). A slow
hook gets bypassed, so fix the slowest step before adding one.
Heavy suites stay out of the hook (`rjv-verify` phase 4): full Pest,
browser tests and production builds run before a release or in CI.

Done when three real pushes each pass in under 60 s.

## 4. Run the guard in CI too

A local hook can be skipped, so CI runs the guard against the target
branch:

```sh
git fetch origin "$TARGET_BRANCH" && .githooks/check-edits.sh "origin/$TARGET_BRANCH" HEAD
```

Use `$CI_MERGE_REQUEST_TARGET_BRANCH_NAME` on GitLab and
`$GITHUB_BASE_REF` on GitHub. Run it only on merges into the branch
feature work lands on. Release and promotion merges carry many commits
already checked there, and the guard would fail every one.

**Never push with `--no-verify`.** When the hook is wrong, fix the hook
in its own commit with the explanation line, then push.

Done when CI fails on a merge request that edits a protected file
without the explanation line.

## Tested

2026-11-19, throwaway repo with stub tools under bash 3.2: a clean
change ran all steps; a baseline edit without a reason failed; the same
edit with the explanation line passed; a test using `RefreshDatabase`
failed while a commented-out one in `tests/Pest.php` passed; deleting
`.protected-paths` in the same push still failed.

2026-11-20, first real install (MF Stack): a namespaced
`use ...\RefreshDatabase;` import in `tests/Pest.php` blocked every
test push until the guard skipped import lines; a ratchet already red
on main would have blocked every push; protected specs and a CI guard
on release merges would have failed most pushes.
