---
name: rjv-writing-skills
description: "Write, review or prune instructions that agents read: a skill (SKILL.md and its sibling files), an AGENTS.md or CLAUDE.md, or any doc an agent reaches through a pointer. Use when creating a skill, editing one, auditing a repo's internal skills, or when an agent keeps ignoring what a skill says. Owns trigger choice, steps and reference layout, leading words, completion criteria, pruning, house prose, and testing a skill by running it."
---

# Writing skills agents obey

A skill is a hypothesis about agent behaviour. It makes the agent walk
the same process every run; the outputs still differ because every
context differs. Write it for a fast colleague who has never seen this
repo, and judge it only by what agents do after reading it.

Pick the branch:

- **Writing a new skill or doc**: walk steps 1 to 6 below.
- **Reviewing or improving existing skills** (this repo or another
  project's internal skills): read [`REVIEW.md`](REVIEW.md), which
  applies these same steps as a checklist.
- **Proving a skill works**: read [`TESTING.md`](TESTING.md).

## 1. Trigger: who invokes it

The description is a context pointer. It sits in every session, so
each word costs on every turn, and its wording decides when the agent
opens the skill.

| The skill must be reached... | Make it |
|---|---|
| by the agent on its own, or by another skill | model-invoked: keep a model-facing description |
| only when the user types its name | user-invoked: `disable-model-invocation: true`, one-line human description |

Model-invoked skills cost context load and can be skipped even when
they fit. User-invoked skills cost the user's memory. Choose per skill,
and say which in one line of the commit.

A model-invoked description:

- opens with what the material is, using the leading word the user
  actually types (`plan`, `review`, `spec`);
- lists one trigger per distinct case; synonyms for the same case are
  one trigger;
- says where a sibling skill owns the neighbouring case
  ("in Codex use rjv-subagents-codex");
- stays under about 80 words.

A must-have skill that agents skip has a weak pointer. Sharpen the
description first; paste its content into always-loaded instructions
only if a test run still misses it.

## 2. Structure: steps and reference

Every skill is made of **steps** (what the agent does, in order) and
**reference** (rules, definitions, templates consulted while doing
it). Place each piece on this ladder:

1. step in SKILL.md
2. reference in SKILL.md, used by every branch
3. reference in a sibling file, reached by a pointer line, used by
   some branches only

The test for rung 3 is branching: inline what every run needs, move
behind a pointer what only some runs reach. A pointer line names the
file and the condition: "When the change touches money, read
`CASTING.md`." Keep a concept's definition, rules and caveats under one
heading so reading one part brings its neighbours.

SKILL.md stays under about 250 lines. Past that, find the branch that
should move out.

## 3. Steering

**Write a decision procedure.** A table or tree the agent walks gives
the same reasoning every run. "Use judgement" gives whatever the model
picks that day.

**Use leading words.** A leading word is a short term the model already
knows from pretraining (`vertical slice`, `red`, `tracer bullet`) that
carries a whole behaviour. Pick one per behaviour, repeat that exact
token through the skill, and check it shows up in the agent's
reasoning. If behaviour stays wrong, try a stronger word before adding
sentences. A word you coin yourself recruits no priors, so define it
once, where it is first used.

**State the target behaviour.** A ban puts the banned behaviour into
context. Write what to do ("write one-line comments"). Keep a
prohibition only as a hard guardrail you cannot phrase positively, and
pair it with the positive target.

**Use numbers and absolutes.** "Under 300 ms", "at most 5 running",
"always ask once". Hedge words (reasonably, where appropriate, try to)
change nothing; delete them or replace them with a number.

**Give the reason where it is not obvious.** One clause of why lets
the agent extend a rule to cases you never wrote down. Skip the reason
when the rule explains itself.

**End every step on a completion criterion.** The agent must be able
to tell done from not done ("every changed model accounted for",
"the test goes red on the bug"). A vague bound invites rushing to the
next step. Sharpen the bound first. Only if the agent still rushes,
split the later steps into a separate skill or a subagent hand-off;
inside one context the later steps stay visible and the split does
nothing.

## 4. Prune

Go sentence by sentence and ask: does the agent act differently with
this line than without it? Delete whole sentences that fail.

- **No-ops**: the model already does it by default (write a decent
  commit message, read the file before editing it).
- **Duplication**: one meaning lives in one place. Across skills, one
  skill owns a rule and the others point to it. The user's global
  instructions outrank every skill.
- **Cache of the environment**: do not restate what `--help`,
  `package.json`, config or the directory listing shows. Do write what
  no file confesses: the unwritten convention, the gotcha, the reason.
- **Sediment**: stale layers others added and nobody removed. Move
  branch-only material to its branch file; delete what is stale.
- **History and motivation**: how the rule came about goes in the
  commit or `EVIDENCE.md`, unless the agent needs it to apply the rule.

## 5. House prose (Rajiv's repos)

Agents read skills, so write them in the register they act on fastest.

- Imperatives and facts. One idea per sentence. Short paragraphs.
- Plain English. Metaphors, em-dash asides and filler adjectives go.
- Avoid the "X, not Y" frame; state X.
- Bold only the rule an agent must not miss, a few per file.
- Name things the way the user says them. A tool noun or ID gets its
  plain meaning beside it once.
- Evidence over aspiration: when a rule came from a real failure or a
  measured run, keep the number and the date (in `EVIDENCE.md` if
  long). Never invent a measurement.
- Works in Claude Code and Codex unless the skill says which harness
  it binds. Harness-specific mechanics sit in their own section.
- No model provenance: no "generated by" lines or AI trailers.

## 6. Ship

1. Run the skill (see `TESTING.md`). A skill untested is a draft.
2. Update every place that shows the skill: its own files, the repo
   README table, other skills that point at it, hooks that name it.
3. For this repo, commit on a branch, push, then install with
   `npx -y skills@latest add rjvim/ai-skills -g -a claude-code -a codex -y`.
   A new skill appears only in a fresh session.

Done when: the test run shows the intended behaviour, and every place
that names the skill says the same thing.

## Related

- `rjv-subagents-claude` §10 owns the rule that global instructions
  stay small and conflict-free; this skill applies it to skills.
- Draws on Matt Pocock's `writing-for-agents` skill (MIT,
  github.com/mattpocock/skills) and Emil Kowalski's writing-skills
  notes.
