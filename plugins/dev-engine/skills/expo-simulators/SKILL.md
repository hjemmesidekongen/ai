---
name: expo-simulators
description: >
  iOS Simulator and Android Emulator management — setup, screenshots, recording,
  and debugging tools.
user_invocable: false
interactive: false
model_tier: senior
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
  iteration: 1
---

# expo-simulators

iOS Simulator (`xcrun simctl`) and Android Emulator (`avdmanager` + `emulator`) are the primary tools for local Expo testing without physical devices.

## iOS Simulator

```bash
xcrun simctl list devices                          # list all simulators
xcrun simctl boot "iPhone 16 Pro"                  # boot a simulator
open -a Simulator                                  # open the Simulator window
xcrun simctl install booted ./build/YourApp.app   # install a build
xcrun simctl launch booted com.your.bundleid       # launch the app
```

## Android Emulator

```bash
avdmanager list avd                                                              # list AVDs
avdmanager create avd -n Pixel_9_API_35 -k "system-images;android-35;google_apis_playstore;x86_64"
emulator -avd Pixel_9_API_35                      # start emulator (warm boot)
emulator -avd Pixel_9_API_35 -no-snapshot-load    # cold boot (fresh state)
```

## Expo Integration

```bash
npx expo start --ios                              # launch on booted iOS simulator
npx expo start --android                          # launch on running Android emulator
npx expo start --ios --device "iPhone 16 Pro"     # target specific simulator
```

Expo picks the booted simulator automatically when only one is running. Multiple running simultaneously causes routing confusion unless intentional.

## Key Rules

- Clear Metro cache (`expo start --clear`) when switching platforms or after major dependency changes.
- Use `xcrun simctl erase` to reset simulator state — faster than creating a new simulator.
- Android emulators with Google Play Store have restricted root access. Use AOSP images when elevated permissions are needed.
- Never run two simulators of the same platform simultaneously unless explicitly testing multi-device scenarios.
See `references/process.md` for screenshots, screen recording, location simulation, push notification testing, network conditions, performance profiling, multi-device testing, reset procedures, and anti-patterns.
