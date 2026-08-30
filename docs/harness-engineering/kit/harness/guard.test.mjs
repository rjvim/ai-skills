// HP1-HP4 — the boundary that holds when permissions are bypassed.

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

const ROOT = resolve(import.meta.dirname, '../..')
const GUARD = resolve(import.meta.dirname, 'guard.mjs')

function runGuard(mode, { stdin = '', env = {} } = {}) {
  return spawnSync(process.execPath, [GUARD, mode], {
    cwd: ROOT,
    input: stdin,
    encoding: 'utf8',
    // A bypassed agent session inherits a normal environment. Start from
    // nothing so a stray CI var in the developer's shell cannot hide a failure.
    env: { PATH: process.env.PATH, HOME: process.env.HOME, ...env },
  })
}

test('HP3: a production command refuses to run outside the deploy pipeline', () => {
  const result = runGuard('prod')
  assert.equal(result.status, 1, 'production work was allowed from an ordinary session')
  assert.match(result.stderr, /refusing a production command/)
})

test('HP3: the deploy workflow can still run it', () => {
  assert.equal(runGuard('prod', { env: { CI: 'true' } }).status, 0)
})

test('HP3: a human can override, and has to say so', () => {
  assert.equal(runGuard('prod', { env: { HARNESS_ALLOW_PROD: '1' } }).status, 0)
})

test('HP2: a non-fast-forward push to a protected branch is refused', () => {
  const head = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: ROOT, encoding: 'utf8' }).stdout.trim()
  const orphan = '0123456789012345678901234567890123456789'
  const result = runGuard('pre-push', {
    stdin: `refs/heads/harness-engineering ${head} refs/heads/develop ${orphan}\n`,
  })
  assert.equal(result.status, 1, 'a history rewrite of develop was allowed')
  assert.match(result.stderr, /non-fast-forward push to develop/)
})

test('HP2: deleting a protected branch on the remote is refused', () => {
  const head = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: ROOT, encoding: 'utf8' }).stdout.trim()
  const result = runGuard('pre-push', {
    stdin: `refs/heads/x 0000000000000000000000000000000000000000 refs/heads/main ${head}\n`,
  })
  assert.equal(result.status, 1)
  assert.match(result.stderr, /refusing to delete main/)
})

test('HP2: pushing an unprotected branch is left alone', () => {
  const head = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: ROOT, encoding: 'utf8' }).stdout.trim()
  const result = runGuard('pre-push', {
    stdin: `refs/heads/x ${head} refs/heads/feat/anything 0000000000000000000000000000000000000000\n`,
  })
  assert.equal(result.status, 0, result.stderr)
})

test('HP1: the boundary travels with the repository', () => {
  const pkg = JSON.parse(readFileSync(resolve(ROOT, 'package.json'), 'utf8'))

  // A fresh clone points git at the committed hooks on install — nothing
  // personal, nothing machine-local.
  assert.match(pkg.scripts.prepare, /core\.hooksPath \.githooks/)

  for (const script of ['deploy:production', 'db:migrate:production', 'db:nav:migrate:production']) {
    assert.match(pkg.scripts[script], /guard\.mjs prod/, `${script} is unguarded`)
  }
})

test('HP4: bypassing agent permissions changes nothing here', () => {
  // Every refusal above came from git hooks and npm scripts. None of them
  // consult an agent permission list, so an unattended run granted everything
  // hits exactly the same wall a supervised one does.
  const bypassed = runGuard('prod', {
    env: { CLAUDE_PERMISSION_MODE: 'bypassPermissions', CODEX_APPROVAL: 'never' },
  })
  assert.equal(bypassed.status, 1, 'a bypassed session got past the production guard')
})
