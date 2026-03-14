# react-patterns — Debugging Reference

## Common Debugging Scenarios

### Infinite re-render loop from unstable useEffect dependencies
**Symptom:** Component re-renders continuously. Browser tab freezes or React throws "Maximum update depth exceeded."
**Root cause:** A dependency in the useEffect array is recreated every render — typically an object literal, array, or function defined inline in the component body.
**Diagnosis:**
- Open React DevTools Profiler, hit Record, and observe the commit graph. If the same component fires on every commit, it's the culprit.
- Install `why-did-you-render`: `npm i -D @welldone-software/why-did-you-render`, add `Component.whyDidYouRender = true`. Console will log which props/state triggered the re-render and whether the value actually changed (deep equality vs referential).
- Check the useEffect dependency array. Look for object/array literals or functions that aren't wrapped in useMemo/useCallback.
- Add a `console.count('effect fired')` inside the effect body to confirm it's the effect causing the loop vs a parent re-render.
**Fix pattern:** Stabilize dependencies — useMemo for objects/arrays, useCallback for functions. If the dependency is a prop, the fix may need to happen in the parent. For effects that should run once, verify the dependency array is `[]` and that the lint rule isn't forcing unstable deps into it.

### Stale closure in event handler
**Symptom:** An event handler reads an outdated value of state or props. Clicking a button after multiple state changes shows the value from when the handler was created, not the current value.
**Root cause:** The handler closed over a stale snapshot of state. This happens when a callback is passed to a memoized child or stored in a ref/timeout without updating.
**Diagnosis:**
- Add a log inside the handler: `console.log('handler value:', value)`. Compare it against the current value shown in React DevTools state inspector.
- Create a ref that tracks the latest value: `const latestRef = useRef(value); latestRef.current = value;`. Log `latestRef.current` inside the handler. If the ref shows the correct value but the closure doesn't, it's a stale closure.
- Check if the handler is wrapped in useCallback with a stale dependency array.
**Fix pattern:** Either add the state variable to the useCallback dependency array, use a ref to track the latest value and read from `ref.current` inside the handler, or use the functional updater form of setState (`setState(prev => prev + 1)`) to avoid needing the current value at all.

### Context re-renders entire subtree
**Symptom:** Updating one piece of context causes unrelated components in the subtree to re-render. Performance degrades as the tree grows.
**Root cause:** React re-renders every consumer when the context value object changes identity. If the provider creates a new object each render (`value={{ user, theme }}`), all consumers re-render regardless of which field they use.
**Diagnosis:**
- React DevTools Profiler: record a commit, click on a component that shouldn't have re-rendered, check "Why did this render?" — it will say "Context changed."
- In the Profiler commit view, look at the flame graph. Components highlighted in yellow/orange re-rendered. If the entire subtree lights up on a minor state change, the context value is unstable.
- Wrap the provider's value in useMemo and check if the problem disappears.
**Fix pattern:** Memoize the context value object with useMemo. Split large contexts into separate providers (one for user, one for theme). For high-frequency updates, consider `use-context-selector` or Zustand/Jotai for fine-grained subscriptions. Wrap consumer components in React.memo to bail out when their specific slice hasn't changed.

### Broken useEffect cleanup causing memory leaks
**Symptom:** Memory usage grows over time. Components unmount but their subscriptions, intervals, or fetch callbacks still fire. Console warnings about "setState on unmounted component" (React 17 and earlier).
**Root cause:** The useEffect return function (cleanup) is missing, doesn't cancel the subscription, or the cleanup references a stale instance.
**Diagnosis:**
- Chrome DevTools > Memory tab > Take heap snapshot before and after navigating away from the component. Compare snapshots — filter by "Detached" to find DOM nodes that should have been garbage collected.
- Use the Performance Monitor panel (Chrome DevTools > More tools > Performance Monitor) to watch JS heap size in real time. Navigate to the component and away repeatedly — if the heap only grows, there's a leak.
- Add `console.log('cleanup ran')` in the useEffect return function. If it never logs on unmount, the cleanup isn't wired correctly.
- For AbortController-based fetch cleanup: log `signal.aborted` in the cleanup to verify the signal fires.
**Fix pattern:** Return a cleanup function from every useEffect that creates subscriptions, timers, or listeners. For fetch: use AbortController and pass `signal` to fetch options. For intervals: `const id = setInterval(...); return () => clearInterval(id);`. For event listeners: `return () => el.removeEventListener(event, handler);`. For WebSocket/third-party subscriptions: call the unsubscribe method in cleanup.

### Key prop misuse causing unexpected state preservation
**Symptom:** Switching between "similar" components (e.g., two user profile forms for different users) preserves the old component's internal state instead of resetting it. Form fields show stale data.
**Root cause:** React reuses the component instance because the element type and position in the tree are the same. Without a key change, React reconciles rather than remounts.
**Diagnosis:**
- React DevTools component tree: select the component and watch its state/hooks panel while switching between entities. If state doesn't reset, the instance is being reused.
- Check the parent — is it rendering `<ProfileForm userId={id} />` without a `key` prop? If the component type and position match, React won't remount.
- Temporarily add a `useEffect(() => console.log('mounted'), [])` — if it doesn't fire on entity switch, the component is being reused.
**Fix pattern:** Add a `key` prop tied to the entity identity: `<ProfileForm key={userId} userId={userId} />`. When the key changes, React unmounts the old instance and mounts a fresh one. Only use this when you genuinely want a full reset — for partial resets, use useEffect to sync specific state with props.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| React DevTools Profiler | Identify which components re-render and why | Browser extension > Profiler tab > Record |
| why-did-you-render | Pinpoint unnecessary re-renders with deep-equality checks | `npm i -D @welldone-software/why-did-you-render` + setup file |
| Chrome Memory tab | Detect memory leaks from missing cleanup | DevTools > Memory > Heap snapshot > Compare |
| Chrome Performance Monitor | Watch real-time heap growth during navigation | DevTools > More tools > Performance Monitor |
| React DevTools Components | Inspect component state, props, hooks, and tree position | Browser extension > Components tab |
| console.count | Confirm how many times an effect or render fires | `console.count('label')` inside effect/render |
| React Strict Mode | Surface missing cleanup and impure renders during dev | `<React.StrictMode>` wrapper in root |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
