---
origin: "vercel-labs/agent-skills"
origin_skill: "react-best-practices"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "Categories 1–5: Eliminating Waterfalls, Bundle Size Optimization, Server-Side Performance, Client-Side Data Fetching, Re-render Optimization"
sections_removed: "Categories 6–8: Rendering Performance, JavaScript Performance, Advanced Patterns (LOW priority per findings.md)"
---

# React Best Practices (Vercel — Categories 1–5)

Performance optimization for React and Next.js. Source: Vercel Engineering. 58 rules across 8 categories; this fork includes the CRITICAL and HIGH impact categories only.

## When to Apply

- Writing new React components or Next.js pages
- Implementing data fetching
- Reviewing code for performance issues
- Optimizing bundle size or load times

> See also: `next-best-practices.md` for Next.js-specific patterns (preload pattern, async params/cookies, Server Actions, Route Handlers)

## Category 1: Eliminating Waterfalls (CRITICAL)

Sequential awaits create waterfalls — each request waits for the previous one. Fix: parallelize.

**`async-defer-await`** — Move await into branches where actually used:
```typescript
// ❌ Always awaits both
const user = await getUser()
const admin = await getAdmin()
if (type === 'admin') return admin

// ✅ Await only what's needed
if (type === 'admin') return await getAdmin()
return await getUser()
```

**`async-parallel`** — Use `Promise.all()` for independent operations:
```typescript
// ❌ Sequential
const user = await getUser(id)
const posts = await getPosts(id)

// ✅ Parallel
const [user, posts] = await Promise.all([getUser(id), getPosts(id)])
```

**`async-dependencies`** — Use `better-all` when dependencies are partial:
```typescript
// When post.authorId needed before fetching author
import { all } from 'better-all'
const [post, user] = await all(
  getPost(postId),
  (results) => getUser(results[0].authorId)
)
```

**`async-api-routes`** — Start promises early, await late:
```typescript
// ✅ Start all fetches immediately
const userPromise = getUser(id)
const configPromise = getConfig()
// Do other work...
const [user, config] = await Promise.all([userPromise, configPromise])
```

**`async-suspense-boundaries`** — Use Suspense to stream content:
```typescript
<Suspense fallback={<Skeleton />}>
  <SlowComponent />   {/* streams when ready */}
</Suspense>
```

## Category 2: Bundle Size Optimization (CRITICAL)

**`bundle-barrel-imports`** — Import directly, avoid barrel files:
```typescript
// ❌ Imports entire lodash
import { debounce } from 'lodash'

// ✅ Direct import (tree-shakeable)
import debounce from 'lodash/debounce'
```

**`bundle-dynamic-imports`** — Use `next/dynamic` for heavy components:
```typescript
const HeavyChart = dynamic(() => import('./HeavyChart'), {
  loading: () => <Skeleton />,
  ssr: false // if not needed on server
})
```

**`bundle-defer-third-party`** — Load analytics/logging after hydration:
```typescript
useEffect(() => {
  import('./analytics').then(({ init }) => init())
}, [])
```

**`bundle-conditional`** — Load modules only when feature is activated:
```typescript
async function handlePDF() {
  const { generatePDF } = await import('./pdf-generator')
  await generatePDF(data)
}
```

**`bundle-preload`** — Preload on hover/focus for perceived speed:
```typescript
<Link
  href="/heavy-page"
  onMouseEnter={() => router.prefetch('/heavy-page')}
>
  Heavy Page
</Link>
```

## Category 3: Server-Side Performance (HIGH)

**`server-auth-actions`** — Authenticate Server Actions like API routes:
```typescript
'use server'
export async function updateUser(data: FormData) {
  const session = await auth() // Always check auth in Server Actions
  if (!session) throw new Error('Unauthorized')
  // ...
}
```

**`server-cache-react`** — Use `React.cache()` for per-request deduplication:
```typescript
import { cache } from 'react'
export const getUser = cache(async (id: string) => {
  return db.user.findUnique({ where: { id } })
})
// Multiple calls in same request share one DB query
```

**`server-cache-lru`** — Use LRU cache for cross-request caching:
```typescript
import LRU from 'lru-cache'
const cache = new LRU({ max: 500, ttl: 1000 * 60 * 5 })
export async function getConfig() {
  if (cache.has('config')) return cache.get('config')
  const config = await db.config.findFirst()
  cache.set('config', config)
  return config
}
```

**`server-hoist-static-io`** — Hoist static I/O (fonts, logos) to module level:
```typescript
// ✅ Read once at startup, not on every request
const logo = fs.readFileSync('./public/logo.svg', 'utf8')
export default function Layout() {
  return <div dangerouslySetInnerHTML={{ __html: logo }} />
}
```

