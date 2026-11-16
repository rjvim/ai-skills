---
name: rjv-fast-code
description: The fast lane for a small fix - one scoped change, smoke checks only, shipped and seen live in minutes.
disable-model-invocation: true
---

# Fast code

A small request gets one change, a smoke check, a direct ship and one
look at the live result. This is `rjv-work-plan`'s `simple` build mode:
no plan file, no spec, the commit message carries the intent.

## 0. Does it apply?

| The request | Lane |
|---|---|
| one component, bug, visual fix, config or doc, intent fits one sentence | fast lane: steps 1 to 6 |
| new architecture, public API, migration, money, security, "critical" | leave this skill; `rjv-work-plan` picks the mode |
| starts small, then a second change turns out to be needed | finish the first, list the second for the user (step 1) |

## 1. Scope in one line

Write the scope as one sentence before touching code. Do only that.

**Never fold a second change into the same commit.** Anything else you
or a reviewer notice goes on a list for the user, in the final report.

Done when the scope line is written and every edit serves it.

## 2. Start now, one worker

Do it yourself, or hand it to exactly one agent. Start immediately:
a fast-lane task is outside any agent cap and never waits behind a
long-running job. No orchestration, no fan-out, no plan file.

Done when the work started within a minute of the request.

## 3. Fix at the source

If the defect comes from a shared library or design system that other
apps consume, fix it there, release it, and bump the app. Do not patch
around it in the app. The fix still covers only the one scoped thing.

Done when the fix sits in the package that owns the defect.

## 4. Smoke only

Run the type check and lint for the touched files, if that takes under
a minute. That is the whole test run.

Test tiers, and when each runs:

| Tier | What | When |
|---|---|---|
| 1 smoke | types and lint on touched files, seconds | every fast-lane change |
| 2 unit | full unit suites | before a library release, unless the user waived it |
| 3 browser | Playwright or other browser suites | only when the user asks |
| 4 QA | screenshot rounds, design review, manual QA | only when the user asks |

Do not run full unit suites, browser suites, production builds,
screenshot rounds or design reviews in the fast lane unless the user
asks. If a pre-push hook runs tiers 2 to 4, tell the user once and ask
whether to skip it for this push.

Done when tier 1 passed and nothing above it ran unasked.

## 5. Ship

Ship directly only where the user has allowed it for this repo, in the
conversation or in the repo's own AGENTS.md or skill. For a
non-critical app that means push to main and let the hosting build
(for example Vercel) be the gate. A library may be released without
its suites if the user said so.

**Never force push. Never commit local links, `file:` overrides or
workarounds.** Without that permission, push a branch and ask once.

At most one independent review, and only for a library release,
scoped to the change, with out-of-scope findings listed separately.
A small app fix gets no review.

Done when the change is pushed and the deploy has started.

## 6. See it live, once

Wait for the deploy in the background, then open the live page and
look at the one changed thing: one screenshot, one width.

**Never tell the user it is fixed before you have seen it fixed.**
Pushed is not live, and live is not verified.

Done when the screenshot shows the fix on the live URL.

## Machine hygiene

- One heavy job at a time: one build, one browser suite.
- Reuse a running dev server; never start one per agent.
- Kill servers, browsers and emulators you started as soon as the
  check is done.

## Report

One screen: what changed, where it is live, what you saw, and the list
of things noticed but not done. No process narration.

## Seen on 2026-11-16 (do not repeat)

- A "status bar" fix bundled a safe-area wrapper, colour logic, a
  naming-rule rewrite and a second frame.
- Three review rounds on a one-component change.
- A pre-push hook ran a production build and 270 browser tests for a
  5-line change.
- Three agents each ran `next build` and Playwright at once: load
  average 40 to 60, 25-minute builds.
- "Fixed and live" was reported before anyone looked; the card still
  sat under the status bar.
