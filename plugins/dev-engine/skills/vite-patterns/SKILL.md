---
name: vite-patterns
description: >
  Vite configuration, plugins, HMR, build optimization, and environment
  variables.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "vite"
  - "vite config"
  - "vite plugins"
  - "vite build"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "env_prefix_respected"
      verify: "Only VITE_-prefixed variables are exposed to client code via import.meta.env"
      fail_action: "Move sensitive vars to server-only env files or add VITE_ prefix only where safe"
    - name: "no_commonjs_in_config"
      verify: "vite.config.ts uses ESM imports, not require() or module.exports"
      fail_action: "Convert config to ESM — Vite's config file runs in a native ESM context"
    - name: "manual_chunks_defined_for_large_deps"
      verify: "Large third-party dependencies (>50kB) are split into named chunks in build.rollupOptions"
      fail_action: "Add manualChunks to prevent monolithic vendor bundle"
  on_fail: "Vite configuration has structural issues — fix before shipping"
  on_pass: "Vite configuration follows best practices"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# Vite Patterns

Vite's two-phase architecture (dev server via native ESM, production build via Rollup) means the rules for dev and prod differ. Configure them independently.

## Config Structure

`vite.config.ts` is the single source of truth. Use `defineConfig()` for type safety. Split large configs with helper functions rather than a single deeply nested object. Conditional logic based on `mode` or `command` goes at the top level, not scattered through the config.

Plugins run in order — transform plugins that produce virtual modules should come before plugins that consume them. Use `enforce: 'pre'` or `enforce: 'post'` only when ordering matters and you can't control it via position.

## Plugin Ecosystem

The plugin API (resolveId, load, transform) mirrors Rollup's. Vite-specific additions: `configureServer` for dev middleware, `transformIndexHtml` for HTML injection, `handleHotUpdate` for custom HMR.

For framework integrations, use official plugins: `@vitejs/plugin-react`, `@vitejs/plugin-vue`, `@vitejs/plugin-svelte`. Prefer official over community alternatives for core framework support — the APIs differ subtly.

## Environment Variables

Only `VITE_`-prefixed variables are injected into client bundles via `import.meta.env`. All other `.env` variables stay server-side. Use `.env.local` for secrets — it is gitignored by default.

Mode determines which `.env` file loads: `development` → `.env.development`, `production` → `.env.production`. Override with `--mode staging`.

## Build Optimization

Production builds go through Rollup. Code splitting is automatic for dynamic imports. Manual chunk grouping via `build.rollupOptions.output.manualChunks` controls vendor bundle structure — use it to isolate large deps and improve long-term caching.

Tree shaking works at the module graph level. Side-effect-free packages need `"sideEffects": false` in their `package.json`. For internal code, avoid barrel re-exports that import more than needed.

See `references/process.md` for full API details, proxy config, CSS handling, library mode, SSR, optimizeDeps, multi-page apps, worker support, and anti-patterns.
