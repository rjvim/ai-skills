# Adding the harness to a new repository

Ordered. Each step's output is the next step's input. Written after doing
it once end to end on a TypeScript repo with an edge runtime, so the stack-specific
parts are marked.

Read `lessons.md` before starting. This file is the sequence; that one is
why each step is shaped the way it is.

---

## Before anything

- [ ] **Confirm the repo is private, or find out what cannot be written
      down.** This nearly went wrong once: design notes naming private
      repos were written into a public one. Nothing was committed. All
      migration notes live outside every work tree for this reason.
- [ ] **Ask two questions, and only two.** Which surfaces are theirs —
      copied-in components, docs sites, published assets. And whether
      warnings gate or only errors. Everything else is measurable.
- [ ] **Ask for the product list.** Not the module list, not the folder
      list. The products the company sells. Guides derive from this later
      and nothing else produces it.

## 1. Survey — one session

- [ ] Walk the six layers and record which exist, which are enforced, and
      which are prose pretending to be enforcement. Most repos are heavy
      on guides and empty everywhere else.
- [ ] Count the debt before touching anything: lint errors, oversized
      files, any rule the repo states and does not check. These become
      ceilings, not exclusions.
- [ ] Find every existing check. Some rules already have owners and do
      not need new ones.

## 2. Criteria before code — one session

- [ ] Write the acceptance criteria first, in groups. This is what stops
      two of them being quietly redefined later to match whatever got
      built.
- [ ] Mark anything unprovable from inside the repo as an explicit gap
      with a reason. Cost is always one of these.

## 3. The gate — one session

- [ ] A data file binding roles to commands: typecheck, lint, test,
      mapped to whatever this repo actually runs. **This is the only file
      the next repo has to write.**
- [ ] Mark per-file roles with a placeholder. A type checker needs the
      whole project; a linter does not, and scoping it is what makes the
      gate usable in a repo carrying lint debt.
- [ ] One runner reading that file. Every caller is a two-line shim.
- [ ] Measure the per-edit time and give it a budget. Over about ten
      seconds it gets switched off.

## 4. Enforcement — under a session each

- [ ] Debt ratchets: record the count, fail if it grows, fail if it drops
      without the ceiling moving.
- [ ] Git hooks for anything destructive. Not approval prompts — runs
      happen with permissions bypassed and a prompt overnight has nobody
      to answer it.
- [ ] Production commands refuse to run outside the deploy pipeline.
- [ ] A plan or branch-state check, if the repo keeps plans.
- [ ] A local command that runs exactly what CI runs, plus a test that
      fails when CI grows a step it does not run.

## 5. The rule that makes the rest work

- [ ] **A test that fails when any guide has no check.** Three lines.
      Write it before the first guide, not after. Everything downstream
      arrives with its enforcement attached because of this one.

## 6. Tool shims — last

- [ ] One per agent, thin, all behaviour in the runner.
- [ ] Each resolves the repo root explicitly rather than assuming the
      working directory.
- [ ] A test asserting each stays short and calls the gate.
- [ ] Note which agent needs a human to trust the repo hook once. The git
      hook is the floor underneath that gap.

## 7. Guides — with the human, one product at a time

Not before here. Everything above is derivable from the repo; this is not.

For each product on the list:

- [ ] Show the human what is true today, in facts, in under ten lines.
- [ ] Ask for the rule. Do not propose one.
- [ ] **Check the codebase against the answer before writing.** This is
      where the value is. Expect to find at least one thing they did not
      know had drifted.
- [ ] Write the guide: the rule, why it is hidden, when to apply, when
      not to worry, known debt with a count, and what enforces it.
- [ ] Write the check, or hand it over with the guide unmerged.
- [ ] Record any mismatch as a GAP criterion in that feature's spec.

Revisit products more than once. The first pass surfaces the rule; the
second surfaces what it collides with.

## 8. Once every rule is enforced

Not before. These are what a harness grows into, and they audit or extend what
steps 1-7 built. Full form in `portable-extensions.md`.

- [ ] **Give every rule a rung**, and the blast radius its consequences demand.
      Check that one is at least the other. Universal, needs no telemetry, and
      it audits every rule already written.
- [ ] **A ratchet that counts unused things**, if the repo declares an
      inventory whose items cost something while idle. Agent tool definitions
      are the strongest case: each is read on every turn whether called or not.
- [ ] **Contribution per unit**, if the repo bills. Price minus variable cost,
      per unit served. The row people get wrong is positive-but-quiet: it looks
      like an unpopular feature and it is an under-exposed one.

## 8. Only then

- [ ] A second repo with a different language and build tool. The output
      is not the second repo — it is the list of what had to change, and
      that list is the installer's spec.

---

## Stack-specific, expect to differ

- The role commands. Everything else is generic.
- Whether the test runner can spawn processes. A sandboxed one cannot
  test a script that runs commands; split the pure logic into the normal
  suite and test execution with the language's built-in runner.
- Whether the linter exits non-zero when handed only ignored paths.
- Whether a script name collides with a package-manager builtin.
- Whether a worktree can live inside the repo. Usually it cannot.

## Two agents

If a second agent works the same repo, read the "Two agents, one
checkout" section of `lessons.md` before the first commit, not after the
first collision.
