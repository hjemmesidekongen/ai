# expo-dev-client — Debugging Reference

## Common Debugging Scenarios

### Dev client crashes on launch

**Symptom:** The development build installs but immediately crashes or shows a white screen before the JS bundle loads.
**Root cause:** Native module initialization failure, incompatible native dependency, or corrupted build artifacts.
**Diagnosis:**
- iOS: open Xcode, run the app from there, and check the console for the crash stack trace. Alternatively: `xcrun simctl launch --console booted <bundle-id>`
- Android: run `adb logcat -s ReactNative:V ReactNativeJS:V AndroidRuntime:E` to capture the native crash log
- Check if the crash happens before or after "Running application" log line — before means native init failure, after means JS error
- Review recently added native packages — check their minimum SDK/iOS version requirements
- Try a clean build: `npx expo prebuild --clean && npx expo run:ios` (or `run:android`)
**Fix pattern:** Identify the failing native module from the crash log. Check version compatibility. If a package requires a higher minimum deployment target, update `app.json` `ios.deploymentTarget` or `android.minSdkVersion`. Clean rebuild.

### Native module not found

**Symptom:** Runtime error: `Invariant Violation: TurboModuleRegistry.getEnforcing(...): '<ModuleName>' could not be found` or `requireNativeComponent: '<ComponentName>' was not found`.
**Root cause:** The native module isn't linked — autolinking missed it, or the prebuild output is stale.
**Diagnosis:**
- Check if the package supports Expo autolinking: look for `expo-module.config.json` in the package directory under `node_modules/`
- For non-Expo packages, check for `react-native.config.js` in the package root
- Run `npx expo-doctor` to check for known incompatibilities
- Inspect the generated native project: `ios/Podfile` for iOS, `android/app/build.gradle` for Android
- Run `npx expo prebuild --clean` to regenerate native projects from scratch
- For iOS specifically: `cd ios && pod install --verbose` to see if the pod was found and linked
**Fix pattern:** Run `npx expo prebuild --clean` to regenerate native projects. If the package doesn't support autolinking, create a config plugin to add the native dependency manually. For community packages, check if an Expo-compatible fork exists.

### Metro bundler connection failures

**Symptom:** Dev client shows "Unable to connect to development server" or spins indefinitely on the loading screen.
**Root cause:** Network configuration preventing the device from reaching Metro, wrong host/port, or Metro not running.
**Diagnosis:**
- Confirm Metro is running: `lsof -i :8081` (default port)
- On physical device: ensure device and dev machine are on the same Wi-Fi network
- Check the dev server URL shown in the terminal — verify the IP is reachable from the device
- For Android emulator: the host machine is at `10.0.2.2`, not `localhost`
- Check if `EXPO_PACKAGER_PROXY_URL` or `REACT_NATIVE_PACKAGER_HOSTNAME` env vars are set and correct
- Try explicit host: `npx expo start --host lan` or `--host tunnel`
- Check firewall rules: `sudo lsof -i -P | grep LISTEN | grep 8081`
**Fix pattern:** Set `REACT_NATIVE_PACKAGER_HOSTNAME` to your machine's LAN IP. For corporate networks with client isolation, use `--host tunnel` (requires `@expo/ngrok`). If port 8081 is taken, use `--port <other>`.

### Hot reload not working in dev client

**Symptom:** Code changes don't appear in the app; requires manual reload or rebuild.
**Root cause:** Stale Metro cache, Fast Refresh disabled, or the module tree has a non-refreshable boundary.
**Diagnosis:**
- Check the Metro terminal for "Fast Refresh" messages when saving a file
- Look for the "Fast Refresh had to perform a full reload" warning — indicates a module that can't be hot-swapped (e.g., root-level side effects)
- Verify Fast Refresh is enabled: shake device > "Enable Fast Refresh" (or `Cmd+D` on iOS sim)
- Check if `.env` changes are involved — those require a full restart
- Inspect for `module.exports =` patterns — CommonJS exports break Fast Refresh
**Fix pattern:** Clear Metro cache with `npx expo start -c`. Convert CommonJS modules to ES module exports. Move side effects out of module scope into `useEffect`. If a specific file consistently breaks refresh, check for non-idempotent top-level code.

### Pod install failures on iOS

**Symptom:** `pod install` fails with dependency resolution errors, version conflicts, or download timeouts.
**Root cause:** Stale CocoaPods cache, version conflicts between pods, or outdated repo index.
**Diagnosis:**
- Read the full error: pod resolution errors specify which pods conflict and what versions are requested
- Run `pod repo update` to refresh the local spec repo
- Check `ios/Podfile.lock` for the conflicting pod versions
- Run `pod install --verbose` to see exactly where it fails (download, resolve, or integrate phase)
- For `CDN: trunk` errors: check network connectivity to `cdn.cocoapods.org`
- For minimum deployment target errors: check each pod's required iOS version vs. your project's target
**Fix pattern:** Delete `ios/Podfile.lock` and `ios/Pods/`, then run `npx expo prebuild --clean` to regenerate. If specific pods conflict, check if newer versions resolve it: `pod outdated`. For persistent issues, clear the CocoaPods cache: `pod cache clean --all`.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Xcode console | iOS native crash logs | Run app from Xcode > Debug navigator |
| adb logcat | Android native crash logs | `adb logcat -s ReactNative:V ReactNativeJS:V AndroidRuntime:E` |
| Metro terminal | JS bundle errors, Fast Refresh status | `npx expo start` (watch terminal output) |
| Expo Doctor | Dependency compatibility check | `npx expo-doctor` |
| Clean prebuild | Regenerate native projects | `npx expo prebuild --clean` |
| Pod verbose | iOS dependency resolution details | `cd ios && pod install --verbose` |
| Port check | Verify Metro is listening | `lsof -i :8081` |
| Config dump | Inspect final app config | `npx expo config --type introspect` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
