# React Conventions

## Exports

- **Named exports only.** Never use `export default`. Every component is `export function ComponentName()`.
- Default exports allow silent renames on import, making refactoring unreliable. Named exports enforce consistency.

## Props

- Define the props interface directly above the component, in the same file.
- Name it `{ComponentName}Props`. No separate props files, no shared props barrels.

```tsx
interface ButtonProps {
  label: string;
  onClick: () => void;
}

export function Button({ label, onClick }: ButtonProps) { ... }
```

## Hooks Extraction

- Inline logic is fine when short. Extract to a co-located `use-{name}.ts` when logic exceeds ~15 lines.
- Custom hooks return **typed objects**, never tuples. Tuples break when you add fields.

```tsx
// use-counter.ts — returns { count, increment, reset }, not [count, increment, reset]
```

## No Barrel Exports

- No `index.ts` re-export files. Import directly from the source file.
- Barrels break tree-shaking, create circular dependency risks, and make imports ambiguous.

```tsx
// Correct
import { Button } from '@/components/Button';
// Wrong
import { Button } from '@/components';
```

## Test File Adjacency

- Tests live next to their component: `Button.tsx` + `Button.test.tsx` in the same directory.
- No `__tests__/` folders. Co-location keeps related files together and makes dead code obvious.

## Component Structure

- **One component per file.** File name matches component name in PascalCase.
- Organize by feature/domain, not by type. No `components/`, `hooks/`, `utils/` top-level folders.

```
features/
  checkout/
    CheckoutForm.tsx
    CheckoutForm.test.tsx
    use-checkout.ts
    OrderSummary.tsx
    OrderSummary.test.tsx
```

## Event Handlers

- Inside the component: prefix with `handle` — `handleClick`, `handleSubmit`.
- On props: prefix with `on` — `onClick`, `onSubmit`.
- This distinction clarifies whether you are defining or consuming the handler.

## Conditional Rendering

- Use early returns for guard clauses (`if (loading) return <Skeleton />`).
- Use ternaries for simple inline conditions.
- Extract to a named component when a conditional block exceeds ~10 lines. Never nest ternaries.
