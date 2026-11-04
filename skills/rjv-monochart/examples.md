# monochart: worked examples

Fuller reference charts. Read this file when you want a bigger, real
example than the two inline in `SKILL.md`.

## split rule in action: a system too big for one chart

A tick-feed trading system is **topology + per-model loop**. Combined,
they pass the 25-line ceiling. So it splits into two charts: a coarse
topology, then a zoom into one repeating unit.

### Chart 1: topology (who runs what)
```
             📡 TICK FEED
                  │  every tick
        ┌─────────┴─────────┐
        ▼                   ▼
   ┌─────────┐         ┌─────────┐
   │  BOT 1  │         │  BOT 2  │
   └────┬────┘         └────┬────┘
        ▼              ┌────┴────┐
     model 1           ▼         ▼
                    model 1   model 2
   3 model runs, each holds at most one position
```

### Chart 2: per-model loop (any one model run, every tick)
```
        ┌──────────────▶ TICK
        │                 │
        │                 ▼
        │        holding a position?
        │          ┌──────┴──────┐
        │        no│             │yes
        │          ▼             ▼
        │       signal?      up ≥ 1%?
        │       ┌──┴──┐       ┌──┴──┐
        │     no│     │yes  no│     │yes
        │       ▼     ▼       ▼     ▼
        │      wait  buy     keep  sell 🟩
        │       🟨   call🟦   holding now flat
        │        now holding
        │       │     │       │     │
        └───────┴─────┴───────┴─────┘
                      next tick
```
legend: 🟦 open (buy call at market) · 🟩 close (sell at +1%) · 🟨 idle

Note what the chart makes obvious: the `hold` branch has **no downside
exit** (no stop-loss). The diagram surfaces the risk asymmetry a prose
description would bury.

## why split into two charts

- topology answers *who talks to who*: flat, no time.
- flow answers *what one unit does over time*: decisions, loops.
- cramming both = a wall of lines nobody reads. split, and each chart
  does one job at a glance. that's the SIZE rule paying off.
