# Nuxt Patterns — Reference

## Directory Structure

```
nuxt-app/
├── app.vue                    # Root component (optional — pages/ takes over if present)
├── nuxt.config.ts             # Central config: modules, runtimeConfig, vite, nitro
├── pages/                     # File-based routing (auto-registered)
│   ├── index.vue
│   ├── users/
│   │   ├── index.vue          # /users
│   │   └── [id].vue           # /users/:id
├── components/                # Auto-imported Vue components
│   └── ui/
│       └── Button.vue         # Available as <UiButton /> or <ui-button />
├── composables/               # Auto-imported composables
│   └── useAuth.ts             # Available as useAuth() everywhere
├── utils/                     # Auto-imported utility functions
│   └── formatDate.ts          # Available as formatDate() everywhere
├── layouts/                   # Named layouts
│   └── default.vue
├── middleware/                # Route middleware (client + server)
│   └── auth.ts
├── server/
│   ├── api/                   # Routes prefixed /api/
│   │   ├── users.get.ts       # GET /api/users
│   │   └── users/[id].get.ts  # GET /api/users/:id
│   ├── routes/                # Non-/api routes
│   ├── middleware/            # Server-only middleware (runs on every request)
│   └── plugins/               # Nitro plugins (server lifecycle)
├── plugins/                   # Vue plugins (client + server)
├── public/                    # Static assets (not processed)
└── assets/                    # Processed assets (Vite)
```

Component naming: subdirectory prefix is auto-applied. `components/base/Button.vue` → `<BaseButton />`. Disable with `{ pathPrefix: false }` in nuxt.config.

---

## Auto-Imports in Depth

### What gets auto-imported

- All Vue reactivity APIs: `ref`, `computed`, `watch`, `reactive`, `toRef`, etc.
- All Nuxt composables: `useFetch`, `useAsyncData`, `useState`, `useRoute`, `useRouter`, `useCookie`, `useHead`, `useNuxtApp`, etc.
- Everything in `composables/` and `utils/` (one level deep by default)
- Server-side: `defineEventHandler`, `readBody`, `getQuery`, `createError`, `H3Error`, etc.

### Extending auto-imports

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  imports: {
    dirs: ['composables/**', 'utils/**'], // recursive scan
    presets: [
      { from: 'date-fns', imports: ['format', 'parseISO'] }
    ]
  }
})
```

### TypeScript support

Nuxt generates `.nuxt/types/` including an auto-imports type file. Run `nuxi prepare` after adding new composables to get type inference without restarting dev.

---

## Data Fetching Patterns

### useFetch

```ts
// Basic — SSR-safe, auto-deduplicates by URL
const { data, pending, error, refresh } = await useFetch('/api/users')

// With options
const { data } = await useFetch('/api/users', {
  query: { page: 1, limit: 10 },
  pick: ['id', 'name'],           // transform response
  transform: (res) => res.data,   // extract nested data
  lazy: true,                     // don't block navigation
  server: false,                  // client-only fetch
})

// Typed
const { data } = await useFetch<User[]>('/api/users')

// Reactive key (re-fetches when ref changes)
const page = ref(1)
const { data } = await useFetch('/api/users', {
  query: { page },
  watch: [page],
})
```

### useAsyncData

Use when you need a custom fetcher, shared deduplication key, or more control over caching:

```ts
// Custom fetcher
const { data } = await useAsyncData('users', () =>
  $fetch<User[]>('/api/users', { query: { page: 1 } })
)

// Shared key — same data, single request, shared across components
const { data: user } = await useAsyncData(`user-${id}`, () => fetchUser(id))

// Lazy (don't block navigation, show loading state instead)
const { data, pending } = await useAsyncData('config', () => fetchConfig(), {
  lazy: true,
  default: () => ({}),  // fallback while loading
})
```

### $fetch

Direct Nitro fetch — no SSR deduplication, no caching. Use for mutations and client-only calls:

```ts
// Form submission
async function submit() {
  await $fetch('/api/users', {
    method: 'POST',
    body: formData.value,
  })
}

// Client-only data fetch (onMounted)
onMounted(async () => {
  userData.value = await $fetch('/api/me')
})
```

### Caching and deduplication

Both `useFetch` and `useAsyncData` use a key to deduplicate. Same key = same request shared across the component tree. Default key for `useFetch` is the URL + serialized options. Override explicitly when URLs contain dynamic content that would create false duplicates.

### Error handling in data fetching

```ts
const { data, error } = await useFetch('/api/users')

// error is Ref<FetchError | null>
if (error.value) {
  // error.value.statusCode, error.value.message
}

// Or throw and let error.vue catch it
const { data } = await useFetch('/api/users', {
  onResponseError({ response }) {
    throw createError({ statusCode: response.status, message: 'Fetch failed' })
  }
})
```

---

## Server Routes

### Defining handlers

```ts
// server/api/users.get.ts
export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const users = await db.users.findMany({ limit: Number(query.limit) ?? 20 })
  return users // Nuxt serializes to JSON automatically
})

