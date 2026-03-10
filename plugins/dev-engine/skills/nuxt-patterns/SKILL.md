---
name: nuxt-patterns
description: >
  Nuxt 3/4 patterns — auto-imports, useFetch, server routes, layers, and module development
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "nuxt patterns"
  - "nuxt 3"
  - "nuxt 4"
  - "nuxt server routes"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "fetch_strategy"
      verify: "Data fetching uses the right primitive for its context (SSR vs client)"
      fail_action: "Apply the useFetch vs useAsyncData vs $fetch decision tree"
    - name: "auto_import_hygiene"
      verify: "No manual imports for Nuxt auto-imported APIs (useState, useFetch, defineEventHandler, etc.)"
      fail_action: "Remove manual imports — Nuxt handles them at build time"
    - name: "server_route_validation"
      verify: "Server routes validate input and return typed responses"
      fail_action: "Add input validation and explicit return types to event handlers"
  on_fail: "Nuxt patterns incomplete — follow the reference"
  on_pass: "Nuxt patterns applied correctly"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# Nuxt Patterns

## Architecture

Nuxt 3 is a full-stack Vue framework built on Nitro (server engine) and Vite (dev server). It unifies SSR, SSG, and SPA in one model. The key mental shift from Nuxt 2: everything is composable-first, auto-imported, and TypeScript-native by default.

Directory roles: `pages/` → file-based routing, `components/` → auto-imported Vue components, `composables/` → auto-imported composables, `server/api/` → Nitro API routes, `server/middleware/` → server-side middleware, `layers/` → composable feature layers.

## Auto-Imports

Nuxt auto-imports from `components/`, `composables/`, `utils/`, and Nuxt's own API surface. No import statements needed for `ref`, `computed`, `useState`, `useFetch`, `useRoute`, `defineEventHandler`, etc.

Rule: if you're writing `import { useFetch } from '#app'` or `import { ref } from 'vue'`, you're doing it wrong. Remove the import — it just works.

Custom composables in `composables/` are auto-imported by filename. `useMyThing.ts` → `useMyThing()` available everywhere.

## Data Fetching Decision Tree

Three primitives, each with a specific role:

| Scenario | Use |
|----------|-----|
| Page-level data, SSR + client hydration | `useFetch` |
| Same data across multiple components | `useAsyncData` with a shared key |
| Client-only fetch (post-mount, no SSR) | `$fetch` in `onMounted` or event handler |
| Form submissions, mutations | `$fetch` directly |

`useFetch` is shorthand for `useAsyncData(url, () => $fetch(url))`. Use `useFetch` for the simple case; reach for `useAsyncData` when you need a custom fetcher, shared deduplication key, or lazy loading.

Caching: both `useFetch` and `useAsyncData` deduplicate by key — same key across components shares one request. Pass `{ key: 'my-key' }` explicitly when the URL isn't unique enough.

## Server Routes

Defined in `server/api/` and `server/routes/`. `server/api/` routes are auto-prefixed with `/api/`.

Each file exports a default `defineEventHandler`. Method routing via filename: `users.get.ts`, `users.post.ts`. Dynamic params: `users/[id].get.ts`.

Input validation belongs in the handler — use `readBody`, `getQuery`, `getRouterParam`, then validate before touching the DB.

Full patterns, layers, module development, runtime config, state management, Nuxt 2→3 migration, and anti-patterns: `references/process.md`
