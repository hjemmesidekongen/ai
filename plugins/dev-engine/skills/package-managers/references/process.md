# package-managers — Process Reference

Extended reference for workspace setup, script patterns, lockfile operations, peer dependency resolution, Node version management, publishing, security, and monorepo patterns.

---

## pnpm Workspaces

### pnpm-workspace.yaml

```yaml
packages:
  - "apps/*"
  - "packages/*"
  - "tools/*"
```

Place at the repo root. All matched directories with a `package.json` become workspace packages. pnpm links them via symlinks in `node_modules`.

### Workspace filtering

```bash
# Run a script in one package
pnpm --filter @acme/ui build

# Run in a package and all its dependencies
pnpm --filter @acme/app... build

# Run in all packages that depend on @acme/ui
pnpm --filter ..@acme/ui test

# Run in all changed packages (requires git)
pnpm --filter '[HEAD~1]' test

# Run in parallel across all packages
pnpm -r --parallel build
```

### Shared dependencies

Install shared dev tools at the root:

```bash
pnpm add -D -w typescript eslint vitest
```

The `-w` flag targets the workspace root. Per-package overrides are fine when versions must differ, but avoid duplicating the same version across many packages — it defeats the store.

### Cross-workspace references

```json
{
  "dependencies": {
    "@acme/ui": "workspace:*"
  }
}
```

`workspace:*` resolves to the local package during development and is replaced with the actual version on publish.

---

## npm Workspaces

```json
{
  "workspaces": ["apps/*", "packages/*"]
}
```

npm workspaces hoist everything to the root `node_modules` by default. This means phantom deps are easy to introduce — an import works locally but fails in isolation. No equivalent of pnpm's strict mode. Use `npm run --workspace=packages/ui build` or `-w packages/ui` shorthand.

---

## npm Scripts

### Lifecycle hooks

npm runs these automatically around standard commands:

| Hook | Triggers before/after |
|------|-----------------------|
| `preinstall` / `postinstall` | `npm install` |
| `prepare` | `npm install`, `npm publish`, `git checkout` (if listed in deps) |
| `prepublishOnly` | `npm publish` only (use this, not `prepublish`) |
| `prepack` / `postpack` | `npm pack`, `npm publish` |
| `pretest` / `posttest` | `npm test` |

Any script gets `pre<name>` and `post<name>` hooks automatically.

### Cross-platform scripts

Avoid shell-specific syntax in `package.json` scripts — they break on Windows CI.

```json
{
  "scripts": {
    "clean": "rimraf dist",
    "copy": "copyfiles -u 1 src/**/*.json dist",
    "env": "cross-env NODE_ENV=production node server.js"
  }
}
```

Key packages: `rimraf` (rm -rf), `copyfiles` (cp), `cross-env` (env vars), `mkdirp` (mkdir -p), `shx` (POSIX commands via shelljs).

### Parallel and sequential scripts

```json
{
  "scripts": {
    "build": "npm run build:types && npm run build:js",
    "build:all": "concurrently \"npm run build:types\" \"npm run build:js\""
  }
}
```

`concurrently` runs scripts in parallel with labeled output. `npm-run-all` provides `run-s` (sequential) and `run-p` (parallel) as clean alternatives.

### Passing args to scripts

```bash
npm run build -- --watch
pnpm build --watch  # pnpm passes args directly without --
```

---

## Lockfile Management

### When to commit

Always. No exceptions for:
- `pnpm-lock.yaml`
- `package-lock.json`
- `yarn.lock`

The lockfile is your bill of materials. Without it, `npm install` resolves to whatever the latest compatible version is at install time — different machines, different deps.

### CI installs

```bash
# npm
npm ci                        # reads package-lock.json, fails if out of sync

# pnpm
pnpm install --frozen-lockfile  # equivalent — fails if lockfile is stale

# yarn
yarn install --immutable       # yarn berry equivalent
```

Never run `npm install` in CI — it can silently update the lockfile.

### Resolving conflicts

Do not hand-edit lockfiles. When you get a merge conflict:

