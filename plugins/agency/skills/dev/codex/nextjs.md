# Next.js Conventions

## App Router Only

Use the App Router (`app/` directory) exclusively. No Pages Router. No `getServerSideProps`, `getStaticProps`, or `getInitialProps`. These are legacy patterns.

## Server Components by Default

Every component is a Server Component unless it needs interactivity. Add `"use client"` only when the component uses hooks, event handlers, browser APIs, or React context.

## Client Boundary Push-Down

Keep `"use client"` as deep in the tree as possible. Create small client islands within server pages. Never mark a page-level layout as `"use client"`. Extract interactive parts into dedicated client components.

## Route Structure

- `app/(marketing)/` — public pages (landing, pricing, blog)
- `app/(app)/` — authenticated pages (dashboard, settings)
- `app/api/` — API routes

Use route groups `()` for layout organization without affecting the URL. Never nest route groups more than one level deep.

## Page File Conventions

Each route folder contains:

- `page.tsx` — the page component (required)
- `layout.tsx` — shared layout (if needed)
- `loading.tsx` — Suspense fallback
- `error.tsx` — error boundary

Co-locate route-specific components in the same folder. Shared components live in `components/`.

## Server Actions

Define in separate `actions.ts` files with `"use server"` at the top of the file. Never inline `"use server"` inside component files. Validate all inputs with Zod before processing. Return typed result objects, not raw data.

## Data Fetching

Use `fetch` in Server Components with explicit `cache` and `revalidate` options. No client-side fetching libraries (SWR, React Query, axios) unless the data is truly client-only and real-time. Use `unstable_cache` for expensive computations. Never fetch in layouts what could be fetched in pages.

## Metadata

Export a `metadata` object or `generateMetadata` function from every `page.tsx`. Never hardcode `<title>` or `<meta>` tags in JSX. Use `metadata.openGraph` for social sharing.

## Image Optimization

Always use `next/image`. Set explicit `width` and `height` props, or use `fill` with a sized container. Never use raw `<img>` tags. Use `priority` only for above-the-fold images.

## Fonts

Use `next/font/google` or `next/font/local`. Load fonts in the root layout and apply via CSS variable. Never use `@import` or `<link>` tags for font loading. One variable font per weight axis.
