---
name: expo-dev-client
description: >
  Custom Expo dev client setup, native module debugging, and development
  build workflows for projects that need native code beyond Expo Go's scope.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo dev client"
  - "custom dev client"
  - "expo development build"
  - "expo native debug"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "dev_client_package_installed"
      verify: "expo-dev-client is in package.json dependencies, not devDependencies"
      fail_action: "Move expo-dev-client to dependencies — it ships in the build"
    - name: "no_expo_go_assumption"
      verify: "App does not assume Expo Go runtime — no bare expo-go-only APIs in use"
      fail_action: "Replace Expo Go-specific patterns with dev client equivalents"
    - name: "eas_development_profile"
      verify: "eas.json has a development profile with developmentClient: true"
      fail_action: "Add development profile to eas.json with correct simulator/device flags"
    - name: "prebuild_not_manual"
      verify: "Native directories generated via expo prebuild, not hand-edited"
      fail_action: "Run expo prebuild --clean and apply changes through config plugins"
  on_fail: "Dev client setup has gaps — fix before building"
  on_pass: "Dev client configuration is correct"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# expo-dev-client

`expo-dev-client` replaces Expo Go with a custom native runtime that includes your app's native modules and config plugin modifications. Required as soon as you add any package with a native layer.

## Dev Client vs Expo Go

**Expo Go**: sandboxed, zero-build, Expo SDK modules only. No third-party native modules, no custom native code. Start here. **Dev Client**: a real development build of your app — includes your native dependencies, config plugin results, and custom native code. Requires a one-time build per native change; JS changes reload instantly without rebuilding.

Switch from Expo Go to dev client the moment you need a native module.

## Setup

```bash
npx expo install expo-dev-client
npx expo start --dev-client   # after building and installing the dev client app
```

EAS Build development profile:
```json
{ "build": { "development": { "developmentClient": true, "distribution": "internal",
    "ios": { "simulator": true }, "android": { "buildType": "apk" } } } }
```

Build: `eas build --profile development --platform ios|android`

## Prebuild Workflow

Native directories are managed by `expo prebuild` — never edit `android/` or `ios/` by hand. Apply all native customizations through config plugins in `app.config.js`. Run `npx expo prebuild --clean` to regenerate.

## Debugging Tools

- **React DevTools**: `j` in Metro terminal or shake device
- **Flipper**: add `react-native-flipper`; Network, Layout, and DB plugins work in dev client builds
- **Xcode / Android Studio**: full native debuggers, instruments, logcat, memory profiler
- **Network**: Proxyman or Flipper Network plugin with SSL proxying

See `references/process.md` for native module integration, config plugin authoring, team distribution via EAS, error handling patterns, and anti-patterns.
