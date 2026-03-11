---
name: expo-jetpack-compose
description: >
  Jetpack Compose integration with Expo modules — native Android views, bridging patterns, and module API
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo jetpack compose"
  - "expo android native"
  - "expo modules kotlin"
  - "compose bridge"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "module_definition_complete"
      verify: "Module class extends Module with a definition() body; view factory registered via View() builder in Kotlin"
      fail_action: "Add Module subclass and register the view — missing registration makes the component invisible to JS"
    - name: "props_typed_correctly"
      verify: "All Compose-bound props use the Prop builder and types match between Kotlin and JS declarations"
      fail_action: "Align Kotlin Prop types with JS prop declarations — type mismatch causes silent null or crash on prop update"
    - name: "gradle_compose_enabled"
      verify: "buildFeatures { compose = true } and composeOptions with the correct Kotlin compiler extension version are set in build.gradle"
      fail_action: "Add Compose build features — Compose will not compile without the compiler plugin enabled"
  on_fail: "Expo Modules Kotlin setup has issues that will cause build failures or runtime crashes — fix before device testing"
  on_pass: "Expo Module Kotlin configuration is valid"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for smedjen"
---

# Expo Jetpack Compose

Expo Modules API supports Kotlin-first native Android modules. A `Module` subclass with a `definition()` body exposes functions, constants, and views to JavaScript — no Java, no `ReactPackage` registration required.

## Module Structure

Define the module, name it, and register functions and views in `definition()`. The `Name()` call must match the string used in `requireNativeModule()` on the JS side.

## Jetpack Compose View Integration

Expo views extend `ExpoView`. To host a Compose UI, add a `ComposeView` as a child and call `setContent {}` on it. Use `ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed` to align the Compose lifecycle with the Android view tree. When a prop changes, call `setContent {}` again to recompose with the new state.

## Props and Events

Props are declared with `Prop` in the module `definition()` and applied to the `ExpoView` subclass. Events use `EventDispatcher` and are registered with `Events()` in the definition. Fire them by calling the dispatcher with a plain map payload.

## Gradle Configuration

Compose requires explicit opt-in in the module's `build.gradle`:
- `buildFeatures { compose = true }`
- `composeOptions { kotlinCompilerExtensionVersion = "<version>" }`
- Compose BOM in dependencies for consistent artifact versions

Config plugins handle Gradle changes in managed workflow — don't edit `android/` files manually.

## Lifecycle

Compose lifecycle is tied to the `ViewCompositionStrategy`. Use `DisposeOnViewTreeLifecycleDestroyed` to align with the Android view lifecycle. For subscriptions, use `LaunchedEffect` inside the composable or `OnCreate` / `OnDestroy` in the module definition.

See `references/process.md` for full Kotlin module code, ComposeView setup, Gradle config, config plugins for Android, testing, debugging, and anti-patterns.
