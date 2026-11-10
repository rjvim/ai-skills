---
name: rjv-monochart
description: "Draw a system as a terminal-native text diagram — boxes, rails, arrows — that lives in a README, code comment, or chat. Topology (things fan out) or flow (decisions, loops). Cheap, diffable, renders anywhere monospace does. Triggers: 'monochart', 'draw a flowchart', 'flowchart this', 'diagram it', 'draw the flow', 'ascii diagram', 'terminal diagram', 'box diagram', 'sketch the architecture', 'draw it out', 'show the topology'."
---

# monochart: draw a system in text, in the terminal

WHAT: box + arrow picture. pure text. no render tool. goes in README, comment, chat.
WHY: cheap. read at glance. git-diffable. renders anywhere monospace runs.
TWO KINDS: **topology** (boxes fan out, who talks to who) · **flow** (decisions, loops, steps).

> **VOICE: read this first.** This file is written terse to stay small. The
> diagram you draw is written in plain words for a stranger: `return
> response`, not `RET`; `buy call option`, not `BUY CE`; `holds one
> position`, not `slot`. Spell out every abbreviation and every piece of
> internal jargon, so nothing needs a decoder. Terse file, readable diagram.

## always 3 steps: PLAN, DRAW, VERIFY

model draws ascii badly on first try: misaligns, wrong branches. so:

1. **PLAN**: pick kind. count boxes. pick ONE center column. list every branch + its label.
2. **DRAW**: one entry at top. flow top→down. hang children under parent. mirror branches.
3. **VERIFY**: run checklist below. fix. show user only the chart that passes every check.

## charset: house style

- rails: `│ ─ ┌ ┐ └ ┘ ┬ ┴ ├ ┤ ┼`
- arrows: `▼ ▲ ▶ ◀`
- box: `┌──┐` / `│..│` / `└──┘`
- state markers (leaves only): 🟩 good/return · 🟦 write/side-effect · 🟥 stop/fail · 🟨 wait

RULE: box-drawing = rails. emoji = END-STATE only, 1 per terminal leaf, add legend if >1 kind (a loop's last node before its return counts as a leaf).

## patterns (steal these)

fan-out (topology):
```
       FEED
         │
   ┌─────┴─────┐
   ▼           ▼
┌─────┐     ┌─────┐
│  A  │     │  B  │
└─────┘     └─────┘
```

decision: split, label both sides:
```
  signal?
  ┌──┴──┐
no│     │yes
  ▼     ▼
 wait  BUY 🟦
```

loop-back: close the cycle, draw the return:
```
 SELL 🟩
   │
   └──▶ back to top
```

## example 1: topology (two bots, one feed)
```
          📡 TICK FEED
                 │
        ┌────────┴────────┐
        ▼                 ▼
 ┌─────────────┐   ┌─────────────┐
 │    BOT 1    │   │    BOT 2    │
 │   model 1   │   │ models 1, 2 │
 └──────┬──────┘   └──────┬──────┘
        ▼                 ▼
    BUY/SELL          BUY/SELL
```

## example 2: flow (decision + marker + loop)
```
      🌐 REQUEST
          │
          ▼
   ┌─────────────┐
   │ API GATEWAY │
   └──────┬──────┘
       auth ok?
     ┌────┴────┐
  yes│         │no
     ▼         ▼
 ┌───────┐   reject
 │ CACHE │   401 🟥
 └───┬───┘
 cache hit?
  ┌──┴──────┐
no│         │yes
  ▼         ▼
fetch DB,  return
cache it🟦 cached🟩

🟩 return · 🟦 write · 🟥 stop
```

## rules (this is the "one-shot with best practice")

- LABELS: plain words a stranger reads without asking (see VOICE).
- SYMMETRY: mirror branches. equal box width in a row.
- ALIGN: children hang under parent `┴` / center column.
- DECISION: word + `?` then split. label every branch (yes/no, hit?/miss).
- SIZE: at most 25 lines. bigger → split into 2 charts: coarse topology, then zoom one box. bigger real example of the split: `examples.md` in this skill dir.
- ASCII fallback: target may break unicode/emoji (email, old term, some fonts)? switch to `+ - | v > <`, drop emoji, and SAY which mode you used.

## VERIFY checklist: run before showing

- [ ] every label is plain words a stranger can read (no `RET`, `CE`, `slot`)
- [ ] exactly one entry node at top
- [ ] every arrow touches a box/node (nothing dangles)
- [ ] every decision fork has ALL branches labeled
- [ ] each child's `▼` sits in the same column as its parent's `┬` / `┴`
- [ ] emoji only at terminal leaves; legend if >1 kind
- [ ] every loop draws its return arrow as rails, in addition to any words
- [ ] at most 25 lines, else split into 2 charts
