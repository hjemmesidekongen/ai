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
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# Vue Patterns

Vue 3's Composition API is the default for all new work. Options API still works but should be reserved for existing code or gradual migrations.

## Composition API vs Options API

**Use Composition API** (`<script setup>`) for all new components. Logic is colocated by concern rather than option type, composables are natural, TypeScript inference is better, and the compiler optimizes `<script setup>` more aggressively.

**Options API is acceptable** when: migrating an existing component incrementally, working in a codebase with strong Options API conventions, or using mixins that haven't been extracted yet.

Never mix both styles in the same component.

## Reactivity Rules

`ref()` for primitives and anything that needs to be reassigned. `reactive()` for objects where you won't reassign the root reference. The critical rule: **never destructure a reactive object** — doing so strips reactivity. Use `toRefs()` to destructure safely.

`computed()` for derived state. Never recompute in templates. `watch()` when you need to react to a change with side effects. `watchEffect()` when you want automatic dependency tracking.

## Pinia Overview

Pinia is the official state management solution for Vue 3. Define stores with `defineStore()`. Use setup stores (Composition API style) over options stores for better TypeScript support and composable compatibility.

Access stores in components with `useXxxStore()`. Use `storeToRefs()` when destructuring store state to preserve reactivity. Actions are plain async functions — no mutations.

## Migration Guidance (Vue 2→3)

The largest breaking changes: Composition API replaces Options API as primary pattern, `Vue.set`/`Vue.delete` are gone (proxy-based reactivity handles this), filters are removed (use computed or methods), `$listeners` merged into `$attrs`, multiple root elements now allowed.

For Vuex→Pinia: map modules to individual stores, replace `commit` with direct action calls, replace `mapState`/`mapGetters` with `storeToRefs`.

See `references/process.md` for full API details, composables, Pinia patterns, reactivity pitfalls, slots, Teleport, Suspense, and anti-patterns.
