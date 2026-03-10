# expo-dev-client — Process Reference

Full reference for dev client setup, native module integration, config plugins, prebuild workflow, EAS Build distribution, debugging tools, error handling, and anti-patterns.

---

## Dev Client vs Expo Go — Decision Matrix

| Need | Expo Go | Dev Client |
|------|---------|------------|
| Expo SDK modules only | ✓ | ✓ |
| Third-party native module | ✗ | ✓ |
| Custom native code (Swift/Kotlin) | ✗ | ✓ |
| Config plugin that modifies AndroidManifest or Info.plist | ✗ | ✓ |
| Fast JS iteration (no native change) | ✓ | ✓ (no rebuild needed) |
| Zero-install QR scan workflow | ✓ | ✗ |
| Multiple team members with shared build | n/a | ✓ via EAS internal distribution |

Rule: start with Expo Go, migrate when the first native dependency lands.

---

## Full Setup Walkthrough

### 1. Install

```bash
npx expo install expo-dev-client
```

`expo-dev-client` must be in `dependencies`, not `devDependencies` — it is bundled into the native build.

### 2. Entry point

For bare workflow (or if using Expo Router v2+), the entry point is already correct. For classic Expo, ensure `App.js` does not import anything that conflicts with the dev client launcher.

### 3. app.json / app.config.js

```json
{
  "expo": {
    "developmentClient": {
      "silentLaunch": false
    }
  }
}
```

`silentLaunch: true` skips the launcher screen and connects directly on startup — useful for CI but disorienting for team members.

### 4. Start dev server

```bash
npx expo start --dev-client
```

The server shows a QR code. Scanning it opens the installed dev client app (not Expo Go) and connects to your Metro bundler.

---

## EAS Build — Development Profile

```json
// eas.json
{
  "cli": { "version": ">= 5.0.0" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": true
      },
      "android": {
        "buildType": "apk"
      }
    },
    "development-device": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": false
      }
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {}
  }
}
```

Build commands:
```bash
# iOS simulator
eas build --profile development --platform ios

# Android device/emulator
eas build --profile development --platform android

# Both in parallel
eas build --profile development --platform all
```

After build completes, EAS provides a QR code to install. On simulator: EAS CLI can install automatically. On device: tap the install link.

---

## Prebuild Workflow

`expo prebuild` generates `android/` and `ios/` from your `app.config.js` and installed packages' config plugins. It is the only safe way to modify native directories in a managed workflow.

```bash
# Generate native dirs (idempotent)
npx expo prebuild

# Wipe and regenerate (use after major SDK upgrade or config plugin changes)
npx expo prebuild --clean

# Target one platform
npx expo prebuild --platform ios
npx expo prebuild --platform android
```

**Never hand-edit** `android/` or `ios/`. Changes made there are overwritten on the next `prebuild --clean`. Use config plugins for all native customization.

---

## Native Module Integration

When you add a package with a native module:

1. `npx expo install <package-name>` — installs and pins to SDK-compatible version
2. Check if the package includes a config plugin (documented in its README or in `app.plugin.js`)
3. Add config plugin to `app.config.js` if needed
4. Run `npx expo prebuild` to apply native changes
5. Rebuild the dev client: `eas build --profile development`
6. Reinstall on device/simulator

Steps 4–6 are only required when native code changes. Subsequent JS changes hot-reload without a rebuild.

---

## Config Plugin Authoring

Config plugins modify native project files during `expo prebuild`. Used when a package needs to modify `Info.plist`, `AndroidManifest.xml`, `build.gradle`, `Podfile`, etc.

### Simple plugin (inline in app.config.js)

```js
// app.config.js
const { withInfoPlist } = require('@expo/config-plugins');

export default ({ config }) => {
  config = withInfoPlist(config, (config) => {
    config.modResults.NSPhotoLibraryUsageDescription =
      'Used for profile photos';
    return config;
  });
  return config;
};
```

### Standalone plugin file

```js
// plugins/withCustomPermissions.js
const { withAndroidManifest } = require('@expo/config-plugins');

module.exports = function withCustomPermissions(config) {
  return withAndroidManifest(config, async (config) => {
    const manifest = config.modResults;
    // mutate manifest.manifest.['uses-permission'] etc.
    return config;
  });
};
```

```js
// app.config.js
export default {
  plugins: ['./plugins/withCustomPermissions']
};
```

