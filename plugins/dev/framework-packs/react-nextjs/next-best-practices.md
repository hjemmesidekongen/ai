---
origin: "vercel-labs/next-skills"
origin_skill: "next-best-practices"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "All 18 modules: file conventions, RSC boundaries, async patterns, runtime selection, directives, functions, error handling, data patterns, route handlers, metadata, image optimization, font optimization, bundling, scripts, hydration errors, suspense boundaries, parallel routes, self-hosting"
sections_removed: "None — kept in full per findings.md recommendation"
---

# Next.js Best Practices

Apply these rules when writing or reviewing Next.js code.

## File Conventions

- Project structure and special files
- Route segments (dynamic, catch-all, groups)
- Parallel and intercepting routes
- Middleware rename in v16 (middleware → proxy)

## RSC Boundaries

Detect invalid React Server Component patterns:

- Async client component detection (invalid)
- Non-serializable props detection
- Server Action exceptions

## Async Patterns

Next.js 15+ async API changes:

- `params` and `searchParams` are now async — must be awaited
- `cookies()` and `headers()` are now async — must be awaited
- Use the Next.js migration codemod to update existing code

```typescript
// Before (Next.js 14)
export default function Page({ params }: { params: { id: string } }) {
  return <div>{params.id}</div>
}

// After (Next.js 15+)
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  return <div>{id}</div>
}
```

## Runtime Selection

- Default to Node.js runtime
- Edge runtime: only when latency is critical and you don't need Node.js APIs

```typescript
export const runtime = 'edge' // Only when explicitly needed
```

## Directives

- `'use client'` — boundary: component and all imports run on client
- `'use server'` — marks Server Actions (functions called from client)
- `'use cache'` — Next.js 16 caching directive (experimental)

## Functions

**Navigation hooks (client only):**
- `useRouter()` — programmatic navigation
- `usePathname()` — current pathname
- `useSearchParams()` — URL search params (needs Suspense)
- `useParams()` — dynamic route params

**Server functions:**
- `cookies()` — read/write cookies (async in v15+)
- `headers()` — read request headers (async in v15+)
- `draftMode()` — enable draft mode (async in v15+)
- `after()` — run logic after response is sent (non-blocking)

**Generate functions:**
- `generateStaticParams()` — pre-generate dynamic routes at build time
- `generateMetadata()` — async dynamic metadata

## Error Handling

Special error files:
- `error.tsx` — catches errors in route segment, must be `'use client'`
- `global-error.tsx` — catches root layout errors
- `not-found.tsx` — renders when `notFound()` is thrown

Functions:
- `redirect(url)` — redirects (307 by default)
- `permanentRedirect(url)` — redirects (308)
- `notFound()` — throws a not-found error
- `forbidden()` / `unauthorized()` — auth errors (Next.js 15+)
- `unstable_rethrow(error)` — use inside catch blocks to re-throw Next.js internal errors

## Data Patterns

**When to use what:**

| Pattern | When | Notes |
|---------|------|-------|
| Server Component | Default — fetch data | Zero client JS |
| Server Action | Form mutations, user actions | Called from client, runs on server |
| Route Handler | External webhooks, non-React clients | REST API surface |

**Avoid data waterfalls** — see `react-best-practices.md` Category 1 for full waterfall rules. Next.js-specific pattern:

```typescript
// ✅ Preload pattern (start fetch early, Next.js-specific)
function preloadUser(id: string) {
  void getUser(id)
}

export default async function Page({ params }) {
  const { id } = await params
  preloadUser(id) // Start fetching immediately
  // Do other work...
  const user = await getUser(id) // Resolves quickly
}
```

**Client component data fetching:**
- Use SWR or TanStack Query for client-side data
- Wrap `useSearchParams()` in Suspense boundary

## Route Handlers

- Create in `app/api/.../route.ts`
- **Conflict:** `route.ts` and `page.tsx` cannot coexist in same directory
- GET requests are NOT cached by default in Next.js 15+
- Use Server Actions instead of Route Handlers for form mutations

