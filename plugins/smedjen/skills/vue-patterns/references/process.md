# Vue Patterns — Process Reference

## Composition API in Detail

### ref and reactive

```ts
const count = ref(0)          // access via count.value in JS, count in template
const user = reactive({ name: 'Alice', age: 30 })  // access directly: user.name

// WRONG — loses reactivity
const { name, age } = user

// CORRECT
const { name, age } = toRefs(user)
```

`ref()` wraps any value in a reactive container. In `<template>`, `.value` is unwrapped automatically. In `<script setup>`, always use `.value`.

`reactive()` uses a Proxy. Works only on objects (arrays, maps, sets included). Reassigning the root reference (`user = newObject`) breaks reactivity — use `ref` if you need to swap the whole object.

### computed

```ts
const fullName = computed(() => `${user.firstName} ${user.lastName}`)

// Writable computed
const doubled = computed({
  get: () => count.value * 2,
  set: (val) => { count.value = val / 2 }
})
```

Computed values are lazy and cached. They only re-evaluate when their reactive dependencies change. Never put side effects inside `computed`.

### watch and watchEffect

```ts
// watch — explicit source, lazy by default
watch(count, (newVal, oldVal) => {
  console.log(`changed from ${oldVal} to ${newVal}`)
})

// watch multiple sources
watch([firstName, lastName], ([newFirst, newLast]) => { ... })

// immediate execution
watch(count, handler, { immediate: true })

// deep watch (use sparingly — performance cost)
watch(user, handler, { deep: true })

// watchEffect — auto-tracks dependencies, runs immediately
watchEffect(() => {
  console.log(`count is ${count.value}`)
})
```

Prefer `watch` when you need the old value or want lazy execution. Use `watchEffect` for fire-and-forget side effects that need auto-tracking.

### Lifecycle Hooks

```ts
import { onMounted, onUnmounted, onUpdated, onBeforeMount } from 'vue'

onMounted(() => { /* DOM ready */ })
onUnmounted(() => { /* cleanup subscriptions, timers */ })
onUpdated(() => { /* after reactive data causes a re-render */ })
```

All lifecycle hooks must be called synchronously inside `setup()` or `<script setup>`. Calling them conditionally or after an `await` will not register them.

Vue 3 equivalents for Vue 2 hooks:
- `beforeCreate` / `created` → not needed; use `setup()` directly
- `beforeDestroy` → `onBeforeUnmount`
- `destroyed` → `onUnmounted`

---

## Composables Pattern

Composables are the Vue 3 replacement for mixins. A composable is a function that uses Vue reactivity and returns reactive state or methods.

```ts
// composables/useCounter.ts
import { ref, computed } from 'vue'

export function useCounter(initial = 0) {
  const count = ref(initial)
  const doubled = computed(() => count.value * 2)

  function increment() { count.value++ }
  function reset() { count.value = initial }

  return { count, doubled, increment, reset }
}

// In component
const { count, increment } = useCounter(10)
```

Rules for composables:
- Name with `use` prefix.
- Return refs and reactive values, not plain values.
- Clean up side effects in `onUnmounted` inside the composable.
- Accept `ref` or plain values as arguments — use `toValue()` (Vue 3.3+) to normalize.
- Do not call composables conditionally.

---

## Pinia

### Defining a Store

```ts
// stores/useUserStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

// Setup store (preferred)
export const useUserStore = defineStore('user', () => {
  const user = ref<User | null>(null)
  const isLoggedIn = computed(() => user.value !== null)

  async function login(credentials: Credentials) {
    user.value = await api.login(credentials)
  }

  function logout() {
    user.value = null
  }

  return { user, isLoggedIn, login, logout }
})
```

### Using a Store

```ts
const userStore = useUserStore()

// Access state directly (but don't destructure without storeToRefs)
console.log(userStore.user)

// WRONG — loses reactivity
const { user, isLoggedIn } = userStore

// CORRECT — storeToRefs extracts reactive state/getters
const { user, isLoggedIn } = storeToRefs(userStore)

// Actions can be destructured directly (they're not reactive refs)
const { login, logout } = userStore
```

### Actions

Actions are async-capable plain functions. No mutations. No `commit`. Just call them.

```ts
async function fetchProfile(id: string) {
  loading.value = true
  try {
    profile.value = await api.getProfile(id)
  } finally {
    loading.value = false
  }
}
```

### Getters

In setup stores, getters are `computed()` values. In options stores, they live in the `getters` key and receive `state` as argument.

### Store Plugins

Pinia plugins add properties or wrap actions across all stores:

```ts
pinia.use(({ store }) => {
  store.$onAction(({ name, after, onError }) => {
    after(() => { /* log success */ })
    onError((error) => { /* log failure */ })
  })
})
```

### Persistence

Use `pinia-plugin-persistedstate` for localStorage/sessionStorage persistence:

```ts
defineStore('user', () => { ... }, {
  persist: {
    key: 'user',
    storage: localStorage,
    pick: ['token']   // only persist the token, not the full user object
  }
})
```

---

## Reactivity Pitfalls

### Destructuring Reactive Objects

```ts
// WRONG
const { name } = reactive({ name: 'Alice' })  // name is a plain string

// CORRECT
const state = reactive({ name: 'Alice' })
const { name } = toRefs(state)  // name is a Ref<string>
```

### Replacing the Whole Reactive Object

