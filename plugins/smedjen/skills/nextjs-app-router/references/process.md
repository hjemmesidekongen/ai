# Next.js App Router — Process Reference

## File Conventions

```
app/
  layout.tsx          # Root layout — persistent across navigations
  page.tsx            # Route segment UI
  loading.tsx         # Suspense boundary for the segment
  error.tsx           # Error boundary (must be 'use client')
  not-found.tsx       # 404 UI for the segment
  route.ts            # Route Handler (API endpoint)
  template.tsx        # Like layout, but re-mounts on navigation
  default.tsx         # Fallback for parallel routes
  (group)/            # Route group — organizes routes without affecting URL
  [slug]/             # Dynamic segment
  [...slug]/          # Catch-all segment
  [[...slug]]/        # Optional catch-all
  @slot/              # Named slot for parallel routes
  (.)path/            # Intercepting route (same level)
  (..)path/           # Intercepting route (one level up)
```

Every folder with a `page.tsx` becomes a public route. Folders without it are private (components, utils).

## Server Components — When and Why

Server Components run exclusively on the server. They can be async, access the filesystem, query databases, and use server-only secrets. They emit no JavaScript to the client.

```tsx
// app/dashboard/page.tsx
import { db } from '@/lib/db';

export default async function DashboardPage() {
  // Direct DB access — no API needed
  const stats = await db.analytics.getWeekly();
  return <StatsGrid data={stats} />;
}
```

Use Server Components for:
- Database queries and ORM calls
- File system access
- Calling internal services with secrets
- Components with large dependencies (markdown parsers, chart libraries with SSR)
- Any component that doesn't need interactivity

Server Components cannot use: `useState`, `useEffect`, `useContext`, event handlers (`onClick`, `onChange`), browser APIs.

## Client Components — `'use client'`

`'use client'` marks a boundary. Everything imported into that file also runs on the client.

```tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

Keep Client Components small and at the leaves. Pass server-fetched data as props rather than fetching again inside the client component.

```tsx
// Server Component — fetches data
export default async function Page() {
  const user = await getUser();
  return <UserProfile user={user} />;  // passes data down
}

// Client Component — receives data, handles interaction
'use client';
export function UserProfile({ user }: { user: User }) {
  const [editing, setEditing] = useState(false);
  // ...
}
```

**Anti-pattern:** wrapping a Server Component in a Client Component to pass context — instead, pass the data as props or use `children` to compose.

## Route Handlers

`route.ts` files define HTTP endpoints. Use for external integrations, webhooks, OAuth callbacks, and public APIs. Do not use for internal Next.js data flows — Server Components handle those directly.

```ts
// app/api/webhooks/stripe/route.ts
import { headers } from 'next/headers';

export async function POST(req: Request) {
  const sig = headers().get('stripe-signature');
  const body = await req.text();

  const event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_SECRET);

  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckout(event.data.object);
      break;
  }

  return Response.json({ received: true });
}
```

Route Handlers support: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`. Export a named function for each method.

Dynamic Route Handlers:

```ts
// app/api/products/[id]/route.ts
export async function GET(
  req: Request,
  { params }: { params: { id: string } }
) {
  const product = await db.product.findUnique({ where: { id: params.id } });
  if (!product) return new Response('Not Found', { status: 404 });
  return Response.json(product);
}
```

## Loading and Error UI

`loading.tsx` creates an automatic Suspense boundary around the page segment. It renders immediately while the async page resolves.

```tsx
// app/products/loading.tsx
export default function Loading() {
  return <ProductGridSkeleton />;
}
```

`error.tsx` must be a Client Component — it receives `error` and `reset` props.

```tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div>
      <p>Something went wrong: {error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

`not-found.tsx` is triggered by calling `notFound()` from `next/navigation` in any Server Component within the segment.

## Parallel Routes

Parallel routes render multiple pages simultaneously in the same layout, each in a named slot.

```
app/
  layout.tsx        # uses @team and @analytics slots
  @team/
    page.tsx
  @analytics/
    page.tsx
  page.tsx
```

```tsx
// app/layout.tsx
export default function Layout({
  children,
  team,
  analytics,
}: {
  children: React.ReactNode;
  team: React.ReactNode;
  analytics: React.ReactNode;
}) {
  return (
    <div>
      {children}
      <div className="side-panels">
        {team}
        {analytics}
      </div>
    </div>
  );
}
```

Each slot can have its own `loading.tsx`, `error.tsx`, and `default.tsx`. `default.tsx` is required when navigating directly to a URL that doesn't match a slot — prevents 404.

## Intercepting Routes

Intercepting routes show a route in a modal overlay while preserving the current page. Useful for image galleries, auth modals, or detail drawers.

```
app/
  photos/
    [id]/
      page.tsx          # full page view at /photos/123
  @modal/
    (.)photos/
      [id]/
        page.tsx        # intercepted modal view
    default.tsx         # null — no modal when not intercepted
