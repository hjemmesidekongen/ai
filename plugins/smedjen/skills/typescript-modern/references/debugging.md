# typescript-modern — Debugging Reference

## Common Debugging Scenarios

### Excessively deep type instantiation

**Symptom:** `Type instantiation is excessively deep and possibly infinite (ts2589)`. Build hangs or OOMs on large conditional types.

**Root cause:** Recursive conditional types that expand beyond the 50-level depth limit. Usually caused by mapped types over unions that branch into further conditionals at each level, or circular type references through generics.

**Diagnosis:**

- Isolate the type in a minimal `.ts` file — strip everything except the failing type alias and a test assignment
- Run `tsc --generateTrace ./trace-output` on the minimal file, then open `trace-output/trace.json` in `chrome://tracing` — look for the deepest `checkTypeRelatedTo` or `instantiateType` stacks
- Add `// @ts-expect-error` above the failing line to confirm it's the sole source — if the error disappears elsewhere too, the type is referenced in multiple locations

**Fix pattern:**

- Insert explicit `never` short-circuits early in conditional branches: `T extends never ? never : ...`
- Break deeply nested conditionals into separate named type aliases — each alias resets the depth counter
- Replace recursive utility types with iterative tuple-accumulator patterns (e.g., `TupleOf<T, N, Acc extends T[]>`)
- If the type is a library generic you don't control, wrap it with a bounded version: `type Safe<T> = T extends infer U ? MyType<U & SomeConstraint> : never`

### any propagation

**Symptom:** Values silently widen to `any`, bypassing all type checks. Bugs appear at runtime in code that compiled without errors. `tsc` reports zero errors on clearly wrong assignments.

**Root cause:** An `any` entered the type graph — from an untyped import, a JSON parse, a third-party `d.ts` with loose signatures, or a missing return type — and propagated through assignments and function calls.

**Diagnosis:**

- Enable `"noImplicitAny": true` in `tsconfig.json` — recompile and fix every new error
- Add `@typescript-eslint/no-unsafe-assignment`, `no-unsafe-call`, `no-unsafe-member-access`, and `no-unsafe-return` rules set to `error` in ESLint — run `eslint --ext .ts src/` and review hits
- Hover suspect variables in VS Code — if the tooltip shows `any`, trace back through assignments to find where the type was lost
- Run `tsc --noEmit --strict` as a one-off check even if the project doesn't use strict mode — the delta shows where `any` hides

**Fix pattern:**

- Add explicit type annotations at `any` entry points: function parameters, return types, and destructured values from untyped sources
- Use `unknown` instead of `any` for genuinely unknown data, then narrow with type guards
- For third-party libraries missing types, add a local `@types` declaration file or use `declare module` with specific signatures
- Add `no-explicit-any` as an ESLint error to prevent future introduction

### Union narrowing not working

**Symptom:** TypeScript doesn't narrow a union inside an `if` or `switch` block. Properties that should be accessible after a check still show type errors like `Property 'x' does not exist on type 'A | B'`.

**Root cause:** The discriminant property is typed as `string` instead of a literal type, the check uses a non-narrowing pattern (e.g., bracket access with a variable key), or the control flow is broken by a closure or async boundary.

**Diagnosis:**

- Hover the discriminant property in the IDE — confirm it shows literal types (`"circle" | "square"`) not `string`
- Hover the variable inside the narrowed block — if it still shows the full union, narrowing failed
- Check if the narrowing happens inside a callback or `async` closure — TypeScript does not narrow across closure boundaries
- Verify the check uses `===` or `!==` — loose equality (`==`) narrows fewer cases
- If using `in` operator, confirm the property is unique to one branch of the union

**Fix pattern:**

- Declare discriminant fields with `as const` or literal types: `type Circle = { kind: "circle"; radius: number }`
- Extract closure-blocked narrowing into a variable before the closure: `const narrow = value; callback(() => narrow.prop)`
- Use `assertNever` in the default branch of switch statements to catch un-narrowed cases: `function assertNever(x: never): never { throw new Error("Unexpected: " + x); }`
- For complex narrowing, use a user-defined type guard: `function isCircle(s: Shape): s is Circle { return s.kind === "circle"; }`

