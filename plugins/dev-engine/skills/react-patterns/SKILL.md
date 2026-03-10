---
name: react-patterns
description: >
  React hooks, context, composition, performance optimization, and common
  anti-patterns. Covers when to use each hook, composition over inheritance,
  performance decision tree, and state management choices.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "react patterns"
  - "react hooks"
  - "react performance"
  - "react composition"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_premature_optimization"
      verify: "useMemo/useCallback only wraps values/functions with proven referential instability"
      fail_action: "Remove wrapping unless a profiler or prop-equality check shows benefit"
    - name: "effects_are_synchronization"
      verify: "useEffect is used for syncing external state, not for reacting to user events"
      fail_action: "Move event-driven logic into event handlers, not effects"
    - name: "context_scope_correct"
      verify: "Context only crosses component-tree boundaries that props cannot reasonably span"
      fail_action: "Consider prop drilling or component composition before reaching for context"
    - name: "state_lives_where_used"
      verify: "State is colocated at the lowest component that needs it"
      fail_action: "Lift only as high as necessary — do not default to global state"
  on_fail: "React structure has common anti-patterns — address before merging"
  on_pass: "React patterns are sound"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced hook tutorial with advanced composition patterns and React 19 features"
---

# react-patterns

## Compound Component Pattern

Components sharing implicit state via context: `<Select>`, `<Select.Option>`, `<Select.Trigger>`. Parent provides state through context; children consume without prop drilling. Use `React.createContext` internally — never expose the context. Export only the compound pieces.

## Polymorphic Component Pattern

The `as` prop renders a component as any element type: `<Button as="a" href="/home">`. Type with `<T extends React.ElementType>` + `React.ComponentPropsWithoutRef<T>`. Use for design system primitives (Box, Text, Button). Avoid on complex components — type complexity compounds.

## Headless UI Pattern

Separate logic from rendering: a hook (`useCombobox`) manages state, keyboard navigation, and ARIA; a render component consumes the hook's return values. Callers own the markup. Return prop-getter functions (`getInputProps`, `getMenuProps`) that attach handlers and ARIA attributes to arbitrary elements.

## RSC vs Client Component Decision

**Server Component (default)**: data fetching, database access, heavy imports, no interactivity needed. **Client Component** (`'use client'`): interactive UI, browser APIs, hooks, effects. Push `'use client'` to the lowest possible boundary.

**Composition rule**: server components can render client components. Client components cannot import server components — but can accept them as `children` props.

## React 19 Patterns

**`use()`**: read promises and context in render. Suspends until resolved. Works inside conditionals — unlike hooks, doesn't follow hook rules.

**Actions**: functions passed to `action` prop on `<form>`. Async, server or client. Replaces `onSubmit` + `preventDefault` + `fetch`.

**`useActionState(action, initialState)`**: tracks pending state, return value, and error for form actions. Replaces `useState` + `useTransition` + manual error handling.

**`useOptimistic(state, updateFn)`**: instant UI updates before server confirmation. Reverts automatically on action failure.
## Performance Decision Tree

1. Real problem confirmed via profiler? If not, stop.
2. Pure expensive computation? → `useMemo`
3. Callback causing memoized child re-render? → `useCallback`
4. Large list? → virtualize (react-window / TanStack Virtual)
5. Deep tree? → code split with `React.lazy` + `Suspense`

See `references/process.md` for composition examples, state management decisions, and anti-patterns.
