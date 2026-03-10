# typescript-modern — Process Reference

Full reference for utility types, generic patterns, advanced type constructs, tsconfig, and anti-patterns.

---

## Utility Types

### Partial / Required
```ts
Partial<T>   // all fields optional
Required<T>  // all fields required
```
Use `Partial` for update payloads. Use `Required` to assert a hydrated state after loading.

### Pick / Omit
```ts
Pick<T, 'a' | 'b'>   // keep only listed keys
Omit<T, 'a' | 'b'>   // drop listed keys
```
Prefer `Pick` — it makes what you need explicit. `Omit` hides what you're removing, which creates drift when the source type grows.

### Record
```ts
Record<'admin' | 'editor' | 'viewer', Permission>
```
Use for homogeneous maps with a finite known key set. More precise than `{ [key: string]: V }`.

### Extract / Exclude
```ts
Extract<'a' | 'b' | 'c', 'a' | 'c'>  // → 'a' | 'c'
Exclude<'a' | 'b' | 'c', 'a' | 'c'>  // → 'b'
```
Use to filter union members. Useful when building derived unions from a master set.

### ReturnType / Parameters / Awaited
```ts
ReturnType<typeof fn>        // infer return type
Parameters<typeof fn>        // infer parameter tuple
Awaited<ReturnType<typeof asyncFn>>  // unwrap promise
```
Use to derive types from existing functions — avoids duplication when the function is the source of truth.

### NonNullable / Required (deep)
```ts
NonNullable<T | null | undefined>  // → T
```
Use at boundaries where null has been checked and you want the type to reflect that.

---

## Generics

### Constraints
```ts
function getKey<T extends { id: string }>(item: T): string {
  return item.id;
}
```
Add `extends` when you need to access a property. Do not over-constrain — the narrower the constraint, the wider the reuse.

### Defaults
```ts
type ApiResponse<T = unknown> = { data: T; status: number };
```
Provide defaults for type parameters that are optional at usage.

### Inference
```ts
function wrap<T>(value: T): { value: T } { return { value }; }
wrap(42); // T inferred as 42 (with const assertion) or number
```
Let TypeScript infer from usage. Explicit type arguments at call sites signal a design smell — usually means the function's types are not expressive enough.

### Generic Constraints with Conditional Return
```ts
function parse<T extends string | number>(
  input: T
): T extends string ? Date : number {
  // ...
}
```
Use sparingly. Conditional return types based on input type are powerful but hard to maintain. Prefer discriminated unions where possible.

---

## Discriminated Unions

```ts
type Result<T> =
  | { status: 'ok'; data: T }
  | { status: 'error'; message: string }
  | { status: 'loading' };

function handle<T>(result: Result<T>) {
  switch (result.status) {
    case 'ok':    return result.data;
    case 'error': return result.message;
    case 'loading': return null;
    default: {
      const _exhaustive: never = result;
      throw new Error(`Unhandled: ${_exhaustive}`);
    }
  }
}
```

The `never` assignment in the default branch is a compile-time exhaustiveness check. Adding a new variant without updating the switch becomes a type error.

---

## Template Literal Types

```ts
type EventName<T extends string> = `on${Capitalize<T>}`;
type ButtonEvent = EventName<'click' | 'focus'>;  // 'onClick' | 'onFocus'

type Route = `/api/${string}`;
type UserRoute = `/users/${number}`;
```

Use to constrain string shapes at the type level — event names, route patterns, CSS property prefixes. Avoid when the resulting type is too broad to be useful at runtime.

---

## satisfies Operator

```ts
const palette = {
  red: [255, 0, 0],
  green: '#00ff00',
} satisfies Record<string, string | number[]>;

// palette.red is inferred as number[], not string | number[]
// satisfies validates shape, preserves narrow inference
```

Use `satisfies` for config objects and lookup tables where you want both type safety and preserved narrowness. Replaces the pattern of declaring a typed variable then casting back.

---

## const Assertions

```ts
const directions = ['north', 'south', 'east', 'west'] as const;
type Direction = typeof directions[number]; // 'north' | 'south' | 'east' | 'west'

const config = { env: 'production', debug: false } as const;
```

Use `as const` to freeze literal inference. Required before using an object/array as a type source. Combine with `typeof` to derive union types from data.

---

## Conditional Types

```ts
type IsArray<T> = T extends any[] ? true : false;
type Flatten<T> = T extends Array<infer Item> ? Item : T;
```

Conditional types are evaluated distributively over unions. Use for type-level branching. Keep them readable — nested conditionals become unmaintainable fast.

---

## Mapped Types

