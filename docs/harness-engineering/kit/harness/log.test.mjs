// HT1, HT3 — the record, and the escalation it makes possible.
//
// HT2 (cost) is deliberately not here. A repo-side gate cannot see tokens or
// money; that lives in the agent runtime. See the spec's HT status.

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, readFileSync, appendFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { append, read, repeatingFailures, logPath, REPEAT_LIMIT } from './log.mjs'

function root() {
  return mkdtempSync(join(tmpdir(), 'harness-log-'))
}

function entries(...failedPerRun) {
  return failedPerRun.map((failed) => ({ files: ['src/a.ts'], roles: ['typecheck', 'lint'], failed }))
}

test('HT1: a run is recorded with when, what, and how it went', () => {
  const dir = root()
  append(dir, { files: ['src/a.ts'], roles: ['lint'], failed: ['lint'], seconds: 1.2 })

  const [entry] = read(dir)
  assert.match(entry.at, /^\d{4}-\d{2}-\d{2}T/, 'no timestamp')
  assert.deepEqual(entry.files, ['src/a.ts'])
  assert.deepEqual(entry.roles, ['lint'])
  assert.deepEqual(entry.failed, ['lint'])
  assert.equal(entry.seconds, 1.2)
})

test('HT1: the record appends rather than replacing', () => {
  const dir = root()
  append(dir, { files: ['a.ts'], roles: ['lint'], failed: [] })
  append(dir, { files: ['b.ts'], roles: ['lint'], failed: [] })
  assert.equal(read(dir).length, 2)
  assert.equal(readFileSync(logPath(dir), 'utf8').trim().split('\n').length, 2)
})

test('HT1: a missing record reads as empty rather than throwing', () => {
  assert.deepEqual(read(root()), [])
})

test('HT1: a torn line does not take the whole record down', () => {
  const dir = root()
  append(dir, { files: ['a.ts'], roles: ['lint'], failed: [] })
  appendFileSync(logPath(dir), '{ this is not json\n')
  append(dir, { files: ['b.ts'], roles: ['lint'], failed: [] })
  assert.equal(read(dir).length, 2)
})

test(`HT3: the same role failing ${REPEAT_LIMIT} runs running trips`, () => {
  const tripped = repeatingFailures(entries(['lint'], ['lint'], ['lint']))
  assert.equal(tripped.length, 1)
  assert.equal(tripped[0].role, 'lint')
  assert.equal(tripped[0].count, REPEAT_LIMIT)
})

test('HT3: two failures in a row is not yet a trip', () => {
  assert.deepEqual(repeatingFailures(entries(['lint'], ['lint'])), [])
})

test('HT3: a success in between resets the streak', () => {
  assert.deepEqual(repeatingFailures(entries(['lint'], ['lint'], [], ['lint'])), [])
})

test('HT3: a streak that has since been fixed stops being reported', () => {
  // Otherwise every later run repeats an alert about something already dealt
  // with, which is how an alert gets ignored.
  const fixed = entries(['lint'], ['lint'], ['lint'], [], [])
  assert.deepEqual(repeatingFailures(fixed), [])
})

test('HT3: two roles failing independently both trip', () => {
  const both = entries(['lint', 'typecheck'], ['lint', 'typecheck'], ['lint', 'typecheck'])
  const roles = repeatingFailures(both).map((trip) => trip.role).sort()
  assert.deepEqual(roles, ['lint', 'typecheck'])
})

test('HT3: the same role failing on different files is not one streak', () => {
  const spread = [
    { files: ['a.ts'], roles: ['lint'], failed: ['lint'] },
    { files: ['b.ts'], roles: ['lint'], failed: ['lint'] },
    { files: ['c.ts'], roles: ['lint'], failed: ['lint'] },
  ]
  assert.deepEqual(repeatingFailures(spread), [])
})
