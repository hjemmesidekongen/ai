---
name: typescript-modern
description: >
  Modern TypeScript — utility types, generics, discriminated unions, template
  literals, satisfies, and type-level programming. Covers narrowing strategy,
  generics vs overloads, utility type selection, and type safety rules.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "typescript"
  - "typescript types"
  - "generics"
  - "utility types"
  - "satisfies"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_any_abuse"
      verify: "No `any` used where `unknown`, a union, or a generic would be correct"
      fail_action: "Replace `any` with the narrowest safe type — `unknown` if truly dynamic"
    - name: "generics_not_overloads"
      verify: "Overloads are only used when return type varies in ways generics cannot express"
      fail_action: "Collapse overloads into a generic signature where the shape is uniform"
    - name: "discriminated_unions_exhaustive"
      verify: "Every switch/if on a discriminant has a never-typed exhaustiveness check"
      fail_action: "Add a default branch that assigns to `never` to catch future variants"
    - name: "satisfies_not_as"
      verify: "`satisfies` used for value inference with type constraint; `as` only for known-safe casts"
      fail_action: "Replace `as` with `satisfies` unless the cast is genuinely unavoidable"
  on_fail: "Type structure has safety gaps — address before merging"
  on_pass: "TypeScript patterns are sound"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced known fundamentals with TS 5.4+ features, branded types, and type-level testing"
---

# typescript-modern

Patterns beyond standard generics and narrowing — TS 5.4+ features, branded types, module augmentation, and type-level testing.

## TS 5.4–5.7 Features

**Inferred type predicates** (5.5): Filter functions returning `x !== null` auto-narrow without `is` guards.
**NoInfer<T>** (5.4): Blocks a parameter from contributing to inference. Use on fallback params: `create<T>(value: T, fallback: NoInfer<T>)`.
**Const type parameters** (5.0+): `<const T>` infers literal types without `as const` at call sites. Use for config factories.
**Isolated declarations** (5.5): `--isolatedDeclarations` requires explicit return types on exports. Parallel `.d.ts` emit for monorepo packages.

## Branded Types

Prevent domain confusion (`UserId` vs `OrderId` are both strings, but swapping is a bug):
```ts
type Brand<T, B> = T & { readonly __brand: B };
type UserId = Brand<string, 'UserId'>;
const toUserId = (s: string) => s as UserId;  // single controlled cast point
```
Brand at creation, accept branded types in signatures. One `as` cast at the entry point is acceptable.

## Module Augmentation

Extend third-party types with `declare module` in `.d.ts` files under `types/`. Only extend, never override — if you need to change a field type, patch the library instead.

## Type-Level Testing

`// @ts-expect-error` as assertion: next line **must** error or test fails. `expectTypeOf` (vitest) / `expectType` (tsd) for positive assertions. Run both in CI.

## Key Rules

- Model state as **what is true**, not flags. Discriminated union > optional fields.
- `satisfies` preserves narrowest inference while constraining. Pair with `as const`.
- `unknown` for untrusted input. `any` only at seams you intend to replace.
- `as` is a compiler promise — if wrong, runtime crashes. Prefer narrowing or `satisfies`.

See `references/process.md` for conditional types, mapped types, `infer`, tsconfig options, and anti-patterns.