```ts
type Readonly<T> = { readonly [K in keyof T]: T[K] };
type Nullable<T> = { [K in keyof T]: T[K] | null };
type Getters<T> = { [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K] };
```

Use mapped types to systematically transform type shapes. Key remapping (`as`) allows renaming while mapping.

---

## infer Keyword

```ts
type UnpackPromise<T> = T extends Promise<infer U> ? U : T;
type FirstArg<T> = T extends (first: infer F, ...rest: any[]) => any ? F : never;
```

`infer` extracts a type from a pattern match. Use inside conditional types to capture matched sub-types. Keep inference patterns simple — complex `infer` chains are hard to debug.

---

## Branded Types

```ts
type UserId = string & { readonly _brand: 'UserId' };
type OrderId = string & { readonly _brand: 'OrderId' };

function createUserId(id: string): UserId {
  return id as UserId;
}
```

Branded types prevent accidentally passing a `UserId` where an `OrderId` is expected, even though both are `string` at runtime. Use at domain boundaries where identity confusion causes bugs. The brand field only exists at the type level — zero runtime cost.

---

## Module Augmentation

```ts
// Extend an existing module's types
declare module 'express' {
  interface Request {
    user?: AuthenticatedUser;
  }
}
```

Use to extend third-party types without forking. Place in a `.d.ts` file included by your `tsconfig`. Do not overload augmentations — they apply globally and can conflict across packages.

---

## Declaration Merging

```ts
interface Config { host: string }
interface Config { port: number }
// Merges to: interface Config { host: string; port: number }
```

Interfaces merge; types do not. Use interface when you expect consumers to extend (e.g., plugin systems). Use `type` for unions, intersections, and computed types where merging would be confusing.

---

## tsconfig Key Options

| Option | Recommended | Why |
|--------|-------------|-----|
| `strict` | `true` | Enables all strict checks — `strictNullChecks`, `noImplicitAny`, etc. |
| `noUncheckedIndexedAccess` | `true` | Index access returns `T \| undefined`, not just `T` |
| `exactOptionalPropertyTypes` | `true` | `{ a?: string }` means `a` is absent or string, not `undefined` |
| `noImplicitReturns` | `true` | All code paths in a function must return |
| `noFallthroughCasesInSwitch` | `true` | Prevents accidental switch fallthrough |
| `moduleResolution` | `bundler` or `node16` | Match your runtime/bundler |
| `isolatedModules` | `true` | Required for esbuild/swc/Babel transpilation |
| `verbatimModuleSyntax` | `true` (ESM projects) | Enforces explicit `import type` — reduces bundler confusion |

---

## Common Anti-Patterns

### any abuse
```ts
// Bad
function process(data: any) { return data.value; }

// Good
function process(data: unknown) {
  if (typeof data === 'object' && data !== null && 'value' in data) {
    return (data as { value: unknown }).value;
  }
}
```
`any` infects callers. `unknown` forces safe narrowing at the boundary.

### Over-typing with redundant annotations
```ts
// Bad — TypeScript already infers this
const count: number = 0;
const fn: (x: number) => number = (x) => x + 1;

// Good — let inference work
const count = 0;
const fn = (x: number) => x + 1;
```
Annotate where inference cannot reach or where the inferred type is too wide. Elsewhere, trust inference.

### Unnecessary type assertions
```ts
// Bad
const el = document.getElementById('root') as HTMLDivElement;

// Good — narrow with a check
const el = document.getElementById('root');
if (!(el instanceof HTMLDivElement)) throw new Error('Root not found');
```
`as` skips the compiler. When wrong, it produces runtime errors with no TypeScript warning. Narrow explicitly whenever possible.

### Index signatures hiding `undefined`
```ts
// Without noUncheckedIndexedAccess
const map: Record<string, string> = {};
const val = map['missing']; // TypeScript says string, runtime says undefined

// With noUncheckedIndexedAccess enabled: val is string | undefined
```
Enable `noUncheckedIndexedAccess` and handle the `undefined` case.

### Type widening on const objects
```ts
// Bad — roles inferred as string[]
const roles = ['admin', 'editor'];

// Good — roles inferred as readonly ['admin', 'editor']
const roles = ['admin', 'editor'] as const;
type Role = typeof roles[number]; // 'admin' | 'editor'
```
Without `as const`, array literals widen to `string[]`, losing the union.

### Intersection instead of extends for object merging
```ts
// Fragile — intersections of conflicting types produce never
type A = { id: string } & { id: number }; // id: never

// Correct — use interface extends or explicit merging
interface Base { id: string }
interface Extended extends Base { name: string }
```
Intersections do not merge — they narrow. Two conflicting property types produce `never` silently.
