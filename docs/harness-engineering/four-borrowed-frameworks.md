# Four business frameworks, read as harness mechanisms

Source: Ikana Business Review, *Mini Strategy Handbook for AI Founders*,
August 2026. Four frameworks aimed at founders. Three of them describe
problems the harness already has and has no vocabulary for.

Ranked by what they would actually change.

---

## 1. The prune ratchet — from the Inverted Launch

**Their claim.** The old risk was building the wrong feature. The new risk is
keeping the wrong tool too long. Ship a cohort, measure pull, cut what does not
earn its place. Arc had features used by 0.4% of daily actives; the company
killed the surface, rebuilt around what people used, and sold for $610M inside a
year.

**Why it lands here.** The tools guide already says composites earn their place
from observed use and the count is deliberately small. That is half the loop.
Nothing prunes. Every ratchet in the harness so far counts *bad* things and
refuses growth — lint errors, oversized files, unmerged overrides. None counts
*unused* things.

**The mechanism.** A tool ratchet, pointed the other way:

- Every tool declares a birth date.
- Metering already records calls per tool.
- A tool older than its grace window with no calls in the window fails the
  check. It is either exposed to nobody who wants it, or it should not exist.
- The remedy is deletion or a recorded exemption with a reason and a date.

**Why this is the strongest of the four.** Every tool definition costs input
tokens on every single turn, called or not. So a dead tool is not neutral — it
is a per-turn tax on every conversation, forever, paid by whoever owns the
inference. This is the only debt in the system that bills continuously and
compounds with usage. It is exactly the kind of thing that never gets cleaned up
without a check.

**Generalises past tools.** A guide whose check has never once fired is a
candidate for the same treatment: either the rule is already impossible to
break, or nobody is doing the thing it governs.

---

## 2. The commitment ladder, applied to rules — from the Signal Cost Principle

**Their claim.** A signal's strength is proportional to what it cost the sender.
A like costs a thumb-twitch; a renewal costs a year of trust. Founders optimise
cheap signals because cheap signals are easy to collect. Read every metric by
what it cost, not by how big it looks.

**Why it lands here.** This is the harness's founding claim in someone else's
words. "A component keeps working when the model ignores it" is the same
sentence as "read the signal by what it cost to produce". But the harness has no
way to *say* how strongly a given rule is enforced, so every rule looks equal in
the index and only the code knows the difference.

**The mechanism.** Give every rule a rung, and record it next to the rule:

| Rung | Enforcement | What it costs to violate |
|---|---|---|
| 5 | Refused by a git hook or a production guard | Impossible without deliberate override |
| 4 | Fails CI | A red branch |
| 3 | Fails the local edit gate | A failed turn |
| 2 | Ratcheted — cannot grow | Nothing today, blocked tomorrow |
| 1 | Prose in a guide | Nothing |

Then one check: **a rule may not sit below the rung its blast radius
demands.** Anything touching production data, money, or a customer's tenancy is
rung 5 or it is not a rule. Anything cosmetic can live at 2.

**What this buys.** The guides index becomes readable at a glance — which of
these actually stop me, and which are advice. Today they look identical, which
is exactly the "cheap signal read as expensive" failure the framework describes.
And a rule that quietly slid down a rung because its check was disabled becomes
visible.

---

## 3. Contribution per call — from the Contribution Factor

**Their claim.** Contribution Factor = price − variable cost per order. Negative
means the unit economics are broken and scaling makes it worse. Positive but not
covering fixed costs means the business is sub-scale and should spend *more*.
Most founders cut when they should spend, because they classify performance
marketing as overhead rather than as a variable cost.

**Why it lands here.** The harness has one criterion it has never been able to
close: runaway cost, because cost lives in the agent runtime and not the
repository. The framework reframes it. The question was never "what did this
cost". It is "what does one call contribute".

**The mechanism.** Per tool, per surface:

```
contribution = price of the call − (invocation + D1 reads + inference + egress)
```

Every term is already available. Metering records the call. AI Gateway returns
provider token counts on the response. Analytics Engine holds the rest.

**What it decides.**

- **Negative** on a tool → do not promote it, do not expose it more widely.
  Volume makes it worse.
- **Positive, low volume** → expose it further. This is the case founders get
  wrong, and it is the case a metering dashboard alone will never surface,
  because it looks like an unpopular tool rather than an underexposed one.
- **DataZero is the pure case.** Zero variable cost per read, so its
  contribution is bounded below by zero at any volume. That is the whole
  argument for keeping a Worker out of its path, restated in one number.

This is also the honest answer to the open cost criterion: not an alert on a
threshold, but a number per tool that says expose more or expose less.

---

## 4. The scar test, applied to guides — from The Founder Is the Channel

**Their claim.** Polish is free now, so polish signals nothing. What is still
expensive to fake is a specific person with a specific scar. Their test: artifact
not announcement, scar not slogan, contrarian not consensus, repeated not
one-off.

**Why it lands here.** This is already the house style and nobody named it. The
guides that work are the ones carrying a scar: a three-day NAV blackout, a
landing page that reached 884 lines, a nested config that broke lint in a live
checkout, an override that rendered in the DOM and did nothing. The guides that
would rot are the ones that would read like policy.

**The mechanism, and its limit.** A check can assert a guide has a "why this is
hidden" section and names either an incident date or a measured number. It
cannot assert the scar is real. So: rung 2 at best, and worth having anyway —
it is the difference between a rule someone will follow and a rule someone will
skim.

---

## Not adopted

**The founder-as-channel argument itself** is about distribution, not
engineering. Interesting, out of scope.

**"Launch wide, cut later" as a build strategy.** The harness exists partly to
stop unbounded work. Shipping a cohort of half-built things to see which sticks
is right for a product surface and wrong for a data pipeline that has already
had one three-day outage. The pruning half of ILA generalises. The launching
half does not.
