#!/usr/bin/env node
// Runs locally what CI runs on a push, in the same order, so you find out
// before pushing rather than after.
//
// The list below is kept honest by ci.test.mjs, which fails if CI grows a check
// this does not run. A local CI that has quietly drifted from the real one is
// worse than not having it.
//
// Usage: node scripts/harness/ci-local.mjs [--base <ref>]

import { spawnSync } from 'node:child_process'
import { resolve } from 'node:path'

const ROOT = resolve(import.meta.dirname, '../..')

function git(args) {
  return spawnSync('git', args, { cwd: ROOT, encoding: 'utf8' }).stdout?.trim() ?? ''
}

function changedFiles(base) {
  const branch = git(['branch', '--show-current'])
  // On the integration branch itself there is no base to compare against, so
  // the last commit is the change.
  const range = branch === base ? ['HEAD^', 'HEAD'] : [`${base}...HEAD`]

  // Committed work plus whatever is still in the working tree. Running this
  // before committing is the whole point, so ignoring uncommitted files would
  // report "nothing changed" at exactly the moment it matters.
  const committed = git(['diff', '--name-only', '--diff-filter=ACM', ...range])
  const working = git(['diff', '--name-only', '--diff-filter=ACM', 'HEAD'])
  const untracked = git(['ls-files', '--others', '--exclude-standard'])

  const all = [committed, working, untracked]
    .flatMap((out) => (out ? out.split('\n') : []))
    .filter(Boolean)
  return [...new Set(all)]
}

// PER REPO. Mirror the CI workflow, step for step, in the same order.
// ci.test.mjs (not shipped in this kit — write it per repo) fails when CI grows
// a step this list does not run. A local CI that has drifted is worse than
// none: it says green and the push still fails.
export const STEPS = [
  { name: 'Type-check', command: '<typecheck command>' },
  { name: 'Harness gate on changed files', command: null }, // built below
  { name: "Harness gate's own tests", command: '<harness test command>' },
  { name: 'Guide rules are enforced', command: '<rule checks command>' },
  { name: 'Unit tests', command: '<test command>' },
]

function main(argv) {
  const base = argv.includes('--base') ? argv[argv.indexOf('--base') + 1] : 'develop'
  const changed = changedFiles(base)

  const steps = STEPS.map((step) => {
    if (step.command !== null) return step
    if (changed.length === 0) return { ...step, command: null, skip: 'nothing changed' }
    const quoted = changed.map((file) => `'${file.replace(/'/g, "'\\''")}'`).join(' ')
    return { ...step, command: `node scripts/harness/gate.mjs ${quoted}` }
  })

  const failed = []

  for (const step of steps) {
    if (step.skip) {
      process.stdout.write(`\n— ${step.name}: skipped (${step.skip})\n`)
      continue
    }
    process.stdout.write(`\n— ${step.name}\n`)
    const result = spawnSync(step.command, { cwd: ROOT, shell: true, stdio: 'inherit' })
    if (result.status !== 0) failed.push(step.name)
  }

  process.stdout.write('\n')
  if (failed.length > 0) {
    process.stderr.write(`CI would fail here: ${failed.join(', ')}\n`)
    return 1
  }
  process.stdout.write(`CI would pass. Compared against ${base}, ${changed.length} file(s) changed.\n`)
  return 0
}

if (process.argv[1]?.endsWith('ci-local.mjs')) {
  process.exit(main(process.argv.slice(2)))
}
