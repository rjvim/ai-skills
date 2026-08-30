#!/usr/bin/env node
// The harness gate. Given the files an agent just changed, runs the roles this
// repo binds to them and reports every failure with its reason.
//
// One script, several callers: a Claude Code hook, a Codex hook and a git
// pre-commit all shim to this, so every tool gets identical behaviour.
//
// Usage: node scripts/harness/gate.mjs [--config <path>] <file> [<file> ...]
// Exits 0 when nothing needed running or everything passed, 1 on any failure.

import { spawnSync } from 'node:child_process'
import { readFileSync, existsSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { rolesForFiles, commandsForRoles, filesForRole, sourceFiles } from './roles.mjs'
import { append, read, repeatingFailures, REPEAT_LIMIT } from './log.mjs'

// A role command containing {files} is scoped to the changed files. Without it
// the role runs repo-wide. `tsc` needs the whole project; a linter does not, and
// scoping it means one file's pre-existing debt cannot block an unrelated edit.
function expandCommand(command, files) {
  if (!command.includes('{files}')) return command
  const quoted = files.map((file) => `'${file.replace(/'/g, "'\\''")}'`).join(' ')
  return command.replace('{files}', quoted)
}

function parseArgs(argv) {
  const files = []
  let configPath = 'harness.json'
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--config') {
      configPath = argv[++i]
      continue
    }
    files.push(argv[i])
  }
  return { configPath, files }
}

function main(argv) {
  const { configPath, files } = parseArgs(argv)
  if (files.length === 0) return 0

  const absoluteConfig = resolve(configPath)
  let config
  try {
    config = JSON.parse(readFileSync(absoluteConfig, 'utf8'))
  } catch (error) {
    process.stderr.write(`harness gate: cannot read ${absoluteConfig}: ${error.message}\n`)
    return 1
  }

  const roles = rolesForFiles(config, files)
  if (roles.length === 0) return 0

  let commands
  try {
    commands = commandsForRoles(config, roles)
  } catch (error) {
    process.stderr.write(`harness gate: ${error.message}\n`)
    return 1
  }

  const cwd = dirname(absoluteConfig)
  const startedAt = Date.now()
  const failures = []

  const scoped = sourceFiles(config, files)

  for (const { role, command: template } of commands) {
    const command = expandCommand(template, filesForRole(config, files, role))
    const result = spawnSync(command, { cwd, shell: true, encoding: 'utf8' })
    if (result.status === 0) continue
    // HS2: the agent gets the role, the command, and the tool's own words —
    // enough to act on without re-running anything.
    const output = `${result.stdout ?? ''}${result.stderr ?? ''}`.trim()
    failures.push(`harness gate: ${role} FAILED (${command})\n${output}`)
  }

  const elapsedSeconds = ((Date.now() - startedAt) / 1000).toFixed(1)
  const budget = config.budgetSeconds
  const failedRoles = failures.map((line) => line.match(/gate: (\S+) FAILED/)?.[1]).filter(Boolean)

  append(cwd, { files: scoped, roles, failed: failedRoles, seconds: Number(elapsedSeconds) })

  // A check that has failed the same way three runs running will not pass on
  // the fourth. Say so, rather than letting an agent keep retrying it.
  //
  // A streak on a file that has since been deleted can never reset, so it would
  // alert forever. Deleted means dealt with.
  const live = (trip) => trip.files.every((file) => existsSync(resolve(cwd, file)))
  for (const trip of repeatingFailures(read(cwd)).filter(live)) {
    process.stderr.write(
      `harness gate: ${trip.role} has failed ${REPEAT_LIMIT} runs in a row on ` +
        `${trip.files.join(', ')} — stop retrying and escalate\n`,
    )
  }

  if (failures.length > 0) {
    process.stderr.write(`${failures.join('\n\n')}\n`)
    process.stderr.write(`harness gate: ${failures.length} of ${commands.length} failed in ${elapsedSeconds}s\n`)
    return 1
  }

  process.stdout.write(`harness gate: ${roles.join(', ')} passed in ${elapsedSeconds}s\n`)
  if (budget && Number(elapsedSeconds) > budget) {
    // HS3 is a criterion, not a suggestion: say so rather than letting the gate
    // quietly become the thing everyone disables.
    process.stderr.write(`harness gate: over the ${budget}s budget — narrow the roles it runs on edit\n`)
  }
  return 0
}

process.exit(main(process.argv.slice(2)))