```ts
// WRONG — breaks reactivity, component won't update
let state = reactive({ count: 0 })
state = reactive({ count: 1 })

// CORRECT — use ref for reassignable roots
const state = ref({ count: 0 })
state.value = { count: 1 }

// Or mutate in place
Object.assign(state, { count: 1 })
```

### Storing Non-Reactive Values in Reactive State

Avoid storing class instances, DOM nodes, or non-serializable objects in reactive state unless you understand the implications. Mark non-reactive with `markRaw()`.

```ts
const store = reactive({
  chart: markRaw(new ChartInstance())  // prevents deep reactivity on class
})
```

### Computed Side Effects

Never mutate state inside a `computed`. It causes infinite loops and is a Vue warning.

---

## provide / inject

For cross-component dependency injection without prop drilling:

```ts
// Parent
import { provide, ref } from 'vue'

const theme = ref('dark')
provide('theme', theme)  // provide a ref so it stays reactive

// Child (anywhere in tree)
import { inject } from 'vue'

const theme = inject('theme', ref('light'))  // second arg is default
```

Type-safe injection uses `InjectionKey`:

```ts
const ThemeKey: InjectionKey<Ref<string>> = Symbol('theme')
provide(ThemeKey, theme)
const theme = inject(ThemeKey)  // typed as Ref<string> | undefined
```

---

## Slots and Scoped Slots

```vue
<!-- Default slot -->
<slot />

<!-- Named slot -->
<slot name="header" />

<!-- Scoped slot — passes data back to parent -->
<slot :item="item" :index="index" />

<!-- Parent usage of scoped slot -->
<MyList v-slot="{ item, index }">
  {{ index }}: {{ item.name }}
</MyList>

<!-- Named scoped slot -->
<template #header="{ title }">
  <h1>{{ title }}</h1>
</template>
```

Use scoped slots to invert control: the child manages data and layout logic, the parent controls rendering.

---

## Vue 2 → Vue 3 Migration Checklist

### Breaking Changes

- [ ] `new Vue()` → `createApp()`
- [ ] `Vue.component()` → `app.component()`
- [ ] `Vue.directive()` → `app.directive()`
- [ ] `Vue.use()` → `app.use()`
- [ ] `Vue.set` / `Vue.delete` → not needed (Proxy handles it)
- [ ] `$listeners` merged into `$attrs`
- [ ] `$scopedSlots` removed — use `$slots` (slots are now functions)
- [ ] `v-model` breaking change: prop is `modelValue`, event is `update:modelValue`
- [ ] `.sync` modifier removed — use `v-model:propName`
- [ ] `destroyed` → `unmounted`, `beforeDestroy` → `beforeUnmount`
- [ ] Filters removed — replace with computed properties or methods
- [ ] Multiple root elements now allowed (no more single root requirement)
- [ ] `<transition>` class names changed: `v-enter` → `v-enter-from`

### Vuex → Pinia Migration

- [ ] Create a Pinia store per Vuex module
- [ ] Replace `state` with `ref()` / `reactive()`
- [ ] Replace `getters` with `computed()`
- [ ] Replace `mutations` + `actions` with plain `async function`s
- [ ] Replace `commit('mutation')` with direct action call
- [ ] Replace `mapState` / `mapGetters` with `storeToRefs()`
- [ ] Replace `mapActions` with destructuring actions from store

### Recommended Migration Order

1. Upgrade Vue version with compat build enabled
2. Fix all deprecation warnings in compat mode
3. Migrate Vuex to Pinia module by module
4. Convert Options API components to Composition API progressively (high-churn files first)
5. Remove compat build

---

## Teleport

Renders component DOM output at a different mount target, useful for modals and tooltips:

```vue
<Teleport to="body">
  <div class="modal">...</div>
</Teleport>
```

`to` accepts any CSS selector or DOM element. Multiple Teleports to the same target render in order. Use `disabled` prop to conditionally disable teleporting.

---

## Suspense

Handles async setup (async `setup()` function or `<script setup>` with top-level `await`):

```vue
<Suspense>
  <template #default>
    <AsyncComponent />
  </template>
  <template #fallback>
    <LoadingSpinner />
  </template>
</Suspense>
```

`Suspense` is still experimental in Vue 3.x but widely used. Combine with error boundaries using `onErrorCaptured` in a parent component.

---

## Common Anti-Patterns

**Mutating props directly.** Props are read-only. Use an emit or a local ref copy.

**Using `reactive` for primitives.** `reactive(0)` returns `0`, not a reactive wrapper. Use `ref(0)`.

**`v-if` and `v-for` on the same element.** `v-if` wins in Vue 3 (changed from Vue 2 where `v-for` won). Never combine on one element — wrap with a `<template>`.

**Watching the result of a function directly.**
```ts
// WRONG — not reactive
watch(store.getUser(), handler)

// CORRECT — getter form
watch(() => store.user, handler)
```

**Large components with no composable extraction.** If a component's `<script setup>` exceeds ~100 lines, extract domain logic into composables. Components should orchestrate, not implement.

**Storing derived data in state.** If a value can be computed from other state, use `computed`. Storing derived data creates sync bugs.

**Calling composables inside conditionals or loops.**
```ts
// WRONG
if (isAdmin) {
  const { data } = useAdminData()  // hook rules violation
}
```

Composables must be called at the top level of `setup()`, just like React hooks.
