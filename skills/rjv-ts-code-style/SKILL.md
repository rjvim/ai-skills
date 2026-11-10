---
name: rjv-ts-code-style
description: How TypeScript and TSX are written and wired in a pnpm monorepo - imports (package names, `./`, `@/` for bundled code, `#src/` for Node-run code, never `../`), kebab-case files, a shared tsconfig package, strict TypeScript without enums or any. Use when writing, moving, converting or reviewing .ts/.tsx files, package.json or tsconfig.json. A repo's own skill names which of its packages are Node-run or bundled.
---

# TypeScript code style

Strict TypeScript and TSX, written so a file can move without breaking and the same code runs in Node, a bundler and a Worker. Apply when you write or move a file; review checks it.

## 1. Imports

Pick by where the target lives:

| Target | Write | Example |
|---|---|---|
| a file in the same folder | `./` | `import { esc } from './svg.ts'` |
| another package | its package name | `import { bind } from '@acme/engine'` |
| elsewhere in a package a bundler builds (browser code, apps) | `@/` (tsconfig `paths`) | `import { layoutOf } from '@/grid/input.ts'` |
| elsewhere in a package Node runs (CLI, servers, libraries Node imports) | `#src/` (package.json `imports`) | `import { StaleBase } from '#src/store.ts'` |

- **Never `../`.** One `../` today becomes `../../../` after the next move, and it hides where the file is.
- Node runs `.ts` by stripping types and never reads tsconfig `paths`. So `@/` in a Node-run package passes the type-check and fails at run time with "module not found"; Node-run packages use `#src/`.
- Declare the Node alias once per package: `"imports": { "#src/*": "./src/*" }`. Node (14.6+), TypeScript, Vitest and esbuild all read it. It must start with `#`: an `@` name means an npm scope.
- Write the real extension (`.ts`, `.tsx`) on every relative and aliased import. Node needs it; `allowImportingTsExtensions` allows it.
- Never reach into another package's files (`@acme/engine/src/...`): import what its `exports` offers, and add to that `exports` when something is missing.

Done when `rg "(from|import\()\s*['\"]\.\./" --glob '*.{ts,tsx}'` finds nothing and every import is a package name, `./`, `@/` or `#src/`.

## 2. Packages and files

- Private internal packages share one scope (`@<repo>/<name>`); only what is published carries the publishing scope.
- Files are kebab-case: `grid-canvas.tsx`, `folder-store.ts`. Exported symbols keep their case (`GridCanvas`, `folderStore`).
- A package's `exports` field names its entries; no barrel `index.ts` that re-exports half the package.
- No Node built-in import (`node:fs`, or bare `fs`) outside a package's `src/node/` entry (`<pkg>/node`), so the rest runs in a browser or a Worker.

## 3. tsconfig

- Shared config is a package (the turborepo pattern), e.g. `packages/tsconfig` with `base.json`, `node.json` (`module`/`moduleResolution` `nodenext`), `react.json` (`bundler`, `jsx: react-jsx`, DOM libs).
- Each app and package has a short `tsconfig.json` extending one of them, adding only its own options:

  ```json
  { "extends": "@acme/tsconfig/node.json", "include": ["src", "test"] }
  ```
- The config package is a `workspace:*` devDependency of each package that extends it. No relative `extends` (`../../tsconfig.base.json`).
- Each package has `"type-check": "tsc --noEmit -p ."`. Project references (`tsc -b`) refuse `noEmit`, so they are not used.

## 4. TypeScript itself

- `strict`, `noUncheckedIndexedAccess`, `erasableSyntaxOnly` (what Node's type stripping can run): no `enum`, no `namespace`, no constructor parameter properties. Use a union of string literals or an `as const` object.
- No `any`. Parsed JSON or YAML is `unknown`, narrowed before use.
- Exported functions declare parameter and return types.
- Comments say why, or what a reader cannot see in the code; one line where one line does.

## Related

- React component conventions: the repo's components skill (components.build: parts, controlled and uncontrolled state, `data-slot`).