```typescript
// app/api/users/route.ts
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const id = searchParams.get('id')
  // ...
}
```

## Metadata & OG Images

```typescript
// Static metadata
export const metadata: Metadata = {
  title: 'My App',
  description: 'Description',
}

// Dynamic metadata
export async function generateMetadata({ params }): Promise<Metadata> {
  const { id } = await params
  const product = await getProduct(id)
  return { title: product.name }
}

// OG image — app/og/route.tsx
import { ImageResponse } from 'next/og'
export function GET() {
  return new ImageResponse(<div>Hello</div>, { width: 1200, height: 630 })
}
```

## Image Optimization

```typescript
import Image from 'next/image'

// ✅ Always use next/image over <img>
<Image
  src="/hero.jpg"
  alt="Hero image"
  width={1200}
  height={600}
  priority          // Use for above-fold LCP images
  sizes="(max-width: 768px) 100vw, 50vw"
  placeholder="blur"
  blurDataURL="..."
/>
```

- Remote images require `remotePatterns` in `next.config.ts`
- Set `priority` on the LCP image to avoid lazy loading the hero

## Font Optimization

```typescript
// app/layout.tsx
import { Inter, Roboto_Mono } from 'next/font/google'
import localFont from 'next/font/local'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

// Usage: className={inter.variable}
```

- `next/font` eliminates layout shift and avoids external network requests
- Use `variable` prop to expose font as CSS custom property for Tailwind

## Bundling

- Server-incompatible packages (with browser globals) need `serverExternalPackages`
- Import CSS directly, never use `<link>` tags in components
- ESM/CJS conflicts: use `transpilePackages` in `next.config.ts`

```typescript
// Analyze bundle
// npm install @next/bundle-analyzer
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
})
```

## Scripts

```typescript
import Script from 'next/script'

// ✅ Use next/script for third-party scripts
<Script src="https://example.com/analytics.js" strategy="lazyOnload" />

// Inline scripts need id
<Script id="analytics-init">{`window.analytics = {}`}</Script>

// Google Analytics (preferred)
import { GoogleAnalytics } from '@next/third-parties/google'
<GoogleAnalytics gaId="G-XYZ" />
```

## Hydration Errors

Common causes:
- Using `window`/`document` in SSR code — wrap in `useEffect`
- Date/time rendering differences — format consistently
- Invalid HTML nesting (e.g., `<p>` inside `<p>`)
- Browser extensions modifying DOM

Fixes:
- `suppressHydrationWarning` on elements with known server/client mismatch
- `dynamic(() => import('./Component'), { ssr: false })` for client-only components

## Suspense Boundaries

Hooks requiring Suspense:
- `useSearchParams()` — wrap page in `<Suspense>`
- `usePathname()` — also needs Suspense in some contexts

```typescript
// app/page.tsx
import { Suspense } from 'react'
import { SearchContent } from './SearchContent'

export default function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <SearchContent />
    </Suspense>
  )
}
```

## Parallel & Intercepting Routes

```
app/
  @modal/
    (.)photo/[id]/
      page.tsx    ← intercepting route for modal
  photo/[id]/
    page.tsx      ← full page route
  default.tsx     ← fallback when slot has no match
  layout.tsx
```

- Close intercepted modal: `router.back()` (not `router.push('/')`)
- `default.tsx` required for each `@slot` to handle direct navigation

## Self-Hosting

```typescript
// next.config.ts
module.exports = {
  output: 'standalone', // For Docker deployments
}
```

- Multi-instance ISR needs external cache handler (`NEXT_CACHE_HANDLER_PATH`)
- Features needing extra setup: Image Optimization (needs `sharp`), ISR

## Debug Tricks

```bash
# MCP endpoint for AI-assisted debugging
npx next dev --mcp

# Rebuild specific routes
npx next build --debug-build-paths /about /products/[id]
```
