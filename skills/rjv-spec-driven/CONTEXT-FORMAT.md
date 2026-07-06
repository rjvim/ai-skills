# CONTEXT.md format — the glossary

The project's ubiquitous language. A glossary and NOTHING else — no
implementation, no spec, no scratch. Adapted from mattpocock/skills `domain-modeling`.

## Structure

```md
# {Context name}

{One or two sentences: what this context is and why it exists.}

## Language

**Order**:
A customer's request to buy, from placement to fulfilment.
_Avoid_: Purchase, transaction

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- **Be opinionated.** Multiple words for one concept → pick the best, list the rest
  under `_Avoid_`.
- **Tight definitions.** One or two sentences. Define what it IS, not what it does.
- **Only project-specific terms.** General programming concepts (timeout, retry,
  cache) don't belong even if used heavily. Ask: unique to this domain, or generic?
  Only the former.
- **Group under subheadings** when natural clusters emerge; a flat list is fine
  otherwise.

## Single vs multi-context (big systems)

- **Single context (most repos):** one `CONTEXT.md` at the root.
- **Multiple contexts:** a `CONTEXT-MAP.md` at the root indexes them and how they
  relate; each context has its own `CONTEXT.md` in its area:

```md
# Context Map

## Contexts
- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks orders
- [Billing](./src/billing/CONTEXT.md) — invoices and payments

## Relationships
- **Ordering → Billing**: Ordering emits `OrderPlaced`; Billing consumes it to invoice.
- Shared types: `CustomerId`, `Money`.
```

The map is the index — read it, then open the ONE context you need. Create files
lazily: first term resolved → create `CONTEXT.md`; second context needed → add
`CONTEXT-MAP.md`.

## The active discipline (not just reading)

Consuming the glossary for vocabulary is a one-line habit any skill does. The
*discipline* is changing it as you design:

- **Challenge conflicts.** A term used against its glossary meaning → call it out.
- **Sharpen fuzzy terms.** "account" → "do you mean Customer or User? Different things."
- **Cross-reference code.** Code contradicts a stated term → surface it, reality wins.
- **Update inline, in real time.** Term resolved → write it now (a branch commit),
  don't batch. Same real-time promotion rule as the rest of `rjv-spec-driven`.
