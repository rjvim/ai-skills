// HM1-HM7 — the plan file cannot drift in silence.

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { checkPlans, LINE_CEILING } from './check-plans.mjs'

const TODAY = new Date('2026-08-30')
const REAL_PLANS = resolve(import.meta.dirname, '../../.plans')

function plansDir(files) {
  const dir = mkdtempSync(join(tmpdir(), 'harness-plans-'))
  for (const [name, body] of Object.entries(files)) {
    if (name.startsWith('shipped/')) mkdirSync(join(dir, 'shipped'), { recursive: true })
    writeFileSync(join(dir, name), body)
  }
  return dir
}

const good = [
  '# Plan: something',
  'Branch: feat/something',
  'Status: in-progress',
  'Last reconciled: 2026-08-28 — verified against code',
].join('\n')

test('HM1: a plan with no branch key is caught and named', () => {
  const problems = checkPlans(plansDir({ 'orphan.md': '# Plan: orphan\nStatus: approved\n' }), TODAY)
  assert.equal(problems.length, 1)
  assert.match(problems[0], /orphan\.md.*no "Branch:" line/)
})

test('HM1: a placeholder branch is not a branch', () => {
  const problems = checkPlans(plansDir({ 'p.md': '# Plan\nBranch: —\nStatus: approved\n' }), TODAY)
  assert.match(problems[0], /placeholder/)
})

test('HM2: two plans claiming one branch is caught, naming both', () => {
  const problems = checkPlans(plansDir({ 'a.md': good, 'b.md': good }), TODAY)
  const clash = problems.find((p) => p.includes('claimed by'))
  assert.ok(clash, 'a duplicate branch key passed')
  assert.match(clash, /a\.md, b\.md/)
})

test('HM3: a plan over the ceiling is caught, with its length', () => {
  const long = `${good}\n${'filler\n'.repeat(LINE_CEILING)}`
  const problems = checkPlans(plansDir({ 'long.md': long }), TODAY)
  assert.match(problems[0], new RegExp(`long\\.md: \\d+ lines, over the ${LINE_CEILING}-line ceiling`))
})

test('HM4: an in-progress plan nobody has reconciled in a fortnight is caught', () => {
  const stale = good.replace('2026-08-28', '2026-08-01')
  const problems = checkPlans(plansDir({ 'stale.md': stale }), TODAY)
  assert.match(problems[0], /last reconciled 29 days ago/)
})

test('HM4: an in-progress plan with no reconcile date at all is caught', () => {
  const undated = '# Plan\nBranch: x\nStatus: in-progress\n'
  const problems = checkPlans(plansDir({ 'undated.md': undated }), TODAY)
  assert.match(problems[0], /no "Last reconciled" date/)
})

test('HM5: a shipped plan still in flight is caught', () => {
  const merged = good.replace('Status: in-progress', 'Status: shipped')
  const problems = checkPlans(plansDir({ 'merged.md': merged }), TODAY)
  assert.match(problems[0], /still in flight; archive it/)
})

test('HM5: archived plans are history and are left alone', () => {
  const ancient = [
    '# Plan: old',
    'Branch: gone',
    'Status: in-progress',
    'Last reconciled: 2024-01-01',
    'filler\n'.repeat(LINE_CEILING),
  ].join('\n')
  const problems = checkPlans(plansDir({ 'ok.md': good, 'shipped/2026-01-01-old.md': ancient }), TODAY)
  assert.deepEqual(problems, [], 'an archived plan was held to a live plan\'s rules')
})

test('HM7: a conforming plan raises nothing', () => {
  assert.deepEqual(checkPlans(plansDir({ 'ok.md': good }), TODAY), [])
})

test('HM6: it fails on this repository as it stands today', () => {
  const problems = checkPlans(REAL_PLANS, TODAY)
  assert.ok(problems.length > 0, 'the check passes on a repo known to be drifting')

  // The violations that were verified by hand before this check existed.
  const unkeyed = problems.filter((p) => p.includes('no "Branch:" line'))
  assert.ok(unkeyed.length >= 5, `expected at least 5 unkeyed plans, found ${unkeyed.length}`)
  assert.ok(problems.some((p) => p.includes('placeholder')), 'the placeholder branch was missed')
  assert.ok(
    problems.filter((p) => p.includes('over the')).length >= 2,
    'the two over-ceiling plans were missed',
  )
})

test('HM7: this branch\'s own plan conforms', () => {
  const problems = checkPlans(REAL_PLANS, TODAY)
  assert.ok(
    !problems.some((p) => p.startsWith('harness-engineering.md')),
    `this branch's plan does not pass its own check: ${problems.join('; ')}`,
  )
})
