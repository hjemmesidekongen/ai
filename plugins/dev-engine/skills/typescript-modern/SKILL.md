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
  iteration: 1
  changes: "Original skill, no port"
---

# typescript-modern

TypeScript's value is making illegal states unrepresentable. Every type decision should push toward that goal.

## Type Narrowing Strategy

Prefer **discriminated unions** over optional fields for variant shapes. A `kind` or `type` literal field on each variant lets the compiler prove exhaustiveness. Use `never` in the default branch to catch future variants at compile time.

**Narrowing order**: `typeof` for primitives → `instanceof` for classes → `in` for shape checks → discriminant field for unions → user-defined type guards (`is`) only when the above are insufficient.

## Generics vs Overloads

Use **generics** when the relationship between input and output type is uniform — the shape of the logic is the same, only the type varies. Use **overloads** only when the return type changes discretely based on the input type in a way generics cannot capture. Overloads are harder to maintain; exhaust generic options first.

Add **constraints** (`extends`) to generics when you need to access specific properties. Add **defaults** when a type parameter is optional. Let TypeScript **infer** generic arguments from usage — explicit type arguments at call sites are a code smell unless disambiguation is necessary.

## Utility Type Selection

Pick the narrowest utility that expresses your intent:
- **Partial / Required** — optional/required toggle for all fields
- **Pick / Omit** — structural subsetting; prefer Pick (explicit) over Omit (implicit)
- **Record<K, V>** — homogeneous maps; use over index signatures for finite key sets
- **Extract / Exclude** — filter union members by assignability
- **ReturnType / Parameters / Awaited** — introspect function and promise types without duplication

## Key Rules

- Model state as **what is true**, not as flags. A `status: 'loading' | 'error' | 'success'` union with per-variant data beats three optional fields.
- `satisfies` validates a value against a type while preserving the narrowest inferred type. Use it for config objects and lookup tables.
- `as const` freezes inference to literal types. Required before `satisfies` for enum-like objects.
- `unknown` is the correct type for untrusted input. Narrow before use. `any` skips the compiler — use it only at integration seams you intend to replace.
- Type assertions (`as`) are a promise to the compiler. If that promise is wrong, runtime crashes follow. Prefer narrowing or `satisfies`.

See `references/process.md` for full utility type reference, generic patterns, conditional types, mapped types, `infer`, branded types, module augmentation, tsconfig options, and anti-patterns with fixes.
