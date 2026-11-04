---
name: rjv-replica-screenshot
description: "Produce a before/after PR visual when the real screen won't render locally (broken dev build, feature flag, unstageable state, backend-only change with no easy UI path). Build a faithful HTML replica of the actual component using the REAL server payload strings, screenshot it, label it as payload-rendered. Triggers: 'add before/after screenshots' but the page is blank/broken in dev, 'the live page can't render', 'show the fix visually but I can't reach the screen'."
license: MIT
---

# Replica screenshot from real payload

Sometimes you fix a UI-visible bug but **can't screenshot the real screen**:
the dev build is broken by an unrelated import, the state is impractical to
stage, the route is feature-flagged, or the change is backend-only and the page
won't render locally. You still want a credible before/after in the PR.

The move: render a **faithful HTML replica of the actual component**, populated
with the **real server payload strings**, and screenshot that. Done honestly it
is real evidence: the exact bytes the component renders, in the component's own
layout.

## When to use

Use it only when both hold:

- The real UI won't render locally, and the change is visible in the UI.
- You can obtain the exact strings the component receives (see Step 1).

Otherwise:

- The real page renders: screenshot the real page. A replica is a fallback
  for a screen you cannot reach.
- Any value would have to be invented: report the payload as text instead,
  and say the screen couldn't render.

## The honesty contract (non-negotiable)

1. **Real data only.** Every value in the replica is the exact string the real
   code path emits, dumped from it. A value you typed makes the image a mockup.
2. **Faithful markup.** Mirror the real component's DOM structure and Tailwind
   classes so the replica looks like the product's own row or card. Read the
   component first.
3. **Label it.** A caption in the image and a line in the PR body state it is
   rendered from the live payload and why the real screen couldn't be shown.
   A reviewer must never mistake it for a live screenshot.

**A labeled replica of real data is evidence. An unlabeled replica, or one
with any invented value, is a fabricated screenshot. Never ship it.**

## Steps

1. **Capture the real payload, both states.**
   Dump the exact strings the component receives, from the app's own code path.
   - Backend change: run the real builder in `tinker` (or a console script) and
     `dump()` the field(s). Backend edits take effect immediately, so dump **before**
     your edit (the "before" strings) and **after** (the "after" strings). Both are real.
   - Or read the Inertia/JSON response (`X-Inertia` header) / a `console.log`.
   Copy the dumped strings verbatim.

   Done when you hold the before and after strings as tool output.

2. **Read the real component** (the one that renders these fields) to copy its
   structure and Tailwind classes: the wrapper, badges, labels, the exact element
   that prints the field under test.

3. **Build `before.html` and `after.html`**: the same replica, differing only in
   the real before/after strings. Highlight the field under test (e.g. red for the
   bug value, green for the fixed value). Add a one-line caption at the bottom
   stating it's rendered from the live payload.

4. **Screenshot** each with your browser tool (e.g.
   `agent-browser open file://…/before.html`, then
   `agent-browser screenshot before.png`). Use the same viewport width for both
   so before and after align.

5. **Upload and embed.** `rjv-github-image-upload` turns the PNGs into
   `user-attachments` URLs. `rjv-pr-descriptions` owns where they sit: under
   the matching item, as a Before | After table.

6. **Disclose in the PR body.** One line: the real screen couldn't render locally
   because of `<reason>`, so the before/after is rendered from the live server
   payload (the exact strings the component prints), plus the verified transition
   (e.g. `2026-08-24 00:00:00` → `24 Aug 26`).

## Faithfulness checklist

Done when every box holds:

- [ ] Every string is dumped from the real code path (zero typed values).
- [ ] Replica markup mirrors the real component (read it, matched structure + classes).
- [ ] Before and after differ **only** in the field under test.
- [ ] Image caption + PR line both say "rendered from live payload" and why.
- [ ] The verified string transition is stated in text too (image + words agree).

## Evidence

A worked case (mfstack bug #3604) is in [`EVIDENCE.md`](./EVIDENCE.md).

## Pairs with

- `rjv-github-image-upload`: upload the PNGs, get embeddable URLs.
- `rjv-pr-descriptions`: the item the Before/After table and disclosure line sit under.
