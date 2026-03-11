---
name: package-managers
description: >
  pnpm workspaces, npm scripts, lockfile management, peer dependencies, and
  node version management. Covers package manager selection, monorepo setup,
  lockfile discipline, peer dep resolution, and version pinning strategy.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "package manager"
  - "pnpm workspaces"
  - "npm scripts"
  - "lockfile"
  - "peer deps"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "lockfile_committed"
      verify: "Lockfile (pnpm-lock.yaml / package-lock.json) is committed and not gitignored"
      fail_action: "Add lockfile to version control — floating installs cause environment drift"
    - name: "no_phantom_deps"
      verify: "All imports reference packages listed in the consuming package's own package.json"
      fail_action: "Add missing direct dep — phantom deps break in strict hoisting modes"
    - name: "peer_deps_declared"
      verify: "Libraries declare peer dependencies; applications pin exact versions in dependencies"
      fail_action: "Move host-provided packages to peerDependencies in library manifests"
    - name: "node_version_pinned"
      verify: ".nvmrc or engines field specifies the Node version used in CI"
      fail_action: "Add .nvmrc and engines.node to align dev and CI environments"
  on_fail: "Package management has environment consistency gaps — address before shipping"
  on_pass: "Package management is sound"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original skill, no port"
---

# package-managers

Reproducible installs depend on three things: the right package manager for the project shape, a committed lockfile, and a pinned Node version. Get all three right before writing a line of application code.

## npm vs pnpm vs yarn

Default to **pnpm** for monorepos. Its content-addressable store saves disk, its strict hoisting mode blocks phantom dependency access, and workspace filtering (`--filter`) is first-class. Use **npm** for single-package libraries where contributor friction matters more than disk efficiency. Avoid **yarn classic** (v1) on new projects — it's in maintenance mode. yarn berry works but the PnP linking model creates friction with many tools.

## Workspace Setup

pnpm workspaces require `pnpm-workspace.yaml` at the root listing package globs. npm workspaces use a `workspaces` array in the root `package.json`. Both resolve cross-workspace deps as symlinks. Shared dev tooling (eslint, typescript, vitest) belongs in the root `devDependencies` — don't repeat it per-package unless versions must differ.

## Lockfile Discipline

Commit the lockfile. Always. Floating installs are a reproducibility failure waiting to happen.

- Run `pnpm install --frozen-lockfile` (or `npm ci`) in CI — never `install` without the flag.
- Resolve lockfile conflicts by checking out one side and re-running `install`, not by hand-editing.
- Regenerate the lockfile intentionally: `pnpm install` after dependency changes, not as a side effect of other commands.

## Peer Dependencies

Libraries declare what the host application must provide via `peerDependencies`. Applications resolve those by listing the actual version in `dependencies`. Mark optional peers with `peerDependenciesMeta: { "<pkg>": { optional: true } }` to avoid install warnings when the peer is not needed. pnpm auto-installs missing peers by default (configurable via `auto-install-peers`).

## Node Version Management

Pin Node via `.nvmrc` (nvm/fnm) or a `volta` key in `package.json`. Also set `engines.node` in `package.json` so `npm install` warns on mismatches. **fnm** is the fastest switcher on macOS (Rust-based, shell hook auto-switches on `.nvmrc`). **volta** pins per-project without shell hooks, useful in team environments where `nvm` adoption is inconsistent.

## Key Rules

- Never `npm install --legacy-peer-deps` to silence errors — fix the actual conflict.
- `devDependencies` in libraries should not bleed into consumer bundles; verify with `npm pack --dry-run`.
- Specify the `files` field in `package.json` to control what gets published — default publishes everything, which leaks source maps and test fixtures.
- `exports` map beats `main`/`module` for dual CJS/ESM packages — it controls subpath imports and blocks deep internal imports.

See `references/process.md` for workspace filtering commands, script lifecycle hooks, cross-platform script patterns, dependency resolution internals, publishing workflow, security audit commands, and monorepo anti-patterns.
