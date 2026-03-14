# vue-patterns — Debugging Reference

## Common Debugging Scenarios

### Reactivity lost after destructuring
**Symptom:** Component stops updating when a reactive object's properties are spread or destructured into local variables.
**Root cause:** Destructuring breaks the Proxy wrapper. The local variable holds a plain value, not a reactive ref.
**Diagnosis:**
- Open Vue DevTools > Inspector > select the component
- Check the "Reactivity" section — destructured values show as plain, not reactive
- Search component code for `const { x, y } = someReactive` patterns
**Fix pattern:**
```js
// Wrong — loses reactivity
const { count } = store

// Correct — preserves reactivity via toRefs
const { count } = toRefs(store)

// Or use storeToRefs for Pinia stores
const { count } = storeToRefs(store)
```

### Watch not triggering on deep mutation
**Symptom:** A `watch()` callback never fires even though nested properties change.
**Root cause:** `watch()` defaults to shallow comparison. Mutating a nested property on a reactive object doesn't trigger a shallow watcher on the parent ref.
**Diagnosis:**
- Open Vue DevTools > Timeline > select "Component events"
- Trigger the mutation and confirm the reactive state actually changes in the Inspector
- If state changes but watch doesn't fire, the watcher is shallow
- Check the watch source — `watch(obj, cb)` on a `reactive()` object auto-deep-watches, but `watch(() => obj.nested, cb)` does not
**Fix pattern:**
```js
// Option 1: deep flag
watch(source, callback, { deep: true })

// Option 2: watch the specific nested path via getter
watch(() => state.nested.value, callback)

// Option 3: use watchEffect for automatic dependency tracking
watchEffect(() => { /* access the nested props here */ })
```

### Template ref null inside onMounted
**Symptom:** `templateRef.value` is `null` inside `onMounted`, even though the element exists in the template.
**Root cause:** The ref target is behind a `v-if` that evaluates to `false` at mount time, or the ref is inside a `<Suspense>` boundary that hasn't resolved.
**Diagnosis:**
- Search the template for the ref attribute: confirm it's not wrapped in `v-if="false"` or a conditional block
- Check if the component uses `<Suspense>` — refs inside the async child aren't available until `onMounted` of the parent
- Add a `watchEffect` to log ref value changes and see when it becomes non-null
**Fix pattern:**
```js
// Use watchEffect instead of relying on onMounted timing
watchEffect(() => {
  if (templateRef.value) {
    // safe to use
  }
})

// Or use v-show instead of v-if to keep the element in the DOM
```

### Pinia store action not updating
**Symptom:** Calling a Pinia action completes without error, but the store state doesn't reflect the change in components.
**Root cause:** The action assigns to `this` incorrectly, mutates a detached copy, or the component destructured the store without `storeToRefs`.
**Diagnosis:**
- Open Vue DevTools > Pinia inspector > select the store
- Call the action and watch whether the state updates in the inspector
- If it updates in the inspector but not the component: the component lost reactivity (destructuring issue)
- If it doesn't update in the inspector: the action itself is broken — check for `this.prop = newVal` vs returning a new object
- Check the Timeline tab for the action event and its payload
**Fix pattern:**
```js
// In the action — mutate via this, not a local copy
actions: {
  update(val) {
    this.count = val         // correct
    // const s = this; s = {} // wrong — reassigning local var
  }
}

// In the component — use storeToRefs
const store = useMyStore()
const { count } = storeToRefs(store)  // reactive
const { update } = store              // actions don't need toRefs
```

### v-model on custom component not working
**Symptom:** Two-way binding on a custom component doesn't update the parent, or updates the parent but not the child.
**Root cause:** The child component doesn't emit the correct event name or doesn't declare the `modelValue` prop (Vue 3 convention).
**Diagnosis:**
- Open Vue DevTools > Events tab > filter by the component
- Interact with the child and check whether `update:modelValue` events fire
- If no event fires: the child isn't emitting
- If the event fires with wrong payload: check the emit call
- Inspect the child's props list in DevTools — confirm `modelValue` is declared
**Fix pattern:**
```vue
<!-- Parent -->
<MyInput v-model="name" />

<!-- Child — must follow this contract -->
<script setup>
const props = defineProps<{ modelValue: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
</script>

<template>
  <input :value="modelValue" @input="emit('update:modelValue', $event.target.value)" />
</template>
```
For named v-models (`v-model:title`), the prop is `title` and the event is `update:title`.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Vue DevTools (browser) | Inspect component tree, state, events, reactivity | Install from Chrome/Firefox extension store |
| Vue DevTools Reactivity Inspector | Track which refs/reactive objects are being tracked | DevTools > Inspector > select component > Reactivity tab |
| Vue DevTools Timeline | Trace component events, watcher triggers, router navigation | DevTools > Timeline > filter by event type |
| Vue DevTools Pinia Inspector | Inspect store state, track actions, time-travel | DevTools > Pinia tab > select store |
| `console.log(isRef(x), isReactive(x))` | Quick check whether a value is still reactive | Inline in component setup |
| `watchEffect` with logging | Trace exactly when and why a dependency triggers | `watchEffect(() => console.log(val.value))` |
| `app.config.warnHandler` | Capture Vue warnings programmatically in tests | Set in app entry point |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