```

Conventions: `(.)` same level, `(..)` one level up, `(..)(..)` two levels up, `(...)` root.

## Middleware

`middleware.ts` at the project root runs before every matched request. Use for auth checks, redirects, header injection, A/B flags.

```ts
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('session')?.value;

  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
};
```

Middleware runs on the Edge runtime — no Node.js APIs, no filesystem, no full ORM. Keep it fast and thin.

## Caching — Full Reference

### Fetch Cache (Request Memoization + Data Cache)

Next.js extends `fetch` with caching semantics:

```ts
// Static — cached indefinitely, revalidated only on deploy
fetch('https://api.example.com/products')

// ISR — revalidated every 60 seconds
fetch('https://api.example.com/products', { next: { revalidate: 60 } })

// Dynamic — never cached, always fresh
fetch('https://api.example.com/cart', { cache: 'no-store' })

// Tagged — revalidate by tag
fetch('https://api.example.com/posts', { next: { tags: ['posts'] } })
```

Within a single request, identical fetch calls are automatically deduplicated (memoized).

### On-Demand Revalidation

```ts
// app/api/revalidate/route.ts
import { revalidatePath, revalidateTag } from 'next/cache';

export async function POST(req: Request) {
  const { tag, path } = await req.json();

  if (tag) revalidateTag(tag);
  if (path) revalidatePath(path);

  return Response.json({ revalidated: true });
}
```

Call this from your CMS webhook or admin action.

### Router Cache (Client-Side)

In-memory cache of rendered React Server Component payloads on the client. Automatically populated as users navigate. Lasts 30s (dynamic segments) or 5min (static segments). Cannot be disabled — it's a client-side performance optimization.

Force a router cache refresh:

```tsx
'use client';
import { useRouter } from 'next/navigation';

const router = useRouter();
router.refresh(); // re-fetches current route from server
```

### Full Route Cache (Server-Side Static Rendering)

Routes rendered at build time are stored on the server. Dynamic routes (using `cache: 'no-store'`, cookies, headers, or `dynamic = 'force-dynamic'`) are excluded.

Force dynamic rendering for a route:

```ts
// app/dashboard/page.tsx
export const dynamic = 'force-dynamic';
```

## Metadata API

Static metadata:

```ts
// app/products/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Products',
  description: 'Browse our catalog',
  openGraph: {
    title: 'Products',
    images: ['/og/products.png'],
  },
};
```

Dynamic metadata (requires async function):

```ts
export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const product = await getProduct(params.id);
  return {
    title: product.name,
    description: product.description,
  };
}
```

## Server Actions

Server Actions are async functions that run on the server, invokable from Client Components. They replace form POST handlers and mutation API endpoints.

```ts
// app/actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { db } from '@/lib/db';

export async function createPost(formData: FormData) {
  const title = formData.get('title') as string;

  await db.post.create({ data: { title } });
  revalidatePath('/posts');
}
```

Using in a form (works without JavaScript):

```tsx
import { createPost } from './actions';

export default function NewPostForm() {
  return (
    <form action={createPost}>
      <input name="title" type="text" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

Using programmatically from a Client Component:

```tsx
'use client';

import { createPost } from './actions';
import { useTransition } from 'react';

export function PostForm() {
  const [isPending, startTransition] = useTransition();

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    startTransition(() => createPost(formData));
  }

  return (
    <form onSubmit={handleSubmit}>
      <input name="title" />
      <button disabled={isPending}>
        {isPending ? 'Creating...' : 'Create'}
      </button>
    </form>
  );
}
```

Server Actions can return values, throw errors, and redirect. Use `zod` to validate inputs before touching the DB.

## Common Anti-Patterns

**Fetching in Client Components via useEffect**
```tsx
// Bad
'use client';
useEffect(() => {
  fetch('/api/products').then(r => r.json()).then(setProducts);
}, []);

// Good — fetch in a Server Component, pass as props
export default async function Page() {
  const products = await db.product.findMany();
  return <ProductList products={products} />;
}
```

**Putting `'use client'` at the top of the tree**
Marking a layout or high-level component as a Client Component forces everything below it to run on the client. Push `'use client'` to the smallest component that actually needs it.

**Using Route Handlers for internal data**
Route Handlers add an HTTP round-trip for no reason when a Server Component can query the DB directly. Only use Route Handlers for external consumers.

**Not using `loading.tsx`**
Without a `loading.tsx`, users see a blank page while async routes resolve. Add one per segment that has async data fetching.

**Missing `default.tsx` in parallel route slots**
Without `default.tsx` in a parallel route slot, direct navigation to a URL will 404 because the slot has no fallback. Always add `default.tsx` (can export `null`) to every slot.

**Triggering waterfalls with sequential awaits**
```ts
// Bad — sequential, 2x the latency
const user = await getUser(id);
const posts = await getPosts(id);

// Good — parallel
const [user, posts] = await Promise.all([getUser(id), getPosts(id)]);
```

**Leaking secrets through Client Components**
Any variable used in a Client Component is bundled and sent to the browser. Use `server-only` package to enforce Server Component boundaries around sensitive modules.

```ts
// lib/db.ts
import 'server-only'; // throws at build time if imported in a Client Component
```
