#!/usr/bin/env node
// Codex shim. Reads the PostToolUse payload on stdin, pulls the files that
// apply_patch just changed, and hands them to the shared gate. All behaviour
// stays in gate.mjs so every tool behaves the same.

import { spawnSync } from 'node:child_process'
import { resolve } from 'node:path'

const GATE = resolve(import.meta.dirname, 'gate.mjs')

let raw = ''
process.stdin.setEncoding('utf8')
for await (const chunk of process.stdin) raw += chunk

let patch
try {
  patch = JSON.parse(raw)?.tool_input?.command
} catch {
  process.exit(0)
}
if (!patch) process.exit(0)

const files = [
  ...patch.matchAll(/^\*\*\* (?:Add|Update|Delete) File: (.+)$/gm),
  ...patch.matchAll(/^\*\*\* Move to: (.+)$/gm),
].map((match) => match[1])
if (files.length === 0) process.exit(0)

const result = spawnSync(process.execPath, [GATE, ...new Set(files)], { encoding: 'utf8' })
if (result.status !== 0) {
  // Exit 2 feeds stderr back into Codex's turn as PostToolUse feedback.
  process.stderr.write(result.stderr ?? '')
  process.exit(2)
}
process.exit(0)