// server/api/users/[id].get.ts
export default defineEventHandler(async (event) => {
  const id = getRouterParam(event, 'id')
  const user = await db.users.findById(id)
  if (!user) {
    throw createError({ statusCode: 404, statusMessage: 'User not found' })
  }
  return user
})

// server/api/users.post.ts
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  // validate body before use
  const user = await db.users.create(body)
  setResponseStatus(event, 201)
  return user
})
```

### Input validation

Nuxt doesn't bundle a validation library — add one explicitly:

```ts
import { z } from 'zod'

const CreateUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

export default defineEventHandler(async (event) => {
  const raw = await readBody(event)
  const result = CreateUserSchema.safeParse(raw)

  if (!result.success) {
    throw createError({
      statusCode: 422,
      statusMessage: 'Validation failed',
      data: result.error.flatten(),
    })
  }

  return db.users.create(result.data)
})
```

### Server middleware

Runs before every matching request. Place in `server/middleware/`:

```ts
// server/middleware/auth.ts
export default defineEventHandler(async (event) => {
  const token = getCookie(event, 'auth-token') ?? getHeader(event, 'authorization')?.replace('Bearer ', '')

  if (!token && event.path.startsWith('/api/protected')) {
    throw createError({ statusCode: 401, statusMessage: 'Unauthorized' })
  }

  if (token) {
    event.context.user = await verifyToken(token)
  }
})
```

Access in handlers via `event.context.user`.

### Route middleware (client-side)

```ts
// middleware/auth.ts (client route guard)
export default defineNuxtRouteMiddleware((to) => {
  const { loggedIn } = useAuth()
  if (!loggedIn.value) {
    return navigateTo('/login')
  }
})
```

Apply per-page: `definePageMeta({ middleware: 'auth' })`.

---

## Nuxt Layers

Layers are composable Nuxt configurations — think shareable base configs with their own components, composables, pages, and config.

```ts
// nuxt.config.ts — consuming a layer
export default defineNuxtConfig({
  extends: [
    './layers/ui',
    '@my-org/nuxt-base-layer',  // npm package
  ]
})
```

Layer structure mirrors a Nuxt app. Components, composables, and utils in a layer are auto-imported with the same rules. Layer config is deep-merged. Pages from layers are added to the routing tree.

Use layers for: shared UI component library, auth layer, analytics layer, multi-tenant base config.

---

## Module Development

A Nuxt module is a function that runs at build time to extend the Nuxt config, add components, inject composables, or register plugins.

```ts
// my-module/src/module.ts
import { defineNuxtModule, addPlugin, createResolver } from '@nuxt/kit'

export default defineNuxtModule({
  meta: {
    name: 'my-module',
    configKey: 'myModule',
    compatibility: { nuxt: '^3.0.0' },
  },
  defaults: {
    apiUrl: 'https://api.example.com',
  },
  setup(options, nuxt) {
    const resolver = createResolver(import.meta.url)

    // Add a plugin
    addPlugin(resolver.resolve('./runtime/plugin'))

    // Inject composable
    addImports({ name: 'useMyModule', from: resolver.resolve('./runtime/composables/useMyModule') })

    // Expose config to runtime
    nuxt.options.runtimeConfig.public.myModuleApiUrl = options.apiUrl
  },
})
```

`@nuxt/kit` helpers: `addPlugin`, `addImports`, `addComponent`, `addServerPlugin`, `extendPages`, `addRouteMiddleware`, `createResolver`.

---

## Runtime Config vs App Config

Two different config systems with different scopes:

| | `runtimeConfig` | `appConfig` |
|---|---|---|
| Purpose | Environment-specific secrets + public values | App-level UI/behavior config |
| Set via | `nuxt.config.ts` + `.env` override | `app.config.ts` only |
| Server-only values | Yes (`runtimeConfig.secret`) | No — always public |
| Reactive at runtime | No (build-time) | Yes — can be updated |
| Access | `useRuntimeConfig()` | `useAppConfig()` |

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  runtimeConfig: {
    dbUrl: process.env.DATABASE_URL,      // server-only
    public: {
      apiBase: process.env.API_BASE_URL,  // exposed to client
    }
  }
})

// app.config.ts
export default defineAppConfig({
  ui: {
    primaryColor: 'blue',
  }
})
```

Rule: secrets and env-specific values go in `runtimeConfig`. Theme, feature flags, and non-sensitive UI config go in `appConfig`.

---

## State Management with useState

`useState` is Nuxt's SSR-safe shared state primitive. Hydrates from server to client without mismatch.

```ts
// composables/useCounter.ts
export const useCounter = () => useState<number>('counter', () => 0)

// In any component
const counter = useCounter()
counter.value++
```

