---
name: expo-simulators
description: >
  iOS Simulator and Android Emulator management — setup, screenshots, recording,
  and debugging tools.
user_invocable: false
interactive: false
model_tier: junior
depends_on: []
triggers:
  - "expo simulators"
  - "ios simulator"
  - "android emulator"
  - "expo device testing"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "simulator_booted"
      verify: "Target simulator/emulator is in Running state before launching the app"
      fail_action: "Boot explicitly — xcrun simctl boot or emulator -avd before expo start"
    - name: "correct_sdk_version"
      verify: "Simulator OS version matches the minimum deployment target in app.json"
      fail_action: "Create or select a simulator with the correct iOS/Android version"
    - name: "no_stale_metro_cache"
      verify: "Metro cache cleared when switching between simulators with different architectures"
      fail_action: "Run expo start --clear before switching device type"
    - name: "screenshots_captured_for_qa"
      verify: "Visual QA screenshots taken on both iOS and Android before marking feature complete"
      fail_action: "Run simctl io screenshot and adb exec-out screencap to capture current state"
  on_fail: "Simulator setup has issues that will block reliable testing — fix before running the app"
  on_pass: "Simulator environment is ready"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced basic CLI commands with CI management, profiling, and platform-specific gotchas"
---

# expo-simulators

Beyond standard CLI commands — CI integration, platform gotchas, profiling, and device limitations.

## CI Simulator Management

**GitHub Actions + iOS**: `macos-14`+ runners (Apple Silicon), simulators pre-installed. Boot with `xcrun simctl boot` in setup step. Headless mode works without Simulator.app.

**GitHub Actions + Android**: Use `reactivecircus/android-emulator-runner`. Enable KVM (`/dev/kvm`), API 31+ `google_apis` target, `emulator-options: -no-window -no-audio -no-boot-anim`. Cache AVD snapshots with `actions/cache`.

**Parallel testing**: iOS and Android in separate matrix jobs — iOS on macOS, Android on Ubuntu (KVM). Saves 5-10 min per run.

## Apple Silicon vs Intel (Android)

M-series Macs require ARM64 images (`google_apis;arm64-v8a`). x86_64 images launch but crash or run at 10% speed. Check: `sdkmanager --list | grep arm64-v8a`. Native ARM emulation — no translation layer.

## Performance Profiling

**iOS Instruments**: Time Profiler, Allocations, Core Animation (frame rate). Attach to simulator process — no signing needed.

**Android Profiler**: CPU/Memory/Network/Energy tabs in Android Studio. For RN: `--profile-hermes`, open `.cpuprofile` in Chrome DevTools.

**Expo**: `npx expo start --dev-client` + shake > Performance Monitor shows JS and UI thread FPS separately.

## Simulator vs Device Limitations

**Not available**: Real push notifications (iOS supports `.apns` drag-and-drop simulation only), camera, NFC, Bluetooth, barometric sensor, accurate GPS (use simulated locations), real perf characteristics.

**Behaves differently**: Biometrics work via Simulator Features menu / `adb -e emu finger touch 1`. Deep links via `xcrun simctl openurl` / `adb shell am start -d`.

## Expo-Specific Gotchas

**EAS local build**: `eas build --local --platform ios --profile development` — simulator-compatible, requires Xcode CLI tools.

**Config plugins**: Changes only apply after `npx expo prebuild`. Native code changes require rebuild — hot reload won't reflect them.

**Port conflicts**: Two dev clients on same simulator need different ports. Use `--port` on second instance.

See `references/process.md` for screen recording, network simulation, multi-device testing, and reset procedures.
