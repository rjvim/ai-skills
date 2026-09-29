---
name: rjv-hidpi-fullpage
description: "Take a full-page, full-width, genuinely high-DPI (2x) screenshot of a web page or signed-in web app with agent-browser, including apps whose content scrolls inside a fixed panel. Also the procedure for crawling an app's read-only pages (reports, tables, detail pages, tabs) into a screenshot catalogue. Triggers: 'high resolution screenshot', 'full page screenshot', 'retina screenshot', '2x screenshot', 'hi-dpi capture', 'screenshot every page', 'capture all reports', 'catalogue this app'."
---

# High-DPI full-page capture

Goal: one PNG per page where the page fills the full image width, every pixel
is real 2x rendering, and nothing is cut off or padded with blank space.

## The one rule that makes it high-DPI

Set density through viewport emulation, as the third number:

    agent-browser --session S set viewport 1920 1080 2

This gives a 3840 px wide image of a 1920 px wide layout.

Never use the Chrome launch flag `--force-device-scale-factor=2`. It renders
the page small inside a large blank canvas. Never upscale an image or change
DPI metadata to claim more resolution; neither adds detail.

## Capture a page

Open the page in a session, sign in, click the tab you want, close popups.
Then run the `capture.sh` bundled in this skill's folder
(`~/.agents/skills/rjv-hidpi-fullpage/` when installed with `npx skills`):

    capture.sh SESSION out.png [1920] [2]

The script:
1. sets the viewport to the width at 2x,
2. waits for network idle and fonts,
3. scrolls the window and every inner scroll panel so lazy content loads,
4. lets inner scroll panels grow to their content (`UNCLIP=0` to skip),
5. returns to the top, takes the full-page screenshot,
6. fails if the width is not width × scale, and warns if the image is
   shorter than the page.

Exit codes: 0 ok, 1 density or screenshot failed, 3 image cut off.

## Why inner panels are unclipped

Many back-office apps put the page body in a panel fixed to a share of the
window height (for example 75vh) that scrolls on its own. A full-page shot
then shows only the first screen of that panel. Making the window taller does
not fix it: the panel grows with the window and leaves a blank band above
the footer. Setting the panel and its clipping ancestors to `height: auto`
in the live browser shows the whole content once, top to bottom. It changes
nothing on the server.

For a marketing site whose layout must be preserved exactly, use `UNCLIP=0`.

## Always look at the result

Width alone proves nothing. Open the image (a resized copy for the overview,
a full-size crop for sharpness) and check:
- header at the top, footer at the bottom, no blank band between,
- no popup or loading overlay covering content,
- text in a full-size crop is crisp.

## Crawling an app for reading pages

Use this when asked to catalogue every page, report or table of an app.

Read-only rules. These are absolute:
- Never fill or submit a form. No typing into inputs, no saving, deleting,
  uploading, sending email or SMS, placing orders, or changing settings.
- Allowed: open links and menu items, click tabs, and click view, show,
  filter, sort, pagination and expand controls with the values already
  offered on the page.
- Popups: click "Don't Show Again" when offered, otherwise Close.
- Skip pages that are only forms (create, edit, upload, settings).
- Follow deeper links: row links in tables open detail pages; capture each
  kind of detail page once, plus every tab inside it.
- Never log out. If the session expires, sign in again the same way.

Naming: `<menu>--<page>[--<tab>].png` in lowercase words joined by hyphens,
for example `aum--scheme-wise--equity.png`. Keep a running list of every
page visited, its URL, its file name, and pages skipped with the reason.

Very tall pages: if the script exits 3, keep the image, and note in the list
that the page is cut off at that height.

## Evidence

A back-office dashboard, September 2026: the body lived in a 75vh scroll
panel. Stretching the viewport left a 25vh blank band; unclipping produced
3840 × 6926 with the footer directly under the last card, and a full-size
crop showed crisp text.
