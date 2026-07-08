# monochart — worked examples

Fuller reference charts. Not loaded by default — read when you want a
bigger, real example than the two inline in `SKILL.md`.

## split rule in action — a system too big for one chart

A tick-feed trading system is **topology + per-model loop** — over the
~25-line ceiling combined. So it splits into two charts: a coarse
topology, then a zoom into one repeating unit.

### Chart 1 — topology (who runs what)
```
             📡 TICK FEED
                  │  every tick
        ┌─────────┴─────────┐
        ▼                   ▼
   ┌─────────┐         ┌─────────┐
   │  BOT 1  │         │  BOT 2  │
   └────┬────┘         └────┬────┘
        ▼                ┌──┴──┐
       M1                ▼     ▼
     (slot)             M1     M2
                      (slot) (slot)
        → 3 independent slots, each holds ≤1 position
```

### Chart 2 — per-model loop (any one slot, every tick)
```
        ┌───────────▶ TICK
        │              │
        │              ▼
        │         holding a position?
        │          ┌────┴────┐
        │        no│         │yes
        │          ▼         ▼
        │       signal?    up ≥ 1%?
        │       ┌──┴──┐    ┌──┴──┐
        │     no│     │yes no│    │yes
        │       ▼     ▼    ▼     ▼
        │      wait  buy   keep  sell 🟩
        │      🟨    call🟦 holding now flat
        │            now holding
        │       │     │    │     │
        └───────┴─────┴────┴─────┘
                   next tick
```
legend: 🟦 open (buy call at market) · 🟩 close (sell at +1%) · 🟨 idle

Note what the chart makes obvious: the `hold` branch has **no downside
exit** (no stop-loss) — the diagram surfaces the risk asymmetry a prose
description would bury.

## why two charts, not one

- topology answers *who talks to who* — flat, no time.
- flow answers *what one unit does over time* — decisions, loops.
- cramming both = a wall of lines nobody reads. split, and each chart
  does one job at a glance. that's the SIZE rule paying off.
