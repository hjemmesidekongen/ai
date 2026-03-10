---
name: vue-patterns
description: >
  Vue 3 Composition API, reactivity system, Pinia state management, and
  Vue 2→3 migration patterns.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "vue patterns"
  - "vue composition api"
  - "pinia"
  - "vue reactivity"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "composition_api_used"
      verify: "New components use Composition API (setup() or <script setup>), not Options API"
      fail_action: "Refactor to Composition API unless Options API is explicitly justified"
    - name: "reactivity_intact"
      verify: "Reactive objects are not destructured without toRefs/storeToRefs"
      fail_action: "Wrap destructured reactive state with toRefs or storeToRefs"
    - name: "pinia_not_vuex"
      verify: "State management uses Pinia, not Vuex, in Vue 3 projects"
      fail_action: "Migrate Vuex store to Pinia or document reason for keeping Vuex"
  on_fail: "Vue patterns have structural issues — fix before merging"
  on_pass: "Vue patterns follow best practices"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced tutorial content with expert composable patterns, compiler macros, and SSR gotchas"
---

# Vue Patterns

## Composable Design Patterns

**When to extract**: logic uses 2+ reactive primitives together and appears in multiple components. Single `ref()` doesn't warrant a composable.

**Return shape**: always return an object (`{ data, loading, error, refresh }`), never a single ref. Allows destructuring and future extension without breaking callers.

**Naming**: `use` prefix, noun-oriented (`useAuth`, `useFormValidation`). Name describes the concern, not the implementation. Composables can call other composables — keep chains shallow (max 3 levels).

**Cleanup**: if a composable sets up listeners/timers/subscriptions, use `onUnmounted` internally. Callers shouldn't need to remember cleanup.

## provide/inject for Dependency Injection

Use for cross-cutting concerns needing 3+ levels of prop drilling: theme, locale, feature flags, form context. **Testing benefit**: `provide` in test wrappers replaces real services with mocks. Use `InjectionKey<T>` for type safety.

**Scope control**: provide at the nearest common ancestor, not app root — root-level provide is effectively a global (use Pinia instead). Always provide a fallback in `inject('key', defaultValue)` or throw explicitly.

## Vue Compiler Macros

**`defineModel()`**: two-way binding without manual emit boilerplate. `const model = defineModel<string>()` replaces the `modelValue` prop + `update:modelValue` emit pair. Supports named models: `defineModel('title')`.

**`defineSlots()`**: type-safe slot definitions. Enforces slot prop types at compile time. Use in library components where consumers need slot prop documentation.

**`defineExpose()`**: explicitly declare what `ref` on the component can access. Default in `<script setup>` is nothing exposed. Only expose imperative methods (focus, reset, validate) — never expose internal state.

## SSR/Nuxt Hydration Gotchas

**Hydration mismatch**: server and client must render identical initial HTML. Common causes: `Date.now()`, `Math.random()`, browser-only APIs (`window`, `localStorage`), conditional rendering based on screen size.

**Fix pattern**: `<ClientOnly>` wrapper for browser-dependent content. For data: use `useState()` (Nuxt) which serializes server state to `__NUXT_DATA__` for client hydration.

**Serialization limits**: `provide`/`inject` values aren't serialized across SSR boundary. Pinia state is (via `useNuxtApp().payload`). Plan store shape around what's JSON-serializable.

**`onMounted` is client-only**: any DOM measurement, intersection observer, or animation setup must go in `onMounted`. Code at `<script setup>` top-level runs on both server and client.

## Pinia Plugin Patterns and Store Composition

**Plugins**: `pinia.use(({ store }) => { store.$subscribe(...) })`. Common uses: persistence (`pinia-plugin-persistedstate`), undo/redo (track mutation history), logging.

**Store composition**: stores can import and use other stores. `useCartStore` calls `useProductStore().getProduct(id)`. Avoid circular dependencies — extract shared logic to a composable instead.
See `references/process.md` for reactivity pitfalls, slots, Teleport, Suspense, and anti-patterns.
