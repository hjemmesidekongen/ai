---
name: nextjs-app-router
description: >
  Next.js App Router patterns — server components, route handlers, caching,
  layouts, and data fetching.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "nextjs"
  - "app router"
  - "server components"
  - "next.js patterns"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_unnecessary_use_client"
      verify: "'use client' only appears where browser APIs or interactivity is needed"
      fail_action: "Remove 'use client' from components that don't need it"
    - name: "data_fetching_in_server_components"
      verify: "Data fetching happens in Server Components, not in Client Components via useEffect"
      fail_action: "Move fetch calls up to Server Components and pass data as props"
    - name: "caching_explicit"
      verify: "Fetch calls with mutations use cache:'no-store' or revalidate: 0 — no stale data"
      fail_action: "Add explicit cache directive to mutation-adjacent fetches"
  on_fail: "App Router usage has structural issues — fix before merging"
  on_pass: "App Router patterns are sound"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# Next.js App Router

App Router (Next.js 13+) defaults everything to Server Components. The mental model shift: run as much as possible on the server, opt into the client only when you need it.

## Server vs Client Component Decision

**Server Component** (default): data fetching, DB access, sensitive env vars, large dependencies, static or async rendering. No hooks, no event handlers, no browser APIs.

**Client Component** (`'use client'`): `useState`, `useEffect`, event handlers, browser APIs (`window`, `localStorage`), third-party components that require client context.

Rule of thumb: push `'use client'` to the leaves. A Server Component can import a Client Component, but not the reverse — a Client Component cannot import a Server Component directly.

## Data Fetching Patterns

Fetch directly in async Server Components. No API layer needed for internal data.

```tsx
// app/products/page.tsx — Server Component
export default async function ProductsPage() {
  const products = await db.product.findMany(); // direct DB call
  return <ProductList products={products} />;
}
```

Parallel fetching with `Promise.all` avoids waterfalls: `const [user, posts] = await Promise.all([getUser(id), getPosts(id)])`.

## Caching Model

Three caches: fetch cache (static/ISR), router cache (client in-memory), full route cache (server static). Control fetch behavior with the `cache` and `next` options: `cache: 'no-store'` for dynamic, `next: { revalidate: 60 }` for ISR, `next: { tags: ['x'] }` for tag-based invalidation. Use `revalidatePath` / `revalidateTag` for on-demand purges from webhooks or mutations.

## Key Rules

- Fetch in Server Components. Never in Client Components via `useEffect`.
- `loading.tsx` auto-wraps the segment in Suspense — always add one for async routes.
- `error.tsx` must be `'use client'` — it needs the `reset()` callback.
- Route Handlers are for external consumers only. Internal data flows through Server Components.
- Server Actions handle mutations from forms — no separate API route needed.

See `references/process.md` for file conventions, parallel/intercepting routes, middleware, metadata API, server actions, and anti-patterns with examples.
