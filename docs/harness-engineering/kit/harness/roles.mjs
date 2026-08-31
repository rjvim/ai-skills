// Pure role resolution. No filesystem, no process spawning — so it can be unit
// tested in the project's own suite even when that suite runs sandboxed. The
// runner (gate.mjs) owns all the I/O.

/**
 * The changed files this repo's gate cares about — the ones a per-file role
 * should be pointed at (HS4).
 */
export function sourceFiles(config, files) {
  return files.filter((file) => editRoutes(config).some((route) => matches(route, file)))
}

function editRoutes(config) {
  const routes = config?.onEdit?.routes
  if (Array.isArray(routes)) return routes
  return [{ extensions: config?.onEdit?.extensions ?? [], roles: config?.onEdit?.roles ?? [] }]
}

function matches(route, file) {
  const extensionMatch = (route.extensions ?? []).some((ext) => file.endsWith(ext))
  const prefixMatch = !route.prefixes || route.prefixes.some((prefix) => file.startsWith(prefix))
  return extensionMatch && prefixMatch
}

export function filesForRole(config, files, role) {
  return files.filter((file) =>
    editRoutes(config).some((route) => route.roles?.includes(role) && matches(route, file)),
  )
}

/**
 * Which roles a set of changed files should trigger.
 * Returns [] when no changed file is one the gate cares about (HS4).
 */
export function rolesForFiles(config, files) {
  const seen = new Set()
  const ordered = []
  for (const route of editRoutes(config)) {
    if (!files.some((file) => matches(route, file))) continue
    for (const role of route.roles ?? []) {
      if (seen.has(role)) continue
      seen.add(role)
      ordered.push(role)
    }
  }
  return ordered
}

/**
 * Bind role names to the commands this repo maps them to (HS5).
 * A role with no command is a broken config, not a silent skip.
 */
export function commandsForRoles(config, roles) {
  return roles.map((role) => {
    const command = config?.roles?.[role]
    if (!command) {
      throw new Error(
        `harness config: onEdit lists role "${role}" but "roles" has no command for it`,
      )
    }
    return { role, command }
  })
}
