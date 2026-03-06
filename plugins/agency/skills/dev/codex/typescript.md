# TypeScript Conventions

Non-negotiable rules for all TypeScript code in this project.

## Strict Mode

`"strict": true` in tsconfig — always. No `// @ts-ignore` or `// @ts-expect-error` without a comment explaining why and a linked issue.

## No `any`

Never use `any`. Use `unknown` for truly unknown types, then narrow with type guards. If an external library forces `any`, wrap it in a typed utility function.

## Zod at System Boundaries

Validate all external data (API responses, form inputs, URL params, environment variables) with Zod schemas. Internal function parameters trust the type system — no runtime validation inside the app.

## Immutable Patterns

Never mutate objects or arrays. Use spread (`{...obj}`) or `structuredClone()` for deep copies. Prefer `readonly` arrays and `Readonly<T>` for shared types.

## const Assertions

Use `as const` for literal types and config objects. Prefer `satisfies` over type annotations when you want both type checking and narrow inference.

## Interface for Objects, Type for Unions

Use `interface` for object shapes (extensible). Use `type` for unions, intersections, and computed types. Never mix.

## Discriminated Unions

Use tagged unions with a `type` or `kind` discriminant for state machines and variant types. Exhaustive `switch` with `never` check in default:

```ts
function assertNever(x: never): never {
  throw new Error(`Unexpected: ${x}`);
}
```

## No Enums

Use `as const` objects instead. Enums have runtime overhead and unexpected behavior:

```ts
const STATUS = { ACTIVE: "active", INACTIVE: "inactive" } as const;
type Status = (typeof STATUS)[keyof typeof STATUS];
```

## Return Types on Public Functions

Explicitly annotate return types on exported functions and methods. Rely on inference for internal/private functions.

## Utility Types

Use built-in utility types (`Pick`, `Omit`, `Partial`, `Required`, `Record`) instead of manual type construction. Create project-specific utilities only when built-ins are insufficient.