**`server-parallel-fetching`** — Restructure components to parallelize fetches:
```typescript
// Lift fetches to parent and pass as props, or use Promise.all
async function Page() {
  const [user, posts] = await Promise.all([getUser(), getPosts()])
  return <Content user={user} posts={posts} />
}
```

**`server-after-nonblocking`** — Use `after()` for non-blocking side effects:
```typescript
import { after } from 'next/server'
export async function handleOrder(data: FormData) {
  const order = await createOrder(data)
  after(async () => {
    await sendConfirmationEmail(order) // Doesn't block response
    await updateAnalytics(order)
  })
  return order
}
```

## Category 4: Client-Side Data Fetching (MEDIUM-HIGH)

**`client-swr-dedup`** — Use SWR for automatic request deduplication:
```typescript
// Multiple components calling useUser('/api/user/1') share one request
const { data: user } = useSWR('/api/user/1', fetcher, {
  revalidateOnFocus: false,
  dedupingInterval: 2000
})
```

**`client-event-listeners`** — Deduplicate global event listeners:
```typescript
// ❌ Each component adds its own listener
useEffect(() => {
  window.addEventListener('resize', handleResize)
  return () => window.removeEventListener('resize', handleResize)
}, [])

// ✅ Shared hook with single listener
function useWindowSize() {
  const [size, setSize] = useState({ width: 0, height: 0 })
  useEffect(() => {
    const handler = () => setSize({ width: window.innerWidth, height: window.innerHeight })
    window.addEventListener('resize', handler)
    return () => window.removeEventListener('resize', handler)
  }, [])
  return size
}
```

**`client-passive-event-listeners`** — Use passive listeners for scroll:
```typescript
element.addEventListener('scroll', handler, { passive: true })
element.addEventListener('touchstart', handler, { passive: true })
```

**`client-localstorage-schema`** — Version and minimize localStorage data:
```typescript
const STORAGE_KEY = 'app-state-v2' // Bump version on schema change
const stored = localStorage.getItem(STORAGE_KEY)
const state = stored ? JSON.parse(stored) : defaultState
```

## Category 5: Re-render Optimization (MEDIUM)

**`rerender-defer-reads`** — Don't subscribe to state only used in callbacks:
```typescript
// ❌ Component re-renders on every count change
function Button({ onSave }) {
  const count = useStore(s => s.count)
  return <button onClick={() => onSave(count)}>Save</button>
}

// ✅ Read inside callback, no re-render
function Button({ onSave }) {
  const getCount = useStore(s => s.getCount)
  return <button onClick={() => onSave(getCount())}>Save</button>
}
```

**`rerender-memo`** — Extract expensive work into memoized components:
```typescript
const ExpensiveList = memo(function ExpensiveList({ items }: Props) {
  return <ul>{items.map(item => <Item key={item.id} item={item} />)}</ul>
})
```

**`rerender-memo-with-default-value`** — Hoist default non-primitive props:
```typescript
// ❌ New array on every render causes child re-render
<Component items={[]} />

// ✅ Stable reference
const EMPTY_ITEMS: Item[] = []
<Component items={EMPTY_ITEMS} />
```

**`rerender-derived-state`** — Subscribe to derived booleans, not raw values:
```typescript
// ❌ Re-renders on every status change
const status = useStore(s => s.status)
const isLoading = status === 'loading'

// ✅ Re-renders only when isLoading changes
const isLoading = useStore(s => s.status === 'loading')
```

**`rerender-derived-state-no-effect`** — Derive state during render:
```typescript
// ❌ Extra render from effect
const [filtered, setFiltered] = useState([])
useEffect(() => {
  setFiltered(items.filter(i => i.active))
}, [items])

// ✅ Compute during render
const filtered = useMemo(() => items.filter(i => i.active), [items])
```

**`rerender-functional-setstate`** — Use functional setState for stable callbacks:
```typescript
// ✅ Stable function reference, doesn't need count in deps
const increment = useCallback(() => {
  setCount(c => c + 1)
}, []) // No dependencies needed
```

**`rerender-transitions`** — Use `startTransition` for non-urgent updates:
```typescript
import { startTransition } from 'react'

function SearchInput() {
  const [query, setQuery] = useState('')
  return (
    <input
      value={query}
      onChange={e => {
        setQuery(e.target.value) // Urgent: update input immediately
        startTransition(() => {
          setSearchResults(e.target.value) // Non-urgent: can defer
        })
      }}
    />
  )
}
```

**`rerender-use-ref-transient-values`** — Use refs for transient frequent values:
```typescript
// Mouse position, scroll position, animation frames
const mousePos = useRef({ x: 0, y: 0 })
useEffect(() => {
  const handler = (e: MouseEvent) => {
    mousePos.current = { x: e.clientX, y: e.clientY } // No re-render
  }
  window.addEventListener('mousemove', handler)
  return () => window.removeEventListener('mousemove', handler)
}, [])
```
