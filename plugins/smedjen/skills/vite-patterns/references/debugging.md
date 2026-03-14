# vite-patterns — Debugging Reference

## Common Debugging Scenarios

### HMR not working
**Symptom:** File changes don't hot-reload in the browser. Full page refresh is required, or changes are silently ignored.
**Root cause:** Circular dependencies break HMR's module graph traversal. Alternatively, the HMR WebSocket connection is blocked by a proxy, or a module doesn't accept HMR updates.
**Diagnosis:**
- Open browser console — look for HMR-related messages:
  - `[vite] hot updated: /src/...` = HMR is working for that file
  - `[vite] page reload` = HMR couldn't patch, fell back to full reload
  - No messages at all = WebSocket connection issue
- Check for circular dependencies:
  ```bash
  npx madge --circular src/
  ```
- Check the Network tab > WS tab — verify the Vite HMR WebSocket is connected (usually `ws://localhost:5173/`)
- If behind a reverse proxy, ensure WebSocket upgrade headers are forwarded
- Check if the module has a `import.meta.hot.accept()` boundary — Vue/React plugins add this automatically for components, but manual modules need explicit HMR handling
**Fix pattern:**
```bash
# Fix circular dependencies first
npx madge --circular src/
# Refactor the cycle — extract shared code into a separate module

# If WebSocket is blocked by proxy, configure the HMR connection
```
```ts
// vite.config.ts — explicit HMR config for proxy setups
export default defineConfig({
  server: {
    hmr: {
      host: 'localhost',
      port: 5173,
      protocol: 'ws',
    },
  },
})
```

### Env variable undefined at runtime
**Symptom:** `import.meta.env.SOME_VAR` is `undefined` in client code, even though the `.env` file contains it.
**Root cause:** Vite only exposes env variables prefixed with `VITE_` to client code. Unprefixed variables are server-only (available in `vite.config.ts` via `process.env` but not in browser code).
**Diagnosis:**
- Check the variable name in `.env`: does it start with `VITE_`?
- Add a diagnostic log:
  ```js
  console.log('All env:', import.meta.env)
  ```
  This prints all exposed variables — if your var is missing, it's not prefixed correctly
- Check which `.env` file is loaded — Vite loads `.env`, `.env.local`, `.env.[mode]`, `.env.[mode].local` in order. Run with `--mode` to confirm:
  ```bash
  npx vite --mode staging
  ```
- Check if the env file has syntax issues (no quotes needed for simple values, no spaces around `=`)
**Fix pattern:**
```bash
# .env
VITE_API_URL=https://api.example.com    # exposed to client
SECRET_KEY=abc123                        # NOT exposed to client
```
```ts
// Access in client code
const apiUrl = import.meta.env.VITE_API_URL

// Access in vite.config.ts (server-side, all vars available)
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  console.log(env.SECRET_KEY)  // works here
})
```
If you need a custom prefix instead of `VITE_`, set `envPrefix` in config.

### Build succeeds but runtime fails
**Symptom:** `vite build` completes without errors, but the production app crashes with module resolution errors, missing exports, or unexpected behavior.
**Root cause:** Development uses Vite's native ESM dev server (unbundled), but production uses Rollup (bundled). Dependencies that rely on CommonJS, have side effects, or use Node.js APIs behave differently between the two.
**Diagnosis:**
- Run the production build locally to reproduce:
  ```bash
  npx vite build && npx vite preview
  ```
- Check browser console for errors — common ones:
  - `require is not defined` = CJS dependency not pre-bundled for production
  - `__dirname is not defined` = Node.js API used in client code
  - `Cannot read properties of undefined` = tree-shaking removed a side effect
- Check `optimizeDeps` in config — deps listed here are pre-bundled for dev but might need explicit inclusion for build:
  ```bash
  # Check what Vite pre-bundled in dev
  ls node_modules/.vite/deps/
  ```
