---
name: rjv-pr-descriptions
description: Use when writing, generating, updating, or fixing a GitHub PR or GitLab MR description. Splits the body into what a tester can check in the UI alone and what needs code or environment setup; each part is written from the tester's view, with grounded steps, a screenshot or a command's output, and ticks for what was actually run. Enforces hard caps; on update preserves checked checkboxes + author content; posts the result.
---

# PR Descriptions

Two people read this: a reviewer deciding if the change is right, and a
tester deciding what to check. Write for the tester and the reviewer is
served too. In MFStack work the tester clicks through the product and does
not read code.

Length is a defect, not thoroughness. An invented test step is worse than no
test step — it sends a human to check something that does not exist.

## Shape

The body always has these two sections, in this order, both present:

1. **Test in the UI** — what a tester can check by clicking through the
   running product, with no code, console, database or config change.
2. **Needs code or environment setup** — what can only be checked by
   changing config, an env var or a flag, seeding data, running tinker or a
   command, calling an API directly, or reading logs or the database.

When a section has nothing, it holds one line: `None.` Never drop a heading.
The tester must see at a glance which part they can do alone.

Each section is a list of items. An item is one test sitting: one actor, one
path, from where they start to something they can see or read.

- In the UI section an item is a journey: `J1`, `J2`, ...
- In the setup section an item is a check: `S1`, `S2`, ...

Group by what a person would sit down and test as one sitting. Never by
file, never by commit, never by layer.

A check's first line says what happens today, its second what happens after.
Then the setup, then the command or call and the output that proves it.

## The rule up top

When a single requirement, regulation, or constraint generates every item
in the PR, state it before the first section. Under five lines.

No rule to state, start at the first section. Never write Overview, Summary,
or Background.

## Budget

Hard caps. If the draft exceeds one, cut. Do not negotiate with yourself.

- 3 sentences of prose per item.
- 4 checkboxes per item. Ticked boxes kept from an earlier version do not
  count against this cap.
- 1 screenshot per journey; 1 output block per check.
- 5 items in total across both sections, and past 3 you need the rule up top.
- Whole body under 120 lines, images counted.

Anything that does not change what a user or a caller observes — refactors,
renames, dependency bumps, test-only files, config, formatting — gets **zero**
items. Collect them in one closing line: `Also: <thing>, <thing>.`

## Ticking

Tick `- [x]` for every step you performed and observed yourself. Leave
`- [ ]` for every step you did not run.

Never tick a step you did not perform. The ticks are the reason a tester
trusts the rest of the body; one false tick and none of it counts.

A body that ships all unticked says nobody has run this. That is a legitimate
state. Say so rather than ticking to look finished.

## Evidence

**Journeys get a screenshot**, immediately under the checkboxes, captioned
with the journey label. Take it with your browser-automation tool —
`agent-browser screenshot` against the running app, checking the project's
docs for local login — or use one the user provides.

**Open every screenshot for the user** with `open -a Preview <absolute path>`
as soon as you take it, and say so. An image you only read yourself is one
the user never saw.

Then pass the absolute path to `rjv-github-image-upload`, which returns a
`github.com/user-attachments` URL ready to paste inline.

**Checks get the output that proves them**: the command or API call, and the
few lines of its output that show the result, in a code block. No
screenshot needed. Never paste secrets, tokens or customer data.

## Notes for QA

A closing section, only for known gaps a tester would otherwise raise as a
bug. Each line names the gap and why it stands.

Nothing to declare, no section. Never use it for a summary or for future
work.

## Grounding

Every line traces to the diff. Before writing a line, name the file and hunk
it came from. If you cannot name one, delete the line.

Never write:

- A UI label, route, button, field, flag, error message, env var, command or
  endpoint whose literal text you have not seen in the diff or in a file you
  opened.
- An edge case the diff does not handle. No branch, no guard, no new test
  for it means it is not a case in this PR.