```bash
# Option 1: Take one side and regenerate
git checkout origin/main -- pnpm-lock.yaml
pnpm install

# Option 2: Delete and regenerate (nuclear)
rm pnpm-lock.yaml
pnpm install
```

Commit the regenerated lockfile as a dedicated merge resolution commit.

### Lockfile regeneration triggers

Intentional regeneration is appropriate when:
- Upgrading dependency versions (`pnpm up`)
- Adding or removing packages
- Changing `overrides`/`resolutions`
- Syncing after a long-lived branch diverge

---

## Peer Dependencies

### How they work

`peerDependencies` declares a contract: "this library requires the host app to provide X at version Y." The library does not install the peer — the consuming project does.

```json
{
  "name": "@acme/button",
  "peerDependencies": {
    "react": ">=18.0.0",
    "react-dom": ">=18.0.0"
  }
}
```

### peerDependenciesMeta

Mark peers optional when the feature that needs them is opt-in:

```json
{
  "peerDependencies": {
    "react": ">=18.0.0",
    "vue": ">=3.0.0"
  },
  "peerDependenciesMeta": {
    "vue": { "optional": true }
  }
}
```

Without `optional: true`, missing peers generate warnings on every install.

### Auto-install behavior

- **pnpm**: auto-installs missing peers by default. Configurable via `.npmrc`: `auto-install-peers=false`.
- **npm 7+**: auto-installs peers. npm 6 did not.
- **yarn**: does not auto-install — consumer must add peers explicitly.

### Common peer dep errors

`ERESOLVE` (npm) or peer conflict warnings usually mean two packages want incompatible versions of a shared peer. Fix strategies in order of preference:
1. Upgrade one of the conflicting packages
2. Use `overrides` (npm/pnpm) or `resolutions` (yarn) to force a single version
3. `--legacy-peer-deps` is a last resort that masks the conflict — avoid on new installs

---

## Node Version Management

### Tools compared

| Tool | Install method | Auto-switch | Speed | Best for |
|------|---------------|-------------|-------|----------|
| nvm | curl/brew | Shell hook + `.nvmrc` | Slow (bash) | Ubiquitous, well-documented |
| fnm | brew/cargo | Shell hook + `.nvmrc` | Fast (Rust) | macOS/Linux dev machines |
| volta | installer | Transparent | Fast | Teams, CI, pinned per-project |
| asdf | brew | `.tool-versions` | Medium | Polyglot version management |

### .nvmrc

```
20.12.0
```

nvm and fnm both read this. Add `--use-nvmrc` to CI setup or use the explicit version in the CI config.

### engines field

```json
{
  "engines": {
    "node": ">=20.0.0",
    "pnpm": ">=9.0.0"
  }
}
```

npm warns when the running Node version doesn't satisfy this range. Set `engine-strict=true` in `.npmrc` to make it a hard failure.

### volta pinning

```json
{
  "volta": {
    "node": "20.12.0",
    "pnpm": "9.4.0"
  }
}
```

Volta pins the exact version per-project. Anyone with Volta installed gets the right version automatically, no shell hook needed.

---

## Dependency Resolution

### Hoisting

