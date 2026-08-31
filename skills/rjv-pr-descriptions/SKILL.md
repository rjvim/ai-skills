---
name: rjv-pr-descriptions
description: "Use when writing, generating, updating, or fixing a GitHub PR description. Structures the body as journeys — one QA pass each, with grounded test steps, a screenshot, and ticks for what was actually run. Enforces hard caps; on update preserves checked checkboxes + author content; posts the result."
---

# PR Descriptions

Two people read this: a reviewer deciding if the change is right, and a QA
person deciding what to click. Write for the second one and the first is
served too.

Length is a defect, not thoroughness. An invented test step is worse than no
test step — it sends a human to check something that does not exist.

## Shape

The body is a list of journeys. A journey is one QA pass: one actor, one
path through the product, from where they start to something they can see.

Group by what a person would sit down and test as one sitting. Never by file,
never by commit, never by layer.

A fix with no journey to walk is still one section. Its first line says what
happens today, its second what happens after.

## The rule up top

When a single requirement, regulation, or constraint generates every journey
in the PR, state it before the first journey. Under five lines. It stops the
reader asking why there are five sections.

No rule to state, start at J1. Never write Overview, Summary, or Background.

## Budget

Hard caps. If the draft exceeds one, cut. Do not negotiate with yourself.

- 3 sentences of prose per journey.
- 4 checkboxes per journey.
- 1 screenshot per journey.
- 5 journeys maximum, and past 3 you need the rule up top to justify them.
- Whole body under 120 lines, images counted.

Anything that does not change what a user or a caller observes — refactors,
renames, dependency bumps, test-only files, config, formatting — gets **zero**
journeys. Collect them in one closing line: `Also: <thing>, <thing>.`

## Ticking

Tick `- [x]` for every step you performed and observed yourself. Leave
`- [ ]` for every step you did not run.

Never tick a step you did not perform. The ticks are the reason a QA person
trusts the rest of the body; one false tick and none of it counts.

A body that ships all unticked says nobody has run this. That is a legitimate
state. Say so rather than ticking to look finished.

## Screenshots

One per journey, immediately under its checkboxes, captioned with the journey
label. A journey with no screenshot reads as untested even when it is ticked.

Produce the image with your browser-automation tool — `agent-browser
screenshot` against the running app, checking the project's docs for local
login sequences — or use one the user provides. Then pass the absolute path
to the `rjv-github-image-upload` skill, which returns a
`github.com/user-attachments` URL ready to paste inline. Private-repo images
stay private.

## Notes for QA

A closing section, only for known gaps a QA person would otherwise raise as a
bug. Each line names the gap and why it stands.

Examples of what belongs: a string not yet translated, a channel switched off
pending an external registration, a limit that is not configurable yet.

Nothing to declare, no section. Never use it for a summary or for future work.

## Grounding

Every line traces to the diff. Before writing a line, name the file and hunk
it came from. If you cannot name one, delete the line.

Never write:

- A UI label, route, button, field, flag, error message, or endpoint whose
  literal text you have not seen in the diff or in a file you opened.
- An edge case the diff does not handle. No branch, no guard, no new test
  for it means it is not a case in this PR.
- "Confirm nothing else broke", "check for regressions", "verify existing
  behaviour still works". Not testable, not grounded.
- Hedges: should, might, presumably, likely, ensure, various.

If you cannot tell what the user actually sees, open the caller and the
template. Do not infer a screen from a function name.

## Voice

Plain English. Short sentences. One idea per line. Wrap the source around
72 characters so diffs stay readable.

Do not write:

- "X, not Y" or "not just X — it's Y" constructions.
- Counts that promise structure: "three things", "two problems here".
  State the things.
- CAPS or bold for emphasis. If it matters, it goes in the first sentence.
- Metaphors, em-dash asides, filler adjectives (simple, robust, seamless,
  comprehensive, significant, various).
- Process narration: "I checked", "after investigating", "it turns out".
  The PR describes the code, not the work of writing it.
- Drama: "this was badly broken", "worse than it looks". State the fact flat.

## Format

```
<the rule up top, if there is one — under five lines>

## J1 — <Actor> <does the thing>

<What happens on this path, and the constraint that shapes it.>

### What To Test
- [x] <Action verb: Open / Create / Submit / Uncheck…>
- [x] Confirm <observable outcome>.

![J1](https://github.com/user-attachments/assets/…)

## J2 — <Actor> <does the other thing>

…

## Notes for QA

- <known gap, and why it stands>

Also: <everything not user-visible, one line>
```

Rules:

- Journey headings name the actor and what they do. Plain English about
  behaviour. No code, no class names, no implementation.
- Action steps start with a verb. Check steps start with "Confirm".
- Happy path first. One edge case only if the diff explicitly handles it.
- No AI signature, attribution, or generator footer (`Generated by Claude`,
  `Generated by Codex`, model names, badges, or equivalents) unless the human
  explicitly asks for it.

## Workflow

### Writing a new description

1. Read the actual diff: `gh pr diff <number>`. For context (title, commits,
   existing body): `gh pr view <number> --json title,commits,body`.
2. Split the diff into user-visible behaviour and everything else.
3. Ask what rule or requirement drives the change. If one does, that is the
   rule up top, and the journeys fall out of it.
4. Group the user-visible behaviour into journeys, at most 5.
5. Walk each journey in the running app, screenshot it, tick what you saw.
6. Write the sections. Run the self-check below.
7. Post: `gh pr edit <number> --body-file -` (pipe the body in; inline
   `--body` breaks on multi-line and special characters).

### Self-check before posting

Answer each. Any "no" means fix it and re-check.

1. Can you point at the hunk behind every sentence and every checkbox?
2. Is every ticked box a step you actually performed?
3. Does every checkbox name something a person can click, run, or read, and
   then observe a result?
4. Does each journey stand alone as one QA sitting?
5. Is it inside every cap above?
6. Does every line tell the reviewer something the PR title did not?

### Updating an existing description

1. Fetch the current body first: `gh pr view <number> --json body`.
2. Preserve all `- [x]` checked checkboxes — never uncheck or remove them.
3. Preserve any content the author or a reviewer added by hand.
4. Preserve existing screenshots and their journey labels.
5. Merge in new changes. Prefer editing an existing journey over adding
   another one; the caps apply to the merged result too.
6. Only replace content you generated in a prior run.
7. Remove AI-attribution text left by a prior agent run; that is generated
   content, not authored content. Leave deliberate human attribution alone.
8. Post the merged result back.