Available modifiers: `withInfoPlist`, `withAndroidManifest`, `withAppBuildGradle`, `withProjectBuildGradle`, `withPodfileProperties`, `withXcodeProject`, and more from `@expo/config-plugins`.

---

## Debugging Tools

### React DevTools

```bash
npx react-devtools
```

Connect by shaking device → "Open JS Debugger", or press `j` in Metro terminal. Inspect component tree, props, hooks state, and profiler.

### Flipper

```bash
npx expo install react-native-flipper
```

Requires a rebuild. Useful plugins:
- **Network**: inspect all HTTP/S requests and responses
- **Layout**: visual component tree inspector
- **React DevTools**: embedded version
- **Databases**: browse SQLite and MMKV stores
- **Hermes Debugger**: JS breakpoints and memory profiling

For HTTPS inspection, configure SSL certificate in Flipper settings.

### Xcode (iOS)

- **Console**: `Window → Devices and Simulators` → select device → open console
- **Instruments**: Time Profiler, Allocations, Network for production-level profiling
- **Address Sanitizer**: catch memory issues in native modules
- **View Hierarchy Debugger**: inspect native view tree including RN bridge layers

### Android Studio (Android)

- **Logcat**: filter by `ReactNative` tag for JS bridge logs; filter by package for full app logs
- **CPU Profiler**: record traces to diagnose JS thread and UI thread contention
- **Memory Profiler**: heap dumps, allocation tracking, GC pressure analysis
- **Network Inspector**: works with `OkHttp` interceptor (add `com.squareup.okhttp3:logging-interceptor`)

### Network Proxying

Proxyman or Charles Proxy with SSL proxying enabled. Install the proxy's root certificate on device/simulator. Add `NSAppTransportSecurity` exception if needed in `Info.plist` via config plugin.

---

## Team Distribution

### Internal Distribution via EAS

```json
// eas.json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    }
  }
}
```

Team members install via EAS install link (iOS) or APK direct install (Android). They share the same dev client build and connect to any developer's Metro server by scanning the QR code at launch.

### iOS Device Builds (non-simulator)

Requires an Apple Developer account and device UDIDs registered.

```bash
eas device:create      # register device UDIDs
eas build --profile development-device --platform ios
```

EAS handles provisioning profiles automatically.

### Updating the Dev Client

Rebuild the dev client only when:
- A new native module is added
- An existing native module is updated with native changes
- A config plugin modifies native files
- Expo SDK version changes

JS and asset changes never require a rebuild — they update via Metro.

---

## Error Handling Patterns

### Native module not found at runtime

Symptom: `NativeModules.SomeName is undefined` or `Cannot read property X of null`.

Cause: package installed but dev client not rebuilt after `npx expo prebuild`.

Fix: run `npx expo prebuild` then rebuild dev client.

### Metro bundler connection refused

Symptom: dev client shows "Could not connect to development server".

Fix:
1. Verify Metro is running (`npx expo start --dev-client`)
2. Ensure device and dev machine are on the same network
3. On physical device, enter IP manually via the connection prompt
4. Check firewall rules for port 8081

### Build fails after adding native module

Check:
1. Run `npx expo install` instead of `npm install` — ensures SDK-compatible version
2. Check if package requires a config plugin and add it to `app.config.js`
3. Run `npx expo prebuild --clean` before rebuilding
4. Review EAS build logs for native compilation errors (Podfile issues, Gradle errors)

### Hermes engine errors

Expo uses Hermes by default. Some packages assume JSC (JavaScriptCore). Check package compatibility with Hermes. If unavoidable, disable Hermes:

```json
// app.json
{ "expo": { "jsEngine": "jsc" } }
```

---

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Editing `android/` or `ios/` by hand | Overwritten on next `prebuild --clean` | Use config plugins |
| `expo-dev-client` in `devDependencies` | Not bundled into native build — crash on launch | Move to `dependencies` |
| Skipping `expo install` for native packages | Version incompatibility with current SDK | Always use `npx expo install` |
| Rebuilding dev client for every JS change | Unnecessary — JS changes hot-reload | Rebuild only on native changes |
| Sharing simulator build for physical device testing | Simulator builds don't install on devices | Use `development-device` profile |
| Hardcoding localhost in API URLs for device testing | Device can't resolve localhost | Use machine's local IP or ngrok |
| Using Expo Go after adding native modules | Expo Go doesn't know about your native code — silent failures or crashes | Always use dev client builds when native modules are present |