npm and yarn classic hoist all deps to the root `node_modules`. This allows phantom dep access (importing a package you didn't declare). pnpm uses a virtual store and symlinks — only declared deps are accessible by default.

### Phantom dependencies

A phantom dep is one you import but didn't declare in your `package.json`. It works because it was hoisted by another package's install. It breaks when:
- The package that pulled it in is removed or updates
- You move to a strict hoisting environment (pnpm strict, isolated node_modules)

Fix: declare every import as an explicit direct dependency.

### pnpm strict mode

```ini
# .npmrc
node-linker=isolated
```

Strict isolation — each package only sees its own declared deps. Maximally safe, but some packages with sloppy peer dep declarations break. Start with default pnpm hoisting; move to isolated if phantom deps are a recurring issue.

---

## Publishing

### prepublishOnly

```json
{
  "scripts": {
    "prepublishOnly": "npm run build && npm run test"
  }
}
```

Runs before `npm publish`. Use `prepublishOnly` not `prepublish` — `prepublish` also runs on `npm install` in older npm versions, which is surprising.

### files field

```json
{
  "files": ["dist", "src", "!**/*.test.*", "!**/*.spec.*"]
}
```

Allowlist of what gets included in the published tarball. Without this, everything is published except `.gitignore` entries — that leaks source maps, test fixtures, and internal tooling. Always set it. Verify with `npm pack --dry-run`.

### exports map

```json
{
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    },
    "./utils": {
      "import": "./dist/utils.mjs",
      "require": "./dist/utils.cjs"
    }
  }
}
```

The `exports` map is the modern entry point definition. It:
- Enables dual CJS/ESM packages
- Blocks deep imports consumers shouldn't use (no `import from 'pkg/internal/thing'`)
- Supports subpath exports for tree-shaking

Keep `main` and `module` for older bundlers that don't read `exports` yet.

### Changesets for monorepos

```bash
# Add a changeset after making changes
pnpm changeset

# Version all changed packages
pnpm changeset version

# Publish
pnpm publish -r --access public
```

Changesets tracks what changed and what kind of version bump it warrants (major/minor/patch). Integrates with GitHub Actions for automated releases.

---

## Security

### npm audit

```bash
npm audit              # show vulnerabilities
npm audit --json       # machine-readable output for CI
npm audit fix          # auto-fix non-breaking updates
npm audit fix --force  # also apply breaking updates (review output carefully)
```

Run `npm audit` in CI and fail on high/critical severity. Treat it as a signal, not a blocker — many advisories are in dev-only paths that don't reach production.

### overrides and resolutions

Force a specific version of a transitive dependency to patch a vulnerability:

```json
// npm — package.json
{
  "overrides": {
    "lodash": "^4.17.21"
  }
}
```

```json
// pnpm — package.json
{
  "pnpm": {
    "overrides": {
      "lodash": "^4.17.21"
    }
  }
}
```

```json
// yarn — package.json
{
  "resolutions": {
    "lodash": "^4.17.21"
  }
}
```

Pin to the patched version and add a comment explaining why. Remove the override when the direct dep upgrades.

---

## Monorepo Patterns

### Root package.json scripts

```json
{
  "scripts": {
    "build": "pnpm -r build",
    "test": "pnpm -r test",
    "lint": "pnpm -r lint",
    "dev": "pnpm --filter @acme/app dev"
  }
}
```

`-r` (recursive) runs the script in all packages that define it. Use `--parallel` to run in parallel; omit for sequential (respects topological order for build).

### Internal package versioning

Options for internal packages in a monorepo:
- **`workspace:*`** — always resolves to local, version irrelevant during dev. Best for internal-only packages.
- **Fixed versioning** — all packages share the same version number, bumped together (lerna fixed mode, changesets with fixed groups).
- **Independent versioning** — each package has its own version. More accurate, more overhead.

### Turborepo caching

```json
// turbo.json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "test": {
      "dependsOn": ["build"]
    }
  }
}
```

Turbo caches task outputs keyed to inputs. On cache hit, the task is skipped. Dramatically speeds up CI for large monorepos. Pairs with pnpm workspaces.

---

## Common Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `npm install` in CI | Resolves new versions, breaks reproducibility | Use `npm ci` / `pnpm install --frozen-lockfile` |
| Gitignoring the lockfile | Every install is different | Commit the lockfile |
| `--legacy-peer-deps` habitually | Masks real conflicts | Fix the underlying conflict |
| Hand-editing the lockfile | Invalid state, conflicts regenerated | Delete + reinstall |
| No `files` field | Publishes source, tests, configs | Allowlist only `dist` and public `src` |
| Phantom deps in pnpm repo | Breaks strict mode, hidden coupling | Declare all direct imports explicitly |
| Same peer dep in `dependencies` for a library | Consumers get duplicate instances | Move to `peerDependencies` |
| Different Node versions in dev vs CI | "Works on my machine" bugs | `.nvmrc` + `engines` + CI matrix pinned version |
| `devDependencies` in library's `dependencies` | Bloats consumer installs | Audit and move to `devDependencies` |
| Missing `prepublishOnly` build step | Publishing un-built source | Add build + test to `prepublishOnly` |
