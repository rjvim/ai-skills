// The record. Every gate run appends one line, so a failure that keeps
// repeating becomes a fact rather than a feeling.
//
// Local runtime data, not repository content — .harness/ is gitignored.

import { appendFileSync, existsSync, mkdirSync, readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'

export const REPEAT_LIMIT = 3

export function logPath(root) {
  return join(root, '.harness', 'log.jsonl')
}

export function append(root, entry) {
  const path = logPath(root)
  mkdirSync(dirname(path), { recursive: true })
  appendFileSync(path, `${JSON.stringify({ at: new Date().toISOString(), ...entry })}\n`)
}

export function read(root) {
  const path = logPath(root)
  if (!existsSync(path)) return []
  return readFileSync(path, 'utf8')
    .split('\n')
    .filter(Boolean)
    .map((line) => {
      try {
        return JSON.parse(line)
      } catch {
        return null
      }
    })
    .filter(Boolean)
}

/**
 * Roles that have failed on the same files this many runs in a row, with no
 * success in between. A fourth attempt is not going to differ, so the caller
 * escalates instead of retrying.
 */
export function repeatingFailures(entries, limit = REPEAT_LIMIT) {
  const streaks = new Map()

  for (const entry of entries) {
    for (const role of entry.roles ?? []) {
      const key = `${role} ${(entry.files ?? []).join(',')}`
      const failed = (entry.failed ?? []).includes(role)
      const previous = streaks.get(key)
      streaks.set(key, {
        role,
        files: entry.files ?? [],
        count: failed ? (previous?.count ?? 0) + 1 : 0,
      })
    }
  }

  // Only streaks that are still running. A trip that was fixed two runs ago is
  // history, and repeating it every run is how an alert gets ignored.
  return [...streaks.values()].filter((streak) => streak.count >= limit)
}
