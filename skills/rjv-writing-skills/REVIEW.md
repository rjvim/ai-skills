# Reviewing and improving existing skills

The review branch of [`rjv-writing-skills`](SKILL.md). Use it on this
repo's `rjv-*` skills or on any project's internal skills
(`.claude/skills/`, `.agents/skills/`, `skills/`, `AGENTS.md`,
`CLAUDE.md`).

## 1. Inventory the set

List every skill with its line count, its trigger (model- or
user-invoked) and the skills it points at. Then mark:

- **Owners**: for each rule that appears in more than one skill, which
  skill owns it. The others get a one-line pointer.
- **Overlap**: two descriptions that fire on the same case. Each case
  gets one owner; the other description names it.
- **Conflicts**: two lines telling an agent opposite things. The
  user's global instructions win; otherwise ask the user once.

Done when every repeated rule has one named owner.

## 2. Check each skill against SKILL.md steps 1 to 5

For each skill, record findings under the five headings: trigger,
structure, steering, prune, prose. A finding names the line and what
an agent does wrong because of it. "Could be clearer" is not a
finding.

Inventory work (counting lines, listing hedge words, em-dashes,
negations, duplicated sentences) is mechanical; hand it to the
cheapest worker. Deciding what to cut is judgment.

## 3. Edit

Order: fix conflicts, then structure (move branch-only reference to
sibling files), then steering, then prune, then prose.

Keep without exception:

- every measured number, date, command, path and verified failure;
  move long ones to `EVIDENCE.md` rather than deleting them;
- every guardrail sentence, word for word (SKILL.md §3: merge, push,
  deploy, delete, publish, spend, send, permissions, secrets,
  production). Adding a positive target after it is allowed; rewording
  it is not;
- skill names, file names that other skills or hooks point at, and
  script behaviour.

Change a description only when step 2 found a trigger problem, and
then run the routing check in `TESTING.md` before the change ships.
When reviewers work in parallel, they propose description changes in
their report and leave the frontmatter alone; the orchestrator applies
them and runs one routing check for the whole set. Descriptions decide
activation, and a tidier description can stop a skill firing.

Leave alone any rule the user has marked as theirs to evolve. Raise
open decisions instead of resolving them in the text.

Done with editing when the guardrail check finds nothing missing:

```sh
python3 <this skill's dir>/scripts/guardrail-check.py <base-ref> <skill dirs>
```

It lists every guardrail sentence (a ban word plus a risky action) that
was at the base ref and is not word for word in the skill's files now,
ignoring line wraps. Put each one back, or say in the report why the
new wording keeps its force. On 2026-11-04 it found 8 weakened
guardrails across this repo's skills after a review pass.

## 4. Report

Per skill: lines before and after, what changed in one line each,
and open questions for the user. Then the repo-level changes
(README table, pointers, hooks).

Done when: every skill has been checked, every edit keeps the facts
above, and descriptions that changed have a test run behind them.
