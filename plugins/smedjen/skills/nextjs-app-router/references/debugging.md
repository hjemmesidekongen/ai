# nextjs-app-router — Debugging Reference

## Common Debugging Scenarios

### Hydration mismatch from non-deterministic rendering
**Symptom:** Next.js dev overlay shows "Hydration failed because the initial UI does not match what was rendered on the server." Content flickers on load.
**Root cause:** Server and client render different output. Common culprits: `Date.now()`, `Math.random()`, `window`/`document` access during render, browser extensions injecting DOM nodes, locale-dependent formatting.
**Diagnosis:**
- Read the Next.js error overlay — it highlights the exact DOM mismatch with a diff view showing server vs client output.
- Search the component for `Date`, `Math.random`, `window`, `document`, `navigator`, `localStorage`. Any of these during render (not inside useEffect) will cause mismatches.
- Temporarily wrap the suspect content in `suppressHydrationWarning` — if the error disappears, that content is the source.
- For browser extension interference: test in incognito mode with extensions disabled.
- Check for conditional rendering based on `typeof window !== 'undefined'` — this produces different server/client trees.
**Fix pattern:** Move non-deterministic values into useEffect/useState so they only run client-side. For date formatting, use a consistent locale or render a placeholder on the server. For content that must differ between server and client, use `useEffect` to update after hydration, or use the `suppressHydrationWarning` prop as a last resort. For components that can't render on the server at all, use `next/dynamic` with `ssr: false`.

### Caching returns stale data after mutation
**Symptom:** After a form submission or Server Action that mutates data, the page still shows old data. Refreshing the browser shows the correct data.
**Root cause:** Next.js aggressively caches fetch responses (Data Cache) and rendered route segments (Full Route Cache, Router Cache). Mutations don't automatically invalidate these caches.
**Diagnosis:**
- Inspect the RSC payload: open Network tab, filter by `__nextDataReq=1` (or look for requests with `RSC: 1` header in Next.js 14+). Check if the payload contains stale data — if it does, the server cache is stale.
- Check if `revalidatePath()` or `revalidateTag()` is called after the mutation in the Server Action or Route Handler.
- For fetch calls, check the `cache` and `next.revalidate` options. `fetch(url)` defaults to `cache: 'force-cache'` in Next.js — data stays cached indefinitely without explicit revalidation.
- Check `router.refresh()` is called client-side after the mutation if using `useRouter`.
**Fix pattern:** After mutations, call `revalidatePath('/path')` or `revalidateTag('tag')` in the Server Action. Tag individual fetches with `next: { tags: ['tag'] }` for granular invalidation. For pages that should never cache, add `export const dynamic = 'force-dynamic'` or use `cache: 'no-store'` on fetches. Call `router.refresh()` client-side when you need the router cache cleared immediately.

### "use client" boundary placed too high in the component tree
**Symptom:** Bundle size is larger than expected. Components that could be Server Components are shipping to the client. `next build` output shows large First Load JS for routes that should be mostly static.
**Root cause:** Adding `"use client"` to a layout or parent component forces the entire subtree to be client-rendered, including children that don't need interactivity.
**Diagnosis:**
- Run `next build` and examine the output table. The "First Load JS" column shows the client bundle per route. Compare against expected sizes — pages with mostly static content shouldn't have large bundles.
- Run `ANALYZE=true next build` with `@next/bundle-analyzer` configured. Check the client bundle visualization for components that shouldn't be there.
- Search for `"use client"` directives: are they on layouts, page-level wrappers, or high-level components? Each one creates a client boundary that pulls its entire import tree to the client.
- Check the `next build` output for "(Static)" vs "(Dynamic)" markers per route. Routes marked Dynamic that should be Static may have a client boundary too high up.
**Fix pattern:** Push `"use client"` down to the leaf components that actually need interactivity. Extract interactive parts into small client components and keep the parent as a Server Component. Pass server-fetched data as props to client components rather than fetching on the client. Use composition: `<ServerLayout><ClientInteractiveWidget /></ServerLayout>` instead of making the entire layout a client component.

### Parallel or intercepting route not resolving
**Symptom:** A parallel route slot renders the `default.tsx` fallback or 404 instead of the expected content. Intercepting routes don't intercept — they navigate to the full page instead.
**Root cause:** File system convention mismatch. Parallel routes require `@slot` folders with matching segment structure. Intercepting routes require `(.)`, `(..)`, `(..)(..)`, or `(...)` prefixes that match the route depth relative to the target.
**Diagnosis:**
- Add `console.log('rendering: [file path]')` at the top of each `layout.tsx`, `page.tsx`, and `default.tsx` in the parallel/intercepting route tree. Check the server terminal output to see which files are actually hit.
- Verify the folder structure matches the convention exactly. For parallel routes: `app/@slot/segment/page.tsx`. For intercepting routes: count the directory levels between the interceptor and the target route.
- Check that every parallel route slot has a `default.tsx` — missing defaults cause 404 on soft navigation when the slot doesn't have a matching segment.
- For intercepting routes, verify the link uses `<Link>` (soft navigation). Direct URL entry or hard refresh bypasses interception by design.
**Fix pattern:** For parallel routes, ensure every `@slot` has a `default.tsx` that returns `null` or appropriate fallback content. Match the segment structure — if the layout expects `@modal` and `@content`, both must exist at the same level. For intercepting routes, count the `(..)` levels carefully relative to the file system, not the URL. Test by adding console logs in every route file to trace resolution.

### Server Action serialization failure
**Symptom:** Server Action throws "Only plain objects, and a few built-ins, can be passed to Server Actions." Or the action receives `undefined` for an argument that was passed.
**Root cause:** Server Actions serialize arguments across the network boundary using a subset of structured clone. Class instances, functions, Symbols, DOM nodes, and circular references can't be serialized.
**Diagnosis:**
- Check the browser console and server terminal for the serialization error message — it usually names the problematic value type.
- Log the arguments on the client side just before calling the action: `console.log(typeof arg, arg)`. Check for non-serializable types.
- Isolate by passing only primitives (strings, numbers, booleans) first. If that works, add arguments back one at a time to find the offending value.
- For FormData-based actions, check that the form field names match what the action expects. Log `Object.fromEntries(formData)` in the action to see what actually arrives.
- Watch for Date objects — they serialize to strings, not Date instances. `instanceof Date` will be false on the server side.
**Fix pattern:** Pass only serializable primitives and plain objects. Convert class instances to plain objects before passing. For complex data, pass an ID and re-fetch on the server. For Dates, pass ISO strings and parse on the server. For file uploads via FormData, ensure the action parameter is typed as `FormData` and files are accessed with `formData.get('file')`.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Next.js error overlay | Hydration mismatches, build errors, RSC errors | Automatic in dev mode |
| Network tab RSC inspection | Check server-rendered payloads and cache behavior | DevTools > Network > filter `RSC: 1` header |
| `next build` output | Identify static vs dynamic routes, bundle sizes | `next build` |
| `@next/bundle-analyzer` | Visualize client/server bundle contents | `ANALYZE=true next build` |
| `next --turbopack` dev | Faster dev server for quicker iteration | `next dev --turbopack` |
| Server terminal logs | Trace Server Component rendering and Server Actions | `console.log` in server code, check terminal |
| `export const dynamic` | Force dynamic rendering for debugging cache issues | `export const dynamic = 'force-dynamic'` in route |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
