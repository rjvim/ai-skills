# Harness engineering

Notes from installing an agent harness on a real repository, written to be
reusable on the next one.

**The claim these are built on:** a harness component keeps working when the
model ignores it. Prose does not. An exit code does.

Six layers. Guides are feedforward — what the agent reads. Sensors, permissions
and observability are enforcement — what happens whether it reads or not. Memory
and the loop sit between.

| File | What it is |
|---|---|
| [checklist.md](./checklist.md) | The ordered sequence for a new repository |
| [lessons.md](./lessons.md) | Why each step is shaped the way it is, and the traps in order |
| [portable-extensions.md](./portable-extensions.md) | Three extensions for once every rule is enforced |
| [four-borrowed-frameworks.md](./four-borrowed-frameworks.md) | Where those extensions came from |

Start with `checklist.md`. Read `lessons.md` before the first commit.

## The one rule that reorganised everything

A test that fails when any guide has no check. Three lines of assertion.

After it, every rule arrives with its enforcement attached, because there is no
longer a way to land prose. Before it, a guide and a hard block look identical
in an index, and one of them is a wish.

Write it on day one, before the first guide.

## What is not here

The runner, the role resolver, the guards and the ratchets themselves. They are
generic by construction — every repo-specific value lives in a data file — but
they have only ever run against one repository. Extracting them before a second
one would ship one repo's assumptions as if they were the pattern.
