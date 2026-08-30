# Lessons from the first repo

Written after doing this once end to end. No repo names — this is the
part meant to survive into the next one.

## The order that worked

1. **Survey against the six layers before touching anything.** Which
   exist, which are enforced, which are prose pretending to be
   enforcement. Most repos are heavy on guides and empty everywhere
   else.
2. **Plan, then criteria, then code.** Writing the acceptance criteria
   first is what stopped two of them being quietly redefined later to
   whatever got built.
3. **Build the gate first.** A data file binding roles to commands, and
   one runner that reads it. Everything else hangs off this.
4. **Enforcement checks after the gate.** Plan drift, debt ceilings.
   They are ordinary scripts once the pattern exists.
5. **Tool shims last, one per agent.** Thin. All behaviour stays in the
   runner so the tools cannot drift apart.

## Design rules that held up

- **One gate script, several callers.** Each agent hook and the git hook
  are two-line shims. Never let a caller carry logic.
- **Roles live in repo data, not the runner.** `typecheck`, `lint`,
  `test` mapped to whatever that repo actually runs. This is the only
  file the next repo has to write.
- **Mark per-file roles.** A `{files}` placeholder means "run on what
  changed"; without it the role runs repo-wide. A type checker needs the
  whole project, a linter does not. This distinction is what makes the
  gate usable in a repo carrying lint debt.
- **Enforcement goes in git hooks and package scripts, never approval
  prompts.** Runs happen with permissions bypassed, and a prompt
  overnight has nobody to answer it. The rule is make it impossible,
  not ask.
- **Debt gets a ratchet, not an exclusion.** Record the current count,
  fail if it grows, fail if it drops without the ceiling moving. An
  exclusion is permanent; a ceiling only goes down.
- **Local CI needs a test keeping it in sync with real CI.** A local CI
  that has drifted is worse than none: it reports green and the push
  still fails.
- **Both agent hooks and the git hook.** Agent hooks give feedback
  inside the turn, which is the fast loop, but each binds one tool. The
  git hook binds everything including a human, and catches what the
  others missed.
- **Hooks resolve the repository root explicitly.** A relative path in a
  hook command only works when the agent happens to be at the root.
  Resolve it (`git rev-parse --show-toplevel`) instead. Learned from the
  second tool's config being better than the first's.
- **Hold the shims to a line count.** A shim that grows logic of its own
  is how two tools quietly start behaving differently. A test asserting
  each stays short and calls the gate is enough.

## Traps, in the order they bit

- **A worktree inside the repo breaks the toolchain.** Anything that
  looks for a single root config — linters, formatters, bundlers — finds
  two and refuses. Worktrees go in a sibling directory.
- **A worktree has no dependencies installed.** Install before assuming
  a test failure means what it says.
- **Short criterion IDs collide.** A two-letter prefix per spec. One
  letter matches fixture data, and matches other specs' IDs.
- **A mapping check that greps for a bare ID gives false passes.** An ID
  in a comment, a fixture value, or another spec's cross-reference all
  count as "tested". Require the ID inside a test declaration or an
  explicit tag.
- **A linter handed only ignored paths exits non-zero.** That is a
  linter with nothing to do, not a failing check. Find the flag that
  silences it, or the gate fails on every edit to an excluded folder.
- **Package managers shadow script names.** Naming the local CI script
  `ci` meant the package manager's own `ci` ran instead: it wiped the
  dependency tree and exited 0 without running a single check. Prefix
  script names.
- **Trip wires must report live streaks only.** Replaying every trip in
  the log means alerting about things fixed days ago. And a streak on a
  deleted file can never reset, so it alerts forever. Both train people
  to ignore the alert.
- **Check whether the app's test runner can spawn processes.** A
  sandboxed runner cannot test a script that runs commands. Split the
  pure logic into the normal suite and test the execution separately
  with the language's built-in runner.

## What to ask the human, and when

Before starting:

- **Which surfaces are theirs.** Copied-in components, docs sites,
  published assets. Expect the answer to be "all of it" — the useful
  outcome is that nothing gets excluded and the debt gets a ceiling.
- **Whether warnings gate, or only errors.**

Everything else is derivable from the repo. Do not ask what can be
measured.

## Agent hooks, as of this writing

Both major CLIs converged on the same shape, which is why one gate with
thin shims works:

- A per-repo config file declaring a `PostToolUse` hook with an
  `Edit|Write` matcher.
