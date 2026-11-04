# Testing a skill by running it

The testing branch of [`rjv-writing-skills`](SKILL.md). A skill is
instructions to other agents, so the only proof is observed
behaviour.

## Activation test (does it fire?)

1. Make a throwaway git repo in the scratchpad, on a branch, shaped
   like the real case (a typo fix, a feature, a money change).
2. Give a subagent a plain task prompt that never names the skill,
   plans or specs. A prompt that names the skill tests obedience to
   the prompt.
3. Check artifacts on disk (files created, commands run, the plan's
   fields). The agent's own report is a claim, not evidence.
4. Run at least one case where the skill should fire and one where it
   should stay quiet.

## Behaviour test (does a line matter?)

Run the same task with the line and without it, and compare. If the
output does not change, the line is a no-op; delete it. If a leading
word is too weak to change the output, try a stronger word.

Read the reasoning trace: the leading words you chose should appear
in it.

## Record

Write the date, model, tasks and outcome in the skill's `EVIDENCE.md`
when the result changed the skill. Example from 2026-07-28: three
tiers (trivial fix, real feature, money change) landed on the
expected build modes; the trivial fix skipped its plan file.

Re-run the activation test after any change to a description or an
activation gate.
