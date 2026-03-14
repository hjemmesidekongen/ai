# nuxt-patterns — Debugging Reference

## Common Debugging Scenarios

### useFetch fires twice (SSR + client)
**Symptom:** Network tab shows the same API request firing on the server during SSR and again on the client after hydration. Data flickers or components re-render unnecessarily.
**Root cause:** `useFetch` deduplicates by default using its key, but if the key changes between SSR and client (dynamic params, reactive refs not yet resolved), the client considers it a new request.
**Diagnosis:**
- Open Nuxt DevTools > Fetch tab — check if the same endpoint appears twice with different keys
- Check the `key` option: if omitted, Nuxt auto-generates from the URL. Dynamic segments that differ between SSR and client produce different keys
- Inspect `__NUXT_DATA__` in the page source (View Source) — confirm the payload is present. If missing, the client refetches
- Add `console.log` in the `useFetch` callback and check server terminal vs browser console
**Fix pattern:**
```js
// Provide an explicit stable key
const { data } = useFetch(`/api/users/${id}`, {
  key: `user-${id}`,  // stable across SSR and client
})

// If you only need server-side data, use lazy: false (default) and the client
// will use the serialized payload without refetching

// If the fetch truly should only run client-side:
const { data } = useFetch('/api/client-only', {
  server: false,
})
```

### Auto-import not resolving
**Symptom:** TypeScript errors like "Cannot find name 'useRoute'" or "ref is not defined" in components, even though auto-imports should handle them.
**Root cause:** The `.nuxt/imports.d.ts` type declarations are stale or missing. The dev server needs to regenerate them.
**Diagnosis:**
- Check if `.nuxt/imports.d.ts` exists: `ls .nuxt/imports.d.ts`
- Open the file and search for the missing import — if it's absent, the module isn't registered
- Check `nuxt.config.ts` for `imports.dirs` or custom module registration
- For composables in custom directories, verify the directory is listed in `imports.dirs`
- Run `npx nuxi prepare` to regenerate type declarations
**Fix pattern:**
```bash
# Regenerate .nuxt types
npx nuxi prepare

# If still failing, clean and regenerate
rm -rf .nuxt
npx nuxi prepare
```
```ts
// For custom composables directory, register in nuxt.config.ts
export default defineNuxtConfig({
  imports: {
    dirs: ['composables/**', 'utils/**'],
  },
})
```

### Hydration mismatch from useState misuse
**Symptom:** Console warning: "Hydration text/attribute mismatch" or visible content flicker after page load. Content rendered on server differs from client.
**Root cause:** `useState` wasn't used for shared state that needs to transfer from SSR to client. Using `ref()` directly creates fresh state on the client, causing mismatches.
**Diagnosis:**
- View page source (Ctrl+U) and compare the server-rendered HTML against what the client renders
- Check `__NUXT_DATA__` script tag in the HTML — search for the state key. If missing, `useState` wasn't used or the key is wrong
- Open Nuxt DevTools > Payload tab to inspect the transferred state
- Search the component for `ref()` or `reactive()` holding data that should persist across SSR/client boundary
**Fix pattern:**
```js
// Wrong — creates new state on client, loses SSR value
const count = ref(0)

// Correct — state transfers from SSR to client via payload
const count = useState('count', () => 0)
```
If the data comes from an API, prefer `useFetch`/`useAsyncData` which handle payload transfer automatically.

### Nitro server route 404
**Symptom:** API calls to `/api/...` return 404 in production, but work in development.
**Root cause:** The route file isn't in the correct directory, has a naming issue, or the build output doesn't include it.
**Diagnosis:**
- Verify the file exists at `server/api/` or `server/routes/` with correct naming: `server/api/users.get.ts` for `GET /api/users`
- Test locally with curl: `curl -v http://localhost:3000/api/users`
- After building (`npx nuxi build`), check the compiled route table:
  ```bash
  ls .output/server/routes/
  # or check the Nitro route manifest
  cat .output/nitro.json | grep -A5 routes
  ```
- Check for conflicting route files (e.g., `users.ts` and `users/index.ts`)
- Verify the HTTP method suffix matches: `.get.ts`, `.post.ts`, `.delete.ts`
**Fix pattern:**
```
# Correct file structure
server/
  api/
    users.get.ts       → GET  /api/users
    users.post.ts      → POST /api/users
    users/[id].get.ts  → GET  /api/users/:id
  routes/
    health.ts          → GET  /health (no /api prefix)
```
```ts
// server/api/users.get.ts
export default defineEventHandler(async (event) => {
  return { users: [] }
})
```

### Runtime config not available in client
**Symptom:** `useRuntimeConfig()` returns `undefined` for a key that's set in `nuxt.config.ts`, but only on the client side. Server-side access works.
**Root cause:** Only keys under `runtimeConfig.public` are exposed to the client. Top-level `runtimeConfig` keys are server-only for security.
**Diagnosis:**
- Check `nuxt.config.ts` — is the key under `runtimeConfig` (server-only) or `runtimeConfig.public` (both)?
- In the browser console: `console.log(useRuntimeConfig())` — only `public` keys appear
- Check if the env variable override follows the naming convention: `NUXT_PUBLIC_` prefix for public keys
- Inspect `__NUXT_DATA__` payload for the `config` section
**Fix pattern:**
```ts
// nuxt.config.ts
export default defineNuxtConfig({
  runtimeConfig: {
    secretKey: '',           // server-only — NUXT_SECRET_KEY env var
    public: {
      apiBase: '',           // client + server — NUXT_PUBLIC_API_BASE env var
    },
  },
})
```
```ts
// Usage in component (client-safe)
const config = useRuntimeConfig()
console.log(config.public.apiBase)  // works on both client and server
// console.log(config.secretKey)    // undefined on client, correct on server
```

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Nuxt DevTools | Inspect routes, components, composables, payload, fetch state | Auto-enabled in dev; opens via bottom-bar icon |
| Nuxt DevTools Fetch tab | Trace all `useFetch`/`useAsyncData` calls with keys and status | DevTools > Fetch |
| Nuxt DevTools Payload tab | Inspect SSR-to-client state transfer | DevTools > Payload |
| `npx nuxi prepare` | Regenerate `.nuxt/` types and auto-imports | Run from project root |
| `npx nuxi analyze` | Bundle analysis for production build | `npx nuxi analyze` |
| `npx nuxi devtools enable` | Enable DevTools if not auto-enabled | Run from project root |
| View Source + `__NUXT_DATA__` | Verify SSR payload and hydration data | Ctrl+U in browser, search for `__NUXT_DATA__` |
| `curl -v` | Test Nitro server routes directly | `curl -v http://localhost:3000/api/route` |
| `.output/` inspection | Verify production build includes routes and assets | `ls .output/server/routes/` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
