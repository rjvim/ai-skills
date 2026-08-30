#!/usr/bin/env node
// Claude Code shim. Reads the PostToolUse payload on stdin, pulls the file that
// was just written, and hands it to the shared gate. All the logic lives in
// gate.mjs so every tool behaves the same.

import { spawnSync } from 'node:child_process'
import { resolve } from 'node:path'

const GATE = resolve(import.meta.dirname, 'gate.mjs')

let raw = ''
process.stdin.setEncoding('utf8')
for await (const chunk of process.stdin) raw += chunk

let filePath
try {
  filePath = JSON.parse(raw)?.tool_input?.file_path
} catch {
  process.exit(0)
}
if (!filePath) process.exit(0)

const result = spawnSync(process.execPath, [GATE, filePath], { encoding: 'utf8' })
if (result.status !== 0) {
  // Exit 2 is how Claude Code feeds stderr back into the model's turn (HS2).
  process.stderr.write(result.stderr ?? '')
  process.exit(2)
}
process.exit(0)