Key rules:
- Always provide a factory function as the second arg (initial value)
- Key must be unique across the app — use a namespaced string
- `useState` is not a substitute for Pinia in complex apps — use it for simple shared state

For complex state with actions and getters, use Pinia via `@pinia/nuxt`.

---

## Error Handling

### createError

```ts
// Server route
throw createError({ statusCode: 404, statusMessage: 'Not found', data: { id } })

// Client composable
throw createError({ statusCode: 403, statusMessage: 'Forbidden', fatal: true })
```

`fatal: true` renders the error page immediately on the client.

### error.vue

Global error page at the root level. Receives the error as a prop:

```vue
<!-- error.vue -->
<script setup lang="ts">
const props = defineProps<{ error: { statusCode: number; statusMessage: string } }>()

function handleError() {
  clearError({ redirect: '/' })
}
</script>
```

### showError / clearError

```ts
// Show error page programmatically
showError({ statusCode: 500, statusMessage: 'Something went wrong' })

// Clear and redirect
clearError({ redirect: '/' })
```

---

## Nuxt 2 → 3 Migration

Key breaking changes:

| Nuxt 2 | Nuxt 3 |
|--------|--------|
| `asyncData()` option | `useAsyncData()` composable |
| `fetch()` hook | `useFetch()` or `useAsyncData()` |
| Vuex | Pinia or `useState` |
| `this.$axios` | `$fetch` or `useFetch` |
| `context` object | `useNuxtApp()`, `useRoute()`, etc. |
| `@nuxtjs/composition-api` | Built-in (Vue 3 native) |
| `process.server` / `process.client` | `import.meta.server` / `import.meta.client` |
| `~/plugins/foo.js` export default fn | `defineNuxtPlugin(() => {})` |
| Options API components | Composition API with `<script setup>` |

The `asyncData` and `fetch` migration is the biggest lift. `asyncData` maps directly to `useAsyncData` or `useFetch` in `<script setup>`. `fetch` for client-side hydration moves to `onMounted`.

---

## Nitro Server Engine

Nitro powers the server layer. Key capabilities:

- **Universal deployment**: adapts to Node, Vercel, Cloudflare Workers, Deno, Bun, static export
- **Hybrid rendering**: per-route rules (`prerender`, `ssr`, `swr`, `isr`)
- **Built-in caching**: `defineCachedEventHandler`, `defineCachedFunction`
- **Storage**: unified KV interface (`useStorage`) across local, Redis, S3

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  nitro: {
    preset: 'vercel-edge',
    routeRules: {
      '/api/cached/**': { cache: { maxAge: 60 } },
      '/marketing/**': { prerender: true },
      '/app/**': { ssr: false },
    },
    storage: {
      redis: { driver: 'redis', url: process.env.REDIS_URL }
    }
  }
})

// Cached handler
export default defineCachedEventHandler(async (event) => {
  return fetchExpensiveData()
}, { maxAge: 60, name: 'expensive-data' })
```

---

## Common Anti-Patterns

**Calling useFetch in non-setup context:**
```ts
// Bad — composables must run in setup() or a composable
async function loadUser(id: string) {
  const { data } = await useFetch(`/api/users/${id}`) // breaks hydration
}

// Good — use $fetch for imperative calls
async function loadUser(id: string) {
  return $fetch<User>(`/api/users/${id}`)
}
```

**Missing key on dynamic useFetch:**
```ts
// Bad — key defaults to URL string, may collide across component instances
const { data } = await useFetch(`/api/users/${props.userId}`)

// Good — explicit unique key
const { data } = await useFetch(`/api/users/${props.userId}`, {
  key: `user-${props.userId}`,
})
```

**Importing auto-imported APIs:**
```ts
// Bad
import { ref, computed } from 'vue'
import { useFetch } from '#app'

// Good — remove all imports for Nuxt/Vue auto-imports
```

**Using process.server in Nuxt 3:**
```ts
// Bad (Nuxt 2 style)
if (process.server) { ... }

// Good (Nuxt 3)
if (import.meta.server) { ... }
if (import.meta.client) { ... }
```

**Mutating reactive query params directly:**
```ts
// Bad — breaks reactivity tracking
route.query.page = 2

// Good
await navigateTo({ query: { ...route.query, page: 2 } })
```

**Server routes without input validation:**
```ts
// Bad — trusting user input directly
const body = await readBody(event)
await db.users.create(body)

// Good — validate before use
const result = CreateUserSchema.safeParse(await readBody(event))
if (!result.success) throw createError({ statusCode: 422, data: result.error.flatten() })
await db.users.create(result.data)
```

**useState without a key:**
```ts
// Bad — key collision risk
const state = useState(() => initialValue)

// Good
const state = useState('feature-name:my-state', () => initialValue)
```
