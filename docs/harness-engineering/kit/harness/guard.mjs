#!/usr/bin/env node
// The destructive-action boundary.
//
// This is deliberately NOT the agent's permission system. Runs happen with
// permissions bypassed, including overnight, so a prompt has nobody to answer
// it. These refusals live in git hooks and npm scripts — the shell, not the
// agent — so they hold identically whatever mode a session was started in.
//
// Usage:
//   guard.mjs prod              refuse production work outside the deploy pipeline
//   guard.mjs pre-push          refuse force-push and branch deletion on protected branches
//   guard.mjs pre-commit        refuse deleting applied migrations

import { spawnSync } from 'node:child_process'

const PROTECTED = ['main', 'develop']
// PER REPO. Directories whose files are append-only history: a deleted
// migration is a schema that can never be rebuilt from the repository.
const MIGRATION_DIRS = ['<migrations dir>/']
const ZERO = /^0+$/

function refuse(lines) {
  process.stderr.write(`${lines.join('\n')}\n`)
  process.exit(1)
}

function git(args) {
  return spawnSync('git', args, { encoding: 'utf8' })
}

// PER REPO. The workflow named in the refusal, so the message points somewhere.
const PROD_WORKFLOW = '<the production deploy workflow>'

// Production work belongs to the deploy workflow, which runs with CI set.
// A laptop or an agent session has to say so out loud.
function guardProd() {
  if (process.env.CI) return
  if (process.env.HARNESS_ALLOW_PROD === '1') return
  refuse([
    'harness guard: refusing a production command outside the deploy pipeline.',
    '',
    `Production changes go through ${PROD_WORKFLOW}.`,
    'If you really mean to do this from here, run it again with',
    'HARNESS_ALLOW_PROD=1 and know that nothing else will stop you.',
  ])
}

function guardPrePush(stdin) {
  for (const line of stdin.split('\n')) {
    const [localRef, localSha, remoteRef, remoteSha] = line.trim().split(/\s+/)
    if (!remoteRef) continue
    const branch = remoteRef.replace('refs/heads/', '')
    if (!PROTECTED.includes(branch)) continue

    if (ZERO.test(localSha ?? '')) {
      refuse([`harness guard: refusing to delete ${branch} on the remote.`])
    }
    if (ZERO.test(remoteSha ?? '')) continue // new branch, nothing to overwrite

    // A push that does not build on what the remote already has is a rewrite
    // of shared history, whether or not --force was typed.
    const ancestor = git(['merge-base', '--is-ancestor', remoteSha, localSha])
    if (ancestor.status !== 0) {
      refuse([
        `harness guard: refusing a non-fast-forward push to ${branch}.`,
        '',
        `${remoteSha.slice(0, 8)} on the remote is not an ancestor of what you are pushing.`,
        'That rewrites history other people and other worktrees already have.',
        `Local ref: ${localRef}`,
      ])
    }
  }
}

function guardPreCommit() {
  const staged = git(['diff', '--cached', '--name-only', '--diff-filter=D']).stdout ?? ''
  const deleted = staged
    .split('\n')
    .map((file) => file.trim())
    .filter((file) => file && MIGRATION_DIRS.some((dir) => file.startsWith(dir)))

  if (deleted.length > 0) {
    refuse([
      'harness guard: refusing to delete a migration.',
      '',
      ...deleted.map((file) => `  ${file}`),
      '',
      'Applied migrations are history. A database that ran them cannot un-run',
      'them by having the file removed. Write a new migration instead.',
    ])
  }
}

const mode = process.argv[2]
if (mode === 'prod') {
  guardProd()
} else if (mode === 'pre-push') {
  let raw = ''
  process.stdin.setEncoding('utf8')
  for await (const chunk of process.stdin) raw += chunk
  guardPrePush(raw)
} else if (mode === 'pre-commit') {
  guardPreCommit()
} else {
  process.stderr.write(`harness guard: unknown mode "${mode ?? ''}"\n`)
  process.exit(1)
}
