---
name: rjv-test-types
description: Which kind of test proves a change - end-to-end flow, property test or differential test - and how to write each so an agent cannot fool it. Use when choosing or writing tests for a feature, an invariant (money, balances, parsing, retries) or a rewrite or migration that must keep behaviour. The phases around testing live in rjv-verify; criterion mapping in rjv-spec-driven.
---

# Test types that keep agents honest

A test the agent wrote with the same blind spots as its code proves
little. Pick the type whose inputs or oracle the agent did not choose.

## Pick the type

```text
Does a user or caller go through a flow (pages, API calls, a job)?
├── Yes → end-to-end test, always
└── No
    Is there a rule that must hold for every input?
    ├── Yes → property test
    └── No
        Is an old system doing the same job?
        ├── Yes → differential test
        └── No → unit test on the public function, real inputs
```

More than one branch can apply. A money feature usually gets an
end-to-end flow and a property test for its invariant.

## End-to-end

Pick this first when you can only afford one type. Either the whole
feature works or it does not, and a failure shows what broke.

- Drive the running app through the repo's `verify` skill
  (`rjv-verify-skill`), a browser, a simulator or an API harness.
- Assert on what the user sees or the caller receives, never on
  internal calls.
- Use the repo's feature map as the rubric: each flow with its path,
  selectors and expected result.

## Property

Write a statement that must never fail and let a library generate
thousands of inputs against it: fast-check (JS/TS), Hypothesis
(Python), proptest (Rust), PHP's Eris or a seeded loop.

| Property | Example |
|---|---|
| round trip | decode(encode(x)) equals x; parse(format(x)) equals x |
| invariant | a balance never goes negative; units times NAV equals amount, within rounding |
| idempotency | running a migration, retry or webhook twice equals running it once |
| equivalence | the optimised function equals the naive one |

Use it for every money rule and every parser. It is also the proof to
use when a spec has drifted from production behaviour.

## Differential

Run the old and new system on the same inputs and compare. Use it for
rewrites, migrations and framework swaps that must not change
behaviour.

- Inputs come from a generator or a sample of real traffic, never
  hand-picked.
- Normalise what does not matter: whitespace, key order, timestamps,
  generated IDs.
- Keep an approved-differences list, one line per difference with its
  reason. Any other difference is a bug.

## Failure modes

- **Flaky** tests teach agents to rerun instead of fix. Root-cause or
  delete (`rjv-verify` phase 3).
- **Slow** tests get run less often, so a failure cannot be traced to
  one change. Keep the per-edit set under a minute; heavy suites run
  once before the commit.

Done when each promised behaviour has a test of the type the tree
picked, and the test fails when the behaviour is broken.
