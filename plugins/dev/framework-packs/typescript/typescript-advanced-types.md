---
origin: "wshobson/agents"
origin_skill: "typescript-advanced-types"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "Core Concepts (all 5: Generics, Conditional Types, Mapped Types, Template Literal Types, Utility Types), Patterns 3-6 (Deep Readonly/Partial, Form Validation, Discriminated Unions, Type-Safe API Client), Type Inference Techniques, Best Practices, Common Pitfalls"
sections_removed: "Pattern 1 (Type-Safe Event Emitter), Pattern 2 (Builder Pattern) — less common per findings.md; Resources list"
---

# TypeScript Advanced Types

Generics, conditional types, mapped types, template literals, and utility types for type-safe applications.

## When to Use This Skill

- Building type-safe libraries or generic components
- Implementing complex type inference
- Designing type-safe API clients
- Building form validation systems
- Creating strongly-typed state machines

## Core Concepts

### 1. Generics

```typescript
function identity<T>(value: T): T { return value }

// Constraints
interface HasLength { length: number }
function logLength<T extends HasLength>(item: T): T {
  console.log(item.length)
  return item
}

// Multiple type parameters
function merge<T, U>(obj1: T, obj2: U): T & U {
  return { ...obj1, ...obj2 }
}
```

### 2. Conditional Types

```typescript
type IsString<T> = T extends string ? true : false

// Extract return type (built-in exists, but shows the pattern)
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never

// Distributive conditional
type ToArray<T> = T extends any ? T[] : never
type StrOrNumArray = ToArray<string | number> // string[] | number[]

// Nested condition
type TypeName<T> =
  T extends string ? 'string' :
  T extends number ? 'number' :
  T extends boolean ? 'boolean' :
  T extends Function ? 'function' :
  'object'
```

### 3. Mapped Types

```typescript
// Transform properties
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
}

// Filter properties by type
type PickByType<T, U> = {
  [K in keyof T as T[K] extends U ? K : never]: T[K]
}

interface Mixed { id: number; name: string; age: number; active: boolean }
type OnlyNumbers = PickByType<Mixed, number>  // { id: number; age: number }
```

### 4. Template Literal Types

```typescript
type EventName = 'click' | 'focus' | 'blur'
type EventHandler = `on${Capitalize<EventName>}`  // "onClick" | "onFocus" | "onBlur"

// Nested path building
type Path<T> = T extends object
  ? { [K in keyof T]: K extends string ? `${K}` | `${K}.${Path<T[K]>}` : never }[keyof T]
  : never
```

### 5. Utility Types

```typescript
Partial<T>           // All optional
Required<T>          // All required
Readonly<T>          // All readonly
Pick<T, K>           // Select properties
Omit<T, K>           // Remove properties
Exclude<T, U>        // Exclude from union
Extract<T, U>        // Extract from union
NonNullable<T>       // Remove null/undefined
Record<K, T>         // Object with specific keys
ReturnType<T>        // Function return type
Parameters<T>        // Function parameter types
Awaited<T>           // Unwrap Promise type
```

## Advanced Patterns

### Pattern: Deep Readonly/Partial

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object
    ? T[P] extends Function ? T[P] : DeepReadonly<T[P]>
    : T[P]
}

type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object
    ? T[P] extends Array<infer U> ? Array<DeepPartial<U>> : DeepPartial<T[P]>
    : T[P]
}
```

### Pattern: Type-Safe API Client

```typescript
type HTTPMethod = 'GET' | 'POST' | 'PUT' | 'DELETE'

type EndpointConfig = {
  '/users': {
    GET: { response: User[] }
    POST: { body: { name: string; email: string }; response: User }
  }
  '/users/:id': {
    GET: { params: { id: string }; response: User }
    PUT: { params: { id: string }; body: Partial<User>; response: User }
    DELETE: { params: { id: string }; response: void }
  }
}

type ExtractResponse<T> = T extends { response: infer R } ? R : never

// Result: api.request('/users', 'GET') returns Promise<User[]>
```

### Pattern: Type-Safe Form Validation

```typescript
type ValidationRule<T> = { validate: (value: T) => boolean; message: string }
type FieldValidation<T> = { [K in keyof T]?: ValidationRule<T[K]>[] }
type ValidationErrors<T> = { [K in keyof T]?: string[] }

class FormValidator<T extends Record<string, any>> {
  constructor(private rules: FieldValidation<T>) {}

  validate(data: T): ValidationErrors<T> | null {
    const errors: ValidationErrors<T> = {}
    let hasErrors = false
    for (const key in this.rules) {
      const fieldErrors = this.rules[key]
        ?.filter(rule => !rule.validate(data[key]))
        .map(rule => rule.message) ?? []
      if (fieldErrors.length > 0) {
        errors[key] = fieldErrors
        hasErrors = true
      }
    }
    return hasErrors ? errors : null
  }
}
```

### Pattern: Discriminated Unions

```typescript
type AsyncState<T> =
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string }

function handleState<T>(state: AsyncState<T>): void {
  switch (state.status) {
    case 'success': console.log(state.data); break   // Type: T
    case 'error': console.log(state.error); break    // Type: string
    case 'loading': console.log('Loading...'); break
  }
}

// State machine
type State =
  | { type: 'idle' }
  | { type: 'fetching'; requestId: string }
  | { type: 'success'; data: any }
  | { type: 'error'; error: Error }

type Event =
  | { type: 'FETCH'; requestId: string }
  | { type: 'SUCCESS'; data: any }
  | { type: 'ERROR'; error: Error }
  | { type: 'RESET' }
```

## Type Inference Techniques

### Infer Keyword

```typescript
type ElementType<T> = T extends (infer U)[] ? U : never
type PromiseType<T> = T extends Promise<infer U> ? U : never
// Parameters<T> and ReturnType<T> use this pattern
```

### Type Guards

```typescript
function isString(value: unknown): value is string {
  return typeof value === 'string'
}

function isArrayOf<T>(value: unknown, guard: (item: unknown) => item is T): value is T[] {
  return Array.isArray(value) && value.every(guard)
}
```

### Assertion Functions

```typescript
function assertIsString(value: unknown): asserts value is string {
  if (typeof value !== 'string') throw new Error('Not a string')
}
// After call, TypeScript knows value is string
```

## Best Practices

1. Use `unknown` over `any` — enforce type checking
2. Prefer `interface` for object shapes — better error messages
3. Use `type` for unions and complex transformations
4. Leverage type inference — don't annotate what TypeScript can infer
5. Avoid type assertions (`as`) — use type guards instead
6. Enable strict mode — `"strict": true` in tsconfig
7. Document complex types with JSDoc comments
8. Use const assertions for literal types: `['a', 'b'] as const`

## Common Pitfalls

1. Over-using `any` — defeats TypeScript's purpose
2. Ignoring strict null checks — causes runtime errors
3. Overly complex nested types — slows compilation
4. Not using discriminated unions — misses narrowing opportunities
5. Missing `readonly` modifiers — allows unintended mutations
6. Circular type references — causes compiler errors
