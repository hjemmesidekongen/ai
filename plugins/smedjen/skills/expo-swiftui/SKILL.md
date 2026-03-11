---
name: expo-swiftui
description: >
  SwiftUI integration with Expo modules — native iOS views, bridging patterns, and module API
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo swiftui"
  - "expo ios native"
  - "expo modules swift"
  - "swiftui bridge"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "module_definition_complete"
      verify: "Module class conforms to Module protocol with Definition() body; view factory registered via View() builder"
      fail_action: "Add Module conformance and register the view — missing registration makes the component invisible to JS"
    - name: "props_typed_correctly"
      verify: "All SwiftUI-bound props use the Prop builder and types match between Swift and JS declarations"
      fail_action: "Align Swift Prop types with JS prop declarations — type mismatch causes silent nil or crash on prop update"
    - name: "config_plugin_for_permissions"
      verify: "Any iOS permission has a config plugin adding the NSUsageDescription key — plist not edited manually"
      fail_action: "Add a config plugin entry — missing plist key crashes on iOS 14+ at permission request"
  on_fail: "Expo Modules Swift setup has issues that will cause build failures or runtime crashes — fix before device testing"
  on_pass: "Expo Module Swift configuration is valid"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for smedjen"
---

# Expo SwiftUI

Expo Modules API is Swift-first. A `Module` subclass with a `Definition()` body exposes functions, constants, and views to JavaScript — no Objective-C bridging or `.m` files required.

## Module Structure

Define the module, name it, and register any functions and views in `definition()`. The `Name()` call must match the string used in `requireNativeModule()` on the JS side.

## SwiftUI View Integration

Expo views subclass `ExpoView` (not `UIView`). To host a SwiftUI view, wrap it in a `UIHostingController` and add the hosting controller's view as a subview. Override `layoutSubviews()` to keep the hosted view's frame in sync with `bounds`.

## Props and Events

Props are declared with `Prop` in the module `Definition()` and applied to the `ExpoView` subclass. Events use `@EventDispatcher` on the view class and are registered with `Events()` in the definition. Fire them by calling the dispatcher with a plain dictionary payload.

## Accessing iOS APIs

Call any iOS SDK directly from the module or view. APIs requiring permissions need a config plugin that adds the `NSUsageDescription` key to `Info.plist` — never edit `Info.plist` manually since `expo prebuild` regenerates it.

## Lifecycle

`ExpoView` lifecycle: `didMoveToWindow()`, `willMove(toSuperview:)`, and SwiftUI `.onAppear` / `.onDisappear` inside the hosted view. Module-level lifecycle uses `OnCreate` and `OnDestroy` in the definition body.

## Native Navigation Integration

To push native UIKit screens from within a module, access the root view controller via `appContext?.utilities?.currentViewController()`. Avoid doing this in props — use a module function that JS calls explicitly.

See `references/process.md` for full Swift module code, `UIHostingController` setup, config plugin patterns, testing native modules, debugging on-device, and anti-patterns.