- Check if the failing module has a `"browser"` or `"module"` field in its `package.json` that differs from `"main"`
**Fix pattern:**
```ts
// vite.config.ts
export default defineConfig({
  optimizeDeps: {
    include: ['problematic-cjs-package'],  // force pre-bundling
  },
  build: {
    commonjsOptions: {
      include: [/problematic-cjs-package/, /node_modules/],
    },
  },
  // For Node.js API polyfills (if truly needed in browser)
  resolve: {
    alias: {
      path: 'path-browserify',
    },
  },
})
```

### Dependency pre-bundling stale
**Symptom:** After installing or updating a dependency, Vite still serves the old version. Or a newly added dependency fails to load with a bare import error.
**Root cause:** Vite caches pre-bundled dependencies in `node_modules/.vite`. After dependency changes, this cache can be stale. Vite auto-detects changes to `package.json` lockfile, but edge cases (manual `node_modules` edits, monorepo hoisting changes) can bypass detection.
**Diagnosis:**
- Check the pre-bundle cache:
  ```bash
  ls -la node_modules/.vite/deps/
  ```
- Look for the dependency in the cached files — is it present? Is it the right version?
- Check the Vite dev server startup logs — it prints which deps it pre-bundles:
  ```
  Pre-bundling dependencies:
    react, react-dom, ...
  ```
- If a new dep is missing from this list, Vite didn't detect it
**Fix pattern:**
```bash
# Nuclear option — delete the cache and restart
rm -rf node_modules/.vite
npx vite

# Or force re-optimization on next start
npx vite --force
```
```ts
// For persistent issues, explicitly include the dependency
export default defineConfig({
  optimizeDeps: {
    include: ['new-package'],
    // Or exclude if pre-bundling breaks it
    exclude: ['package-with-issues'],
  },
})
```

### CSS/PostCSS not processing
**Symptom:** PostCSS plugins (autoprefixer, nesting, etc.) aren't applied. CSS is served raw without transformations.
**Root cause:** Vite has built-in PostCSS support but requires a `postcss.config.js` (or `.postcssrc`) in the project root. If the config is missing, misnamed, or in the wrong directory, PostCSS processing is skipped silently.
**Diagnosis:**
- Run Vite with debug logging to see the CSS pipeline:
  ```bash
  DEBUG=vite:css npx vite
  ```
  This shows which PostCSS config was found and which plugins are loaded
- Check for the PostCSS config file — Vite looks for `postcss.config.js`, `postcss.config.cjs`, `postcss.config.mjs`, `.postcssrc`, `.postcssrc.json`, `.postcssrc.yml` in the project root
- Verify PostCSS plugins are installed:
  ```bash
  ls node_modules/autoprefixer node_modules/postcss-nesting 2>/dev/null
  ```
- Check if `css.postcss` is set in `vite.config.ts` — inline config overrides config files
- In the browser, inspect the processed CSS: DevTools > Sources > find the CSS module — are vendor prefixes present? Is nesting resolved?
**Fix pattern:**
```js
// postcss.config.js
export default {
  plugins: {
    autoprefixer: {},
    'postcss-nesting': {},
  },
}
```
```ts
// Or inline in vite.config.ts
import autoprefixer from 'autoprefixer'

export default defineConfig({
  css: {
    postcss: {
      plugins: [autoprefixer()],
    },
  },
})
```

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| `DEBUG=vite:*` | Verbose Vite internals logging | `DEBUG=vite:* npx vite` |
| `DEBUG=vite:css` | CSS/PostCSS pipeline debugging | `DEBUG=vite:css npx vite` |
| `DEBUG=vite:hmr` | HMR event tracing | `DEBUG=vite:hmr npx vite` |
| `npx vite --force` | Force dependency re-optimization | Run from project root |
| `npx vite preview` | Serve production build locally | `npx vite build && npx vite preview` |
| `npx madge --circular` | Detect circular dependencies | `npx madge --circular src/` |
| `node_modules/.vite/deps/` | Inspect pre-bundled dependency cache | `ls node_modules/.vite/deps/` |
| Browser DevTools Network > WS | Check HMR WebSocket connection | Filter by WS in Network tab |
| `npx vite --debug` | General debug output | `npx vite --debug` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
