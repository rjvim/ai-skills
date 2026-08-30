# The kit

The generic half of a harness, lifted from the first repository it ran on.
Copy it, write one data file, and most of the machinery works.

**Do not trust this blindly.** It has run against exactly one repository. The
files below are marked by how sure that is.

## Verbatim — no repo-specific line in them

| File | What it does |
|---|---|
| `harness/gate.mjs` | The runner. Given changed files, resolves roles and runs them. |
| `harness/roles.mjs` | Pure resolution: files → roles → commands. No I/O. |
| `harness/log.mjs` | Append-only run record, and the repeating-failure trip wire. |
| `harness/check-plans.mjs` | Branch-plan drift: missing branch key, duplicates, line ceiling, staleness. |
| `harness/claude-hook.mjs` | Shim. Parses the tool payload, calls the gate. |
| `harness/codex-hook.mjs` | Shim. Parses the patch envelope, calls the gate. |

Tests for four of them ship too, and they pass unmodified.

## Parameterised — one marked block each

| File | What to change |
|---|---|
| `harness.json` | Every role command. **This is the only file most repos need to write.** |
| `harness/guard.mjs` | The append-only directories, and the protected branch names. |
| `harness/ci-local.mjs` | The step list, mirroring the real CI workflow. |

## Not in the kit, and why

**The ratchets** — lint debt, file size, whatever else the repo carries. Each
one greps for something only that repo has, and the ceiling is a measurement,
not a constant. Write them per repo; the shape is three branches: over the
ceiling fails, under the ceiling fails asking you to lower it, equal passes.

**The rule checks.** Same reason, more so. A rule check enforces a guide, and
guides come from the human, one product at a time.

**`ci.test.mjs`** — it reads the workflow file and asserts the local CI list
matches it. Both sides are per repo.

**The guides themselves.** Nothing about them travels.

## The one test to write first

Before the first guide:

> Every file in the guides folder is named by some script or workflow.

Three lines of assertion. After it, every rule arrives with its enforcement
attached, because there is no longer a way to land prose.

## Order

`../checklist.md`. Read `../lessons.md` before the first commit.
