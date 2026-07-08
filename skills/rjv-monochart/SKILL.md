---
name: rjv-monochart
description: "Draw a system as a terminal-native text diagram — boxes, rails, arrows — that lives in a README, code comment, or chat. Topology (things fan out) or flow (decisions, loops). Cheap, diffable, renders anywhere monospace does. Triggers: 'monochart', 'draw a flowchart', 'flowchart this', 'diagram it', 'draw the flow', 'ascii diagram', 'terminal diagram', 'box diagram', 'sketch the architecture', 'draw it out', 'show the topology'."
---

# monochart — draw system in text, in terminal

WHAT: box + arrow picture. pure text. no render tool. goes in README, comment, chat.
WHY: cheap. read at glance. git-diffable. renders anywhere monospace runs.
TWO KINDS: **topology** (boxes fan out, who talks to who) · **flow** (decisions, loops, steps).

## NEVER zero-shot. always 3 steps.

model draws ascii badly on first try — misaligns, wrong branches. so:

1. **PLAN** — pick kind. count boxes. pick ONE center column. list every branch + its label.
2. **DRAW** — one entry at top. flow top→down. hang children under parent. mirror branches.
3. **VERIFY** — run checklist below. fix. ONLY THEN show user. never show step-2 draft.

## charset — house style

- rails: `│ ─ ┌ ┐ └ ┘ ┬ ┴ ├ ┤ ┼`
- arrows: `▼ ▲ ▶ ◀`
- box: `┌──┐` / `│..│` / `└──┘`
- state markers (leaves only): 🟩 good/return · 🟦 write/side-effect · 🟥 stop/fail · 🟨 wait

RULE: box-drawing = rails. emoji = END-STATE only, 1 per leaf, add legend if >1 kind. never emoji mid-line.

## patterns (steal these)

fan-out — topology:
```
       FEED
         │
   ┌─────┴─────┐
   ▼           ▼
┌─────┐     ┌─────┐
│  A  │     │  B  │
└─────┘     └─────┘
```

decision — split, LABEL both sides:
```
  signal?
  ┌──┴──┐
no│     │yes
  ▼     ▼
 wait  BUY 🟦
```

loop-back — close the cycle, draw the return:
```
 SELL 🟩
   │
   └──▶ back to top
```

## example 1 — topology (two bots, one feed)
```
        📡 TICK FEED
             │
      ┌──────┴──────┐
      ▼             ▼
 ┌─────────┐   ┌─────────┐
 │  BOT 1  │   │  BOT 2  │
 │   M1    │   │  M1 M2  │
 └────┬────┘   └────┬────┘
      ▼             ▼
   BUY/SELL      BUY/SELL
```

## example 2 — flow (decision + marker + loop)
```
      🌐 REQUEST
          │
          ▼
   ┌─────────────┐
   │ API GATEWAY │
   └──────┬──────┘
       auth ok?
     ┌────┴────┐
     ▼         ▼
 ┌───────┐ ┌───────┐
 │ CACHE │ │  DB   │
 └───┬───┘ └───┬───┘
   hit?        │
  ┌──┴──┐      │
no│     │yes   │
  ▼     ▼      ▼
warm  RET 🟩  FETCH 🟦
 cache
```

## rules (this is the "one-shot with best practice")

- SYMMETRY: mirror branches. equal box width in a row.
- ALIGN: children hang under parent `┴` / center column. eyeball the columns line up.
- DECISION: word + `?` then split. LABEL every branch (yes/no, hit?/miss). no unlabeled fork.
- MARKERS: 🟩🟦🟥🟨 at terminal leaves only. not mid-flow.
- SIZE: keep < ~25 lines. bigger → split into 2 charts (coarse topology, then zoom one box). don't cram.
- ASCII fallback: target may break unicode/emoji (email, old term, some fonts)? switch to `+ - | v > <`, drop emoji, and SAY which mode you used.
- it's text: edit one line to change topology, commit, diff clean. that's the whole point.

bigger real example (topology + flow split into 2 charts): see `examples.md` in this skill dir.

## VERIFY checklist — run before showing

- [ ] exactly one entry node at top
- [ ] every arrow touches a box/node (nothing dangles)
- [ ] every decision fork has ALL branches labeled
- [ ] columns line up — children under parent
- [ ] emoji only at leaves; legend if >1 kind
- [ ] loops draw the return arrow (not just say it in words)
- [ ] < ~25 lines, else split into 2 charts
