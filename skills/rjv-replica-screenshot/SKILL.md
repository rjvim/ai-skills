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
is real evidence — the exact bytes the component renders, in the component's own
layout — not a fabricated mockup.

## When to use

- The real UI genuinely won't render locally, AND the change is visible in the UI.
- You can obtain the exact strings the component receives (see Step 1).

## When NOT to use

- The real page renders → screenshot the real page. A replica is a fallback, never a shortcut.
- You'd have to invent any value. If you can't get the real string, don't fake it — report the payload as text instead and say the screen couldn't render.

## The honesty contract (non-negotiable)

1. **Real data only.** Every value in the replica is the exact string the real
   code path emits — dumped, not typed. If you type a number, it's a mockup, not evidence.
2. **Faithful markup.** Mirror the real component's DOM structure and classes so
   the replica *looks like the product*, not a generic card. Read the component first.
3. **Label it.** A caption in the image (and a line in the PR body) states it is
   rendered from the live payload and WHY the real screen couldn't be shown. A
   reviewer must never mistake it for a live screenshot.

## Steps

1. **Capture the real payload — both states.**
   Dump the exact strings the component receives, from the app's own code path.
   - Backend change: run the real builder in `tinker` (or a console script) and
     `dump()` the field(s). Backend edits take effect immediately, so dump **before**
     your edit (the "before" strings) and **after** (the "after" strings). Both are real.
   - Or read the Inertia/JSON response (`X-Inertia` header) / a `console.log`.
   Never hand-transcribe — copy the dumped strings verbatim.

2. **Read the real component** (the one that renders these fields) to copy its
   structure and Tailwind classes: the wrapper, badges, labels, the exact element
   that prints the field under test. The replica should be visually indistinguishable
   from a row/card in the product.

3. **Build `before.html` and `after.html`** — the same replica, differing only in
   the real before/after strings. Highlight the field under test (e.g. red for the
   bug value, green for the fixed value). Add a one-line caption at the bottom
   stating it's rendered from the live payload.

4. **Screenshot** each with your browser tool (e.g.
   `agent-browser open file://…/before.html` → `agent-browser screenshot before.png`).
   Keep a fixed width so before/after align.

5. **Upload + embed** via `rjv-github-image-upload` (→ `user-attachments` URLs) and
   place them in the PR with `rjv-pr-descriptions` (Before | After table).

6. **Disclose in the PR body.** One line: the real screen couldn't render locally
   because of `<reason>`, so the before/after is rendered from the live server
   payload (the exact strings the component prints), plus the verified transition
   (e.g. `2026-08-24 00:00:00` → `24 Aug 26`).

## Faithfulness checklist

- [ ] Every string is dumped from the real code path (zero typed values).
- [ ] Replica markup mirrors the real component (read it, matched structure + classes).
- [ ] Before and after differ **only** in the field under test.
- [ ] Image caption + PR line both say "rendered from live payload" and why.
- [ ] The verified string transition is stated in text too (image + words agree).

## Evidence

Bug #3604 (mfstack): SIP "Instalment Details" showed the Upcoming installment
date raw (`2026-08-24 00:00:00`) vs completed `d M y h:i a`. The real SIP detail
page couldn't render in local dev — a pre-existing unrelated broken import in
`SipPage.tsx` left the page blank. So: dumped the real `OrderHistoryReport::groupSipData()`
payload for a real active SIP (`upcoming date = "2026-08-24 00:00:00"`, then after
the fix `"24 Aug 26"`, completed `"09 Jul 26 04:09 pm"` unchanged), rebuilt the
`SIPInstalmentRow` layout in HTML with those exact strings, screenshotted
before/after, and labeled both as payload-rendered. The reviewer (cross-vendor)
signed off on the fix on payload evidence; the images communicated it visually
without ever pretending to be a live screen.

Register note: a labeled replica of real data is evidence. An unlabeled replica,
or one with any invented value, is a fabricated screenshot — don't ship it.

## Pairs with

- `rjv-github-image-upload` — upload the PNGs, get embeddable URLs.
- `rjv-pr-descriptions` — place the Before/After table + disclosure line.
