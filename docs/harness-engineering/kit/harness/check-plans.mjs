#!/usr/bin/env node
// The memory check. A committed plan is only durable memory if something reads
// it — otherwise it is a guide with better handwriting. This is what reads it.
//
// Usage: node scripts/harness/check-plans.mjs [--dir .plans] [--today YYYY-MM-DD]

import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { join, basename } from 'node:path'

export const LINE_CEILING = 400
export const STALE_DAYS = 14
const PLACEHOLDER = new Set(['', '—', '-', '--', 'tbd', 'none', 'n/a'])

function field(text, name) {
  const match = text.match(new RegExp(`^${name}:\\s*(.*)$`, 'm'))
  return match ? match[1].trim() : null
}

function daysBetween(from, to) {
  return Math.floor((to.getTime() - from.getTime()) / 86400000)
}

export function checkPlans(dir, today = new Date()) {
  const problems = []
  if (!existsSync(dir)) return [`${dir} does not exist`]

  const active = readdirSync(dir).filter((f) => f.endsWith('.md')).sort()
  const shippedDir = join(dir, 'shipped')
  const shipped = existsSync(shippedDir)
    ? readdirSync(shippedDir).filter((f) => f.endsWith('.md')).sort()
    : []

  const byBranch = new Map()

  for (const file of active) {
    const path = join(dir, file)
    const text = readFileSync(path, 'utf8')
    const lines = text.split('\n').length

    // HM3 — an unbounded plan is re-read every resume and taxes every turn.
    if (lines > LINE_CEILING) {
      problems.push(`${file}: ${lines} lines, over the ${LINE_CEILING}-line ceiling`)
    }

    // HM1 — without a branch key, resume cannot find this plan at all.
    const branch = field(text, 'Branch')
    if (branch === null) {
      problems.push(`${file}: no "Branch:" line, so resume can never find it`)
    } else if (PLACEHOLDER.has(branch.toLowerCase())) {
      problems.push(`${file}: "Branch: ${branch}" is a placeholder, not a branch`)
    } else {
      // HM2 — one plan per branch, or resume has to guess.
      if (!byBranch.has(branch)) byBranch.set(branch, [])
      byBranch.get(branch).push(file)
    }

    const status = (field(text, 'Status') ?? '').toLowerCase()

    // HM5 — a merged plan sitting in flight corrupts the delivery timeline.
    if (status === 'shipped') {
      problems.push(`${file}: status is shipped but it is still in flight; archive it`)
    }

    // HM4 — a plan nobody has checked against reality is a rumour.
    if (status === 'in-progress') {
      const stamp = (field(text, 'Last reconciled') ?? '').match(/\d{4}-\d{2}-\d{2}/)
      if (!stamp) {
        problems.push(`${file}: in-progress with no "Last reconciled" date`)
      } else {
        const age = daysBetween(new Date(stamp[0]), today)
        if (age > STALE_DAYS) {
          problems.push(`${file}: in-progress, last reconciled ${age} days ago`)
        }
      }
    }
  }

  for (const [branch, files] of byBranch) {
    if (files.length > 1) {
      problems.push(`branch "${branch}" is claimed by ${files.length} plans: ${files.join(', ')}`)
    }
  }

  // Archived plans are history and are never re-read on resume, so neither the
  // ceiling nor the staleness rule means anything for them. They are left alone
  // deliberately — `shipped` is read only to prove the directory is understood.
  void shipped

  return problems
}

if (basename(process.argv[1] ?? '') === 'check-plans.mjs') {
  const args = process.argv.slice(2)
  const dir = args.includes('--dir') ? args[args.indexOf('--dir') + 1] : '.plans'
  const today = args.includes('--today') ? new Date(args[args.indexOf('--today') + 1]) : new Date()

  const problems = checkPlans(dir, today)
  if (problems.length === 0) {
    console.log(`OK: every plan in ${dir} is keyed, current and inside its ceiling`)
    process.exit(0)
  }
  console.error(`${problems.length} problem(s) in ${dir}:\n`)
  for (const problem of problems) console.error(`  ${problem}`)
  process.exit(1)
}
