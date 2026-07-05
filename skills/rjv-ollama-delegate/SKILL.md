---
name: rjv-ollama-delegate
description: >
  Use when delegating mechanical coding/text work to LOCAL Ollama models
  (free, private, fast) — implementing a feature from a written spec,
  writing tests from a spec, classification, extraction, summarization,
  format conversion. Trigger phrases: "let qwen do it", "use the local
  model", "delegate to ollama", "spike this on a local model". NOT for
  code review, bug-hunting, or anything unverifiable — local models
  draft, the main agent reviews.
---

# Delegate to local Ollama

Pattern: **the local model types, you spec and review.** From a tight
spec, a mid-size local model (30B-class) produces ~90% production-quality
code at zero token cost — but it misses subtle bugs in its own and
others' code, so every output gets reviewed and tested by you before it
ships.

In a `rjv-gated-build` (see that skill), a local model can be cast as an
**Author** for spec-implementable functions — never as a **Reviewer**.

## How to run

Use the bundled runner (relative to this skill's directory), never
`ollama run` — the CLI emits TTY escape codes into its output even when
stdout is redirected:

```sh
<this-skill-dir>/scripts/ollama-chat.sh <model> <prompt-file> <out-file> [num_ctx=16384] [keep_alive=2h]
```

It calls the local HTTP API (`localhost:11434/api/chat`, non-streaming),
writes the raw response to `<out-file>`, and prints timing stats
(`wall / prompt tok/s / output tok/s / load`). Put prompt files in your
scratchpad/temp directory. `keep_alive=2h` keeps the model resident in
RAM so only the first call pays the load time; check residency with
`ollama ps`.

## Model choice

Check what's installed with `ollama list`, then pick by task:

| Class | Use for |
|---|---|
| Largest available (30B+) | code from spec, test-writing, harder extraction |
| Small/fast (7–9B) | classification, summaries, quick extraction |
| Coder variants | small code transforms |

Reference numbers from a verified spike (qwen3.6:35b on an Apple Silicon
Mac): ~60 tok/s generation, ~1000 tok/s prompt processing, ~5s load. A
paginated-API route from spec took 21s; a 300-line test suite took 61s.

## Writing the prompt (this is where quality is won)

The model sees ONLY the prompt file — no repo, no conversation. A good
delegation prompt contains:

1. **The task spec, decided by YOU first** — algorithms, edge cases, API
   shapes. Don't ask it to design; ask it to implement your design.
2. **Real code context inline** — the existing route/function/schema it
   must fit, plus file conventions (imports available, error shapes,
   validation style). Copy actual snippets, don't describe them.
3. **Exact output contract** — "Output ONLY the code, no markdown
   fences, no explanation." (Models ignore the fences rule ~50% of the
   time — strip fences on receipt rather than fighting it.)
4. For tests: the harness conventions verbatim (imports, seeding
   helpers, how to invoke the app) — with these, the spike model
   produced a 7-test suite that passed first run.

## Non-negotiable: verify the output yourself

- **Run it** — type-check, lint, and a test harness with known expected
  values. "Looks right" is not evidence: in the spike, an RFC 2047
  decoder that read cleanly failed 3/9 test vectors.
- **Review for subtle platform bugs** — the class local models miss:
  things needing runtime knowledge (e.g. SQLite LIKE needs an explicit
  `ESCAPE` clause; many ORMs' `like()` helpers don't emit one).
- **Never delegate review or bug-hunting** — asked to find a real bug in
  shipped code, the spike model said "no bugs".
- Note provenance in commits: "drafted by <model>, reviewed + hardened".

## Evidence (spike, 2026-07-05)

| Task | Result |
|---|---|
| RFC 2047 decoder from spec | 6/9 vectors — Q-decoding dropped literal chars |
| Bug-hunt on real shipped code | FAILED — "no bugs" on a real bug |
| Keyset-pagination API route from spec | ~90% in 21s; added an id tiebreaker unprompted; one LIKE-escape bug caught in review |
| Test suite for that route | 7/7 passed first run (lint nits only) |
