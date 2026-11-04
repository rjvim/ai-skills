# Testing a skill by running it

The testing branch of [`rjv-writing-skills`](SKILL.md). A skill is
instructions to other agents, so the only proof is observed
behaviour.

## Routing check (cheap, required for any changed description)

Takes about a minute and two cheap subagents. Run it before a changed
description ships.

1. Build the skill list before and after:
   ```sh
   S=<this skill's dir>/scripts/description-list.sh
   $S <skills-dir> <base-ref> > old.txt     # e.g. main
   $S <skills-dir>            > new.txt
   ```
2. Write 10 to 15 one-line user requests: for each changed skill, at
   least two that should fire it (one per trigger you cut or reworded)
   and one that should stay quiet.
3. Run each list through opencode (`rjv-opencode-agents`, text mode),
   which has no rjv skills installed, so the pasted list is the only
   one the router sees. A Claude subagent already carries the live
   skill list in its own context and would contaminate the old-list
   run. Brief: "Act as the skill router. For each request, name the
   skills you would load before acting, judging only from the list.
   One line per request."
4. Compare the two answers. Done when every should-fire request still
   picks its skill with the new list, and no should-stay-quiet request
   gained one. A miss means restore the trigger words for that case.

This checks the wording only. The activation test below checks a real
session.

## Activation test (does it fire?)

1. Make a throwaway git repo in the scratchpad, on a branch, shaped
   like the real case (a typo fix, a feature, a money change). One repo
   per session: parallel sessions in one repo see each other's edits
   and load skills for work they were never asked to do (2026-11-04).
2. Give a subagent a plain task prompt that never names the skill,
   plans or specs. A prompt that names the skill tests obedience to
   the prompt.
3. Check artifacts on disk (files created, commands run, the plan's
   fields). The agent's own report is a claim, not evidence.
4. Run at least one case where the skill should fire and one where it
   should stay quiet.
5. Cheapest real session: `claude -p "<task>" --model sonnet --max-turns 4
   --output-format stream-json --verbose`, then list the skills it
   loaded with `jq -r 'select(.type=="assistant") | .message.content[]? |
   select(.type=="tool_use" and .name=="Skill") | .input.skill'`. About
   $0.25 a session. Blocking Edit and Write does not stop edits through
   the shell, so keep the repo throwaway.

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
