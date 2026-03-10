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
  iteration: 1
  changes: "Original skill, no port"
---

# react-patterns

React's primitive is composition. Every architectural decision should bias toward the simplest composition that works.

## Hook Selection

**useState** — local UI state, toggle flags, form field values. Not for derived values.

**useReducer** — complex state objects, multi-field updates that move together, or state with non-trivial transitions. Threshold: if your useState setter appears in 3+ places with conditional logic, reach for useReducer.

**useEffect** — synchronize with external systems (DOM APIs, subscriptions, timers, network). Not for responding to events. If you're writing `useEffect` to react to a state change, that's usually a derived value or an event handler in disguise.

**useCallback / useMemo** — only when referential stability matters: a child wrapped in `React.memo`, a dependency in another hook, or a value passed to a native API. Default to not using them. Profile before adding.

**useRef** — mutable values that don't trigger re-renders: DOM node access, storing timer IDs, tracking previous values.

**Custom hooks** — extract any logic that combines 2+ hooks or manages a coherent concern. Name them `useSomething`. They are functions, not components — they can return anything.

## Composition Over Inheritance

Prefer composition patterns: children props, render props for inversion of control, compound components for tightly-coupled UI groups. HOCs are legacy — use hooks instead unless wrapping class components.

## Performance Decision Tree

1. Is there a real perf problem? Profile first. Do not optimize speculatively.
2. Is the expensive computation pure? → `useMemo`
3. Is a callback causing a memoized child to re-render? → `useCallback`
4. Is a large list the bottleneck? → virtualize (react-window / react-virtual)
5. Is the component tree too deep? → consider code splitting with `React.lazy` + `Suspense`

## Key Rules

- Derive state, don't sync it. If a value can be computed from existing state, compute it — don't store it.
- Keep effects small. One effect, one responsibility.
- Move logic down. State should live as close to where it's used as possible.
- Context is not a state manager. It re-renders all consumers on every change.

See `references/process.md` for hook implementations, context patterns, composition examples, state management decision tree, and anti-patterns with fixes.