- "Confirm nothing else broke", "check for regressions", "verify existing
  behaviour still works". Not testable, not grounded.
- Hedges: should, might, presumably, likely, ensure, various.

If you cannot tell what the user actually sees, open the caller and the
template. Do not infer a screen from a function name.

## Voice

Plain English. Short sentences. One idea per line. Write from the tester's
view: what they do, then what they see. Wrap the source around 72
characters so diffs stay readable.

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

## Test in the UI

### J1 — <Actor> <does the thing>

<What the tester does and sees on this path.>

- [x] <Action verb: Open / Create / Submit / Uncheck…>
- [x] Confirm <observable outcome>.

![J1](https://github.com/user-attachments/assets/…)

## Needs code or environment setup

### S1 — <Actor or caller> <does the thing>

Today: <what happens now>
After: <what happens with this PR>
Setup: <env var, flag, seed, tinker line, or config, exactly as in the diff>

- [ ] Run <command or call>.
- [ ] Confirm <the output line that proves it>.

    <the few output lines that prove it>

## Notes for QA

- <known gap, and why it stands>

Also: <everything not user-visible, one line>
```

When a section is empty:

```
## Needs code or environment setup

None.
```

Rules:

- Item headings name the actor and what they do. Plain English about
  behaviour. No code, no class names, no implementation.
- Action steps start with a verb. Check steps start with "Confirm".
- Happy path first. One edge case only if the diff explicitly handles it.
- If a path needs setup only to get started and is then clicked through,
  it belongs in the setup section, with the setup named first.
- No AI signature, attribution, or generator footer (`Generated by Claude`,
  `Generated by Codex`, model names, badges, or equivalents) unless the human
  explicitly asks for it.

## Workflow

### Writing a new description

1. Read the actual diff: `gh pr diff <number>`. For context (title, commits,
   existing body): `gh pr view <number> --json title,commits,body`.
2. Split the diff into user-visible behaviour and everything else.
3. Sort the user-visible behaviour: testable in the UI alone, or needing
   code or environment setup.
4. Work out what rule or requirement drives the change. If one does, that is
   the rule up top.
5. Group each side into items, at most 5 in total.
6. Walk each journey in the running app, screenshot it, open the screenshot
   in Preview, tick what you saw. Run each check you can, and paste its
   output.
7. Write the sections. Run the self-check below.
8. Post: `gh pr edit <number> --body-file -` (pipe the body in; inline
   `--body` breaks on multi-line and special characters). On GitLab,
   `glab mr update <number> --description "$(cat body.md)"`.

### Self-check before posting

Answer each. Any "no" means fix it and re-check.

1. Are both section headings present, with `None.` under an empty one?
2. Is every UI journey doable with no code, console, database or config?
3. Can you point at the hunk behind every sentence and every checkbox?
4. Is every ticked box a step you actually performed?
5. Does every checkbox name something a person can click, run, or read, and
   then observe a result?
6. Is it inside every cap above?
7. Does every line tell the reviewer something the PR title did not?

### Updating an existing description

1. Fetch the current body first: `gh pr view <number> --json body`.
2. Preserve all `- [x]` checked checkboxes — never uncheck or remove them.
   Move them into the right section if the body predates the two-section
   shape.
3. Preserve any content the author or a reviewer added by hand.
4. Preserve existing screenshots and their item labels.
5. Merge in new changes. Prefer editing an existing item over adding
   another one; the caps apply to the merged result too.
6. Only replace content you generated in a prior run.
7. Remove AI-attribution text left by a prior agent run; that is generated
   content, not authored content. Leave deliberate human attribution alone.
8. Post the merged result back.

## Loading this skill

`hooks/pr-body-hook.sh` is a Claude Code PreToolUse hook on `Bash`. When a
command creates or edits a PR or MR, it reminds the agent to load this
skill first. Register it in `settings.json` under `hooks.PreToolUse` with
matcher `Bash`.