### Generic constraint too wide or too narrow

**Symptom:** A generic function accepts types it shouldn't (too wide) or rejects valid types with `Type 'X' does not satisfy the constraint 'Y'` (too narrow). Callers get unexpected inference results.

**Root cause:** The `extends` constraint doesn't match the actual usage. Common: constraining with an interface when a structural subset would work, or constraining with a union when the function actually needs a specific member.

**Diagnosis:**

- Call the function with explicit type arguments instead of relying on inference: `fn<ExactType>(arg)` — this surfaces the real constraint mismatch
- Check what the function body actually accesses on `T` — the constraint should match that, nothing more
- If inference produces `unknown` or an unexpected union, add a type parameter default (`T = SomeType`) temporarily to see where inference diverges
- Use `tsc --noEmit` with `// ^?` (twoslash) comments or the TypeScript Playground to inspect inferred types at each call site

**Fix pattern:**

- Tighten wide constraints by adding the minimum required properties: `<T extends { id: string }>` instead of `<T extends object>`
- Loosen narrow constraints by removing properties the function body doesn't access
- Use `extends` with mapped/conditional types when the constraint depends on another type parameter: `<K extends keyof T>`
- Split overloaded generics into separate function signatures when one constraint can't cover all valid call patterns

### Module augmentation not taking effect

**Symptom:** `declare module` augmentations exist in a `.d.ts` file but TypeScript doesn't see the added types. Properties added via augmentation show as errors. No compile error on the augmentation file itself.

**Root cause:** The augmentation file isn't included in the compilation, the module specifier doesn't match exactly, or the file is treated as a script (no `import`/`export`) instead of a module.

**Diagnosis:**

- Run `tsc --listFiles | grep <augmentation-filename>` — if the file doesn't appear, it's not included in the compilation
- Check `tsconfig.json` `include` and `exclude` arrays — the augmentation file's path must match an include pattern and not be excluded
- Verify the module specifier in `declare module "..."` matches exactly what's used in import statements (including path separators, scope prefixes like `@org/pkg`)
- Confirm the file has at least one top-level `import` or `export` statement — without it, TypeScript treats it as a global script and `declare module` creates an ambient module instead of augmenting
- Run `tsc --traceResolution` and search for the module name — check which `.d.ts` files TypeScript resolves

**Fix pattern:**

- Add an empty `export {}` at the top of the augmentation file to force module mode
- Move the `.d.ts` file into a directory covered by `include`, or add its path explicitly
- Match the module specifier character-for-character with the import path — `"express"` is different from `"express/index"`
- For path-mapped modules (`@/foo`), augment the mapped path, not the alias
- If augmenting a module's subpath, check whether the package uses `exports` in `package.json` — the augmentation must target the resolved entry point

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| tsc --generateTrace | Deep type performance issues, instantiation depth problems | `tsc --generateTrace ./trace-out` then open `trace-out/trace.json` in chrome://tracing |
| tsc --noEmit --strict | One-off strict check to find `any` leaks without changing config | `tsc --noEmit --strict` |
| tsc --listFiles | Verify which files are included in compilation | `tsc --listFiles \| grep <filename>` |
| tsc --traceResolution | Debug module resolution order and paths | `tsc --traceResolution 2>&1 \| grep <module-name>` |
| tsc --explainFiles | Understand why a file is included | `tsc --explainFiles \| grep <filename> -A 3` |
| typescript-eslint | Catch `any` propagation and unsafe operations | `eslint --ext .ts src/ --rule '{"@typescript-eslint/no-unsafe-assignment": "error"}'` |
| VS Code hover | Quick type inspection at any expression | Hover variable, check tooltip type |
| // @ts-expect-error | Isolate whether a specific line is the error source | Add above suspect line, rebuild |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
