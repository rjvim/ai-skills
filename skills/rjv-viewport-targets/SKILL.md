---
name: rjv-viewport-targets
description: "Viewport targets for web UI: which screen sizes a design must work on, including short laptop windows (1366 × 768 gives a 1351 × 625 page), and how to adapt to height without touching tall screens. Use when designing or reviewing a hero, first screen, sign-in, app shell or dialog; when content is cut off on a laptop; when choosing breakpoints, a height media query or svh; or when listing the sizes to screenshot. Phone-only fixes (tap highlight, safe areas, input zoom) are emil-mobile-native."
---

# Viewport targets

Designers work on tall Retina screens. Many users do not. A design is checked against the sizes its audience
actually has, height included, and adapts to a short window without changing the tall one.

## 1. Write the target matrix

Before designing, write the matrix into the project's spec or rulebook. Start from this default and change rows
only with evidence about the audience (analytics, StatCounter for the market):

| Row | Viewport (CSS px) | Comes from |
|---|---|---|
| Phone | 390 × 844 | iPhone 12 to 16 |
| Short laptop | 1351 × 625 | 1366 × 768 laptop, Edge on Windows 11 |
| Short laptop | 1280 × 680 | 1280 × 800 laptop; also 1920 × 1080 at 150% scaling (about 1280 × 610) |
| Standard | 1440 × 900 (page about 1440 × 790) | MacBook Air |
| Tall | 1728 × 1000 | MacBook Pro 16, where most designs are drawn |

The viewport is the page area after the taskbar and browser bars, not the screen size. Windows display scaling
(125%, 150%) divides the screen by the scale. 1366 × 768 is about 18% of desktop screens in India and about 10%
worldwide (StatCounter, 2026-09).

Done when the matrix is written where every agent on the project reads it.

## 2. Decide what must fit

| Region | Rule |
|---|---|
| Composed first screen: hero, sign-in, onboarding step, app shell's first view, a dialog | fits every matrix row at scroll position zero: its heading, its line, its primary action and its key visual are fully visible |
| Everything else: sections, lists, tables, articles | scrolls; never forced to fit |

A cut-off hero reads as broken. A long page that scrolls reads as normal.
Done when each composed screen in the work has its required elements listed.

## 3. Adapt to height with one opt-in variant

Width breakpoints own layout. Height gets one named variant, `short`, that a design opts into:

```css
/* Tailwind v4: in the shared stylesheet every surface imports */
@custom-variant short (@media (min-width: 56.25rem) and (max-height: 50rem));
```

```css
/* Plain CSS equivalent */
@media (min-width: 56.25rem) and (max-height: 50rem) { .hero { padding-top: 1rem; } }
```

- **At least 900 wide and at most 800 tall.** Below 900 wide, designs are already stacked and scroll. 800 covers
  every short row above and leaves MacBook Pro sizes out.
- **Written as a maximum.** The tall layout stays the default; `short:` only tightens. A design with no `short:`
  styles renders identically.
- **In rem.** Media-query rem follows the browser's default font size, so a reader with 20px text gets the tighter
  layout sooner (the line moves to 1125 × 1000). Browser zoom resizes the viewport, so it follows with no extra code.
- Landscape tablets (1024 × 768) and landscape phones (932 × 430) also match. That is intended: each is a short
  window. Do not branch on device or user agent.

Use it in the design's own classes, against the breakpoint it conflicts with:

```tsx
<div className="xl:pt-15.5 short:pt-4">
<h1 className="xl:text-6xl short:text-5xl">
```

Cascade (Tailwind v4): `short:` is emitted after the width breakpoints at equal specificity, so it wins regardless
of class order. A `dark` variant built on `:is()` adds specificity: where a property is set under both, write
`dark:short:` or the dark value wins. Stacked `xl:short:` applies only when both hold.

**Type under `short`:** reading text (paragraphs, labels, buttons, navigation) never shrinks. Display headings may
step down one step on the type scale, and only after the height changes alone do not fit.

**Size a visual from the height left:** `100svh − header height − the design's own allowance`, with the allowance as
a named constant in that design, a floor, and the column width as a cap:

```tsx
supports-[height:100svh]:short:w-[min(100%-1.875rem,clamp(16rem,100svh-var(--header-space,6rem)-10rem,31.25rem))]
```

Keep the `supports-` guard. A declaration whose `var()` turns invalid is not dropped. It becomes `auto` at computed
time and loses the normal size. `svh` stays fixed while mobile bars move (`dvh` is for app shells; see
emil-mobile-native). Below the floor the page scrolls.

**Never scale the page to fit.** Do not set `zoom` or a smaller root font size on short windows. Both shrink reading
text on exactly the cheapest screens, and every design pays for one design's problem. (Measured: zoom 0.8 took body
text from 16 to 12.8px.)

Done when every composed screen fits every row, the tall row is unchanged, and no reading text changed size.

## 4. Check

Screenshot every matrix row, in light and dark, at scroll position zero. On a short row, check "fully visible" for
each required element:

1. its box, intersected with every ancestor that clips overflow, equals its own box;
2. it lies inside the viewport;
3. at nine points on a 3 × 3 grid across the box, the topmost element is the element or inside it, so a sticky
   header or overlay does not cover it.

Load fonts and images before measuring. Measure animated parts at their largest frame and again with reduced motion
on. In Playwright, set each row with `page.setViewportSize({ width, height })`. For Windows scaling and real Edge
chrome, check one short row on real Windows (BrowserStack or a laptop) once per design: emulation sets the viewport
but not the taskbar, scaling or font rendering.

Done when every row has a screenshot, each required element passes the three checks on the short rows, and the tall
row matches its before screenshot.

## Evidence

Imprint (MFStack), short-screens feature, 2026-09-25: the home hero was cut off at 1351 × 625 and 1280 × 680 on real
Windows 11 via BrowserStack while rendering normally at 1728 × 962. The `short` variant above, the type rule and the
height budget fixed it with nothing changed at 1728 × 1000. Spec and design:
`MFStack/imprint/_docs/features/short-screens/` (criteria SV1 to SV12).