- The hook receives JSON on stdin describing the tool call. One passes
  the written path directly; the other passes a patch envelope whose
  headers name the changed files, so the shim parses those out.
- Exit 2 with output on stderr feeds the failure back into that agent's
  turn. Neither can undo the edit that already happened — the feedback
  is the mechanism, not a rollback.

**One asymmetry worth planning for:** one of them requires a human to
approve a repository hook once before it will fire. A fresh clone is
therefore not covered by that agent's edit hook until someone approves
it. This is the strongest argument for the git hook: it needs no
approval, so nothing reaches a commit unchecked regardless.

## What cannot be done from inside a repository

Cost. Tokens and money live in the agent runtime, not the checkout, so
no repo-side script can observe them. Either the runtime reports cost to
a hook, or run duration is accepted as a proxy, or the criterion stays
open. Leaving it open is better than a check that measures something
else and calls it cost.

## Rough cost, first repo

One session for the survey, plan and criteria. One for the gate and its
tests. Under one for each of the enforcement checks. The unknown is
never the harness — it is how much debt the repo is carrying and who is
allowed to pay it down.

---

## Second half of the first repo — guides, and two agents

Everything above was written after building the machinery. This part was
written after using it, and after a second agent joined the same repo.

### The rule that changed everything

**A guide with no check fails the suite.** One test: every file in the
guides folder must be named by some script or workflow.

It is three lines of assertion and it reorganised the whole effort. Every
rule after it arrived with its enforcement attached, because there was no
longer a way to land prose. It also caught the second agent writing ten
acceptance criteria with nothing behind them.

Write this test on day one of the next repo, before the first guide.

### Guides come from products, and the count is not yours to pick

The first instinct was to invent buckets — "frontend patterns, backend
patterns, coupling, general practices". The human rejected it: the
buckets fall out of the product list, not out of a taxonomy.

The method that worked:

1. List the products. Ask the human, do not derive them.
2. Take one product at a time and ask what is true there.
3. Check the codebase against the answer before writing anything.
4. Write the guide, then the check, then hand the mismatch to whoever
   owns the code.

Half the value was in step 3. Every product surfaced something the human
did not know had drifted: a widget rendering a second implementation of a
component the company also publishes, a docs site with no section for a
whole product, a design-system rule that was true in three surfaces and
undocumented in all of them.

### What a good product guide contains

Same shape every time, and the shape matters more than the length:

- **The rule**, in one sentence, before anything else.
- **Why it is hidden** — how the violation renders correctly, passes
  review, and only shows up later. If a rule fails loudly it does not
  need a guide, it needs a type.
- **When to apply / When NOT to worry.** The second half is what stops
  the rule being ignored wholesale the first time it is over-applied.
- **Known debt with a count**, when reality does not match yet.
- **Enforced by**, naming the check.

### Debt goes in the guide, then in the spec

When the code does not match the rule, do not fix it in the same breath.
Record the count in the guide, mirror it as a GAP criterion in the
feature spec, ratchet the check at the current number. The human decides
when it gets paid.

The unsolved half: nothing tells an agent that the file it is editing
carries recorded debt. The manifests declare source roots and the specs
declare gaps — connecting them is one sensor nobody has written.

### Two agents, one checkout

They will collide, and the collision is silent.

- **Split by path, not by branch.** Guides to one, feature specs and
  manifests to the other. Path-split work never collided once. Shared
  files collided three times in a day, and one write was lost entirely —
  the second agent's formatting pass overwrote a fresh edit within
  seconds.
- **Never switch branches in a shared checkout.** A checkout fails, or
  worse succeeds, whenever the other agent has the same file dirty.
  Commit to a branch without touching the working tree instead:
  hash-object the content, read-tree into a temporary index, commit-tree,
  update-ref. It is four commands and it is completely safe.
- **Commit by explicit path, never `git add -A`.** Twice that was the
  only thing standing between one agent and committing the other's
  half-finished work.
- **Adopt the other agent's convention rather than fighting it.** One was
  running a pass that appended an owner to a heading. Matching it cost
  one line and ended the churn.
- Criterion IDs collide too. Two agents both reached for `CR3`.

### The order rules arrive in

Guides last, not first. The gate, the ratchets and the plan check are
generic and can be built from the repo alone. Guides need the human, one
product at a time, and each answer takes a round trip. Build the
machinery while waiting, then spend the human's attention only on the
rules nothing else can supply.
