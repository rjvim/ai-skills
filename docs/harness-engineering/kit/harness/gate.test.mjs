// HS1, HS2, HS3 — the gate actually running commands.
//
// These live under node's built-in test runner rather than the project suite,
// because a sandboxed runner has no child_process and cannot test a script whose
// whole job is running commands.

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, writeFileSync, existsSync, readFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'

const GATE = resolve(import.meta.dirname, 'gate.mjs')
const REPO_CONFIG = resolve(import.meta.dirname, '../../harness.json')

function runGate(args) {
  return spawnSync(process.execPath, [GATE, ...args], { encoding: 'utf8' })
}

function fakeConfig(roles, extensions = ['.ts']) {
  const dir = mkdtempSync(join(tmpdir(), 'harness-gate-'))
  const path = join(dir, 'harness.json')
  writeFileSync(
    path,
    JSON.stringify({ roles, onEdit: { extensions, roles: Object.keys(roles) }, budgetSeconds: 10 }),
  )
  return { dir, path }
}

test('HS1: a source edit runs every role the config binds to it', () => {
  const { dir, path } = fakeConfig({
    typecheck: 'node -e "require(\'fs\').writeFileSync(\'typecheck.marker\',\'1\')"',
    lint: 'node -e "require(\'fs\').writeFileSync(\'lint.marker\',\'1\')"',
  })

  const result = runGate(['--config', path, 'src/server/index.ts'])

  assert.equal(result.status, 0, result.stderr)
  assert.ok(existsSync(join(dir, 'typecheck.marker')), 'typecheck did not run')
  assert.ok(existsSync(join(dir, 'lint.marker')), 'lint did not run')
})

test('HS1: the gate runs nothing when no file needs it', () => {
  const { dir, path } = fakeConfig({
    typecheck: 'node -e "require(\'fs\').writeFileSync(\'typecheck.marker\',\'1\')"',
  })

  const result = runGate(['--config', path, 'README.md', 'package.json'])

  assert.equal(result.status, 0)
  assert.ok(!existsSync(join(dir, 'typecheck.marker')), 'a doc edit triggered a role')
})

test('HS2: a failure reports the role, the command, and the tool\'s own words', () => {
  const { path } = fakeConfig({
    lint: 'node -e "console.error(\'Found 3 errors in app.ts\'); process.exit(1)"',
  })

  const result = runGate(['--config', path, 'src/app.ts'])

  assert.equal(result.status, 1, 'a failing role must fail the gate')
  assert.match(result.stderr, /lint FAILED/, 'the failing role is not named')
  assert.match(result.stderr, /Found 3 errors in app\.ts/, 'the tool output did not reach the caller')
})

test('HS2: a role with no command bound fails loudly rather than skipping', () => {
  const { dir } = fakeConfig({ lint: 'true' })
  const path = join(dir, 'broken.json')
  writeFileSync(
    path,
    JSON.stringify({ roles: { lint: 'true' }, onEdit: { extensions: ['.ts'], roles: ['lint', 'typecheck'] } }),
  )

  const result = runGate(['--config', path, 'src/app.ts'])

  assert.equal(result.status, 1)
  assert.match(result.stderr, /typecheck/)
})

test('HS5: a role marked {files} is scoped to the change, not the repo', () => {
  const { dir, path } = fakeConfig({
    lint: 'node -e "require(\'fs\').writeFileSync(\'seen.txt\', process.argv.slice(1).join(\',\'))" {files}',
  })

  const result = runGate(['--config', path, 'README.md', 'src/a.ts', 'src/b.ts'])

  assert.equal(result.status, 0, result.stderr)
  const seen = readFileSync(join(dir, 'seen.txt'), 'utf8')
  assert.equal(seen, 'src/a.ts,src/b.ts', 'the role was not scoped to the changed source files')
})

test('HT3: a streak on a deleted file stops alerting', () => {
  const { dir, path } = fakeConfig({ lint: 'node -e "process.exit(1)"' })
  // Three failing runs against a file that was never created, so it does not
  // exist by the time the fourth run reads the streak.
  for (let i = 0; i < 3; i++) runGate(['--config', path, 'src/gone.ts'])
  const fourth = runGate(['--config', path, 'src/gone.ts'])

  assert.ok(
    !/runs in a row/.test(fourth.stderr),
    `a deleted file kept alerting: ${fourth.stderr}`,
  )
})

test('HS4: editing a file the linter is configured to ignore still passes', () => {
  // A linter can exit non-zero when every path it is given is excluded by its own
  // config. That is a linter with nothing to do, not a failing check, and the
  // gate must not turn it into one — `scripts/` is excluded in this repo.
  const result = runGate(['--config', REPO_CONFIG, 'scripts/harness/gate.mjs'])
  assert.equal(result.status, 0, result.stderr)
})

test('HS3: a single-file edit finishes inside the repo budget', () => {
  const budget = JSON.parse(
    spawnSync('cat', [REPO_CONFIG], { encoding: 'utf8' }).stdout,
  ).budgetSeconds

  const startedAt = Date.now()
  // Exit status is not the point here — lint may legitimately fail on the repo
  // today. The criterion is how long the gate takes to say so.
  runGate(['--config', REPO_CONFIG, 'src/server/index.ts'])
  const elapsed = (Date.now() - startedAt) / 1000

  assert.ok(elapsed < budget, `gate took ${elapsed.toFixed(1)}s against a ${budget}s budget`)
})
