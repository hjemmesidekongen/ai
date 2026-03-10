# expo-simulators — Process Reference

## iOS Simulator (xcrun simctl)

### Listing and Selecting Devices

```bash
# List all devices (all runtimes)
xcrun simctl list devices

# List only booted devices
xcrun simctl list devices | grep Booted

# List available runtimes
xcrun simctl list runtimes
```

### Booting and Shutdown

```bash
# Boot by name
xcrun simctl boot "iPhone 16 Pro"

# Boot by UDID
xcrun simctl boot A1B2C3D4-E5F6-7890-ABCD-EF1234567890

# Open the Simulator UI (required to see the device)
open -a Simulator

# Shutdown a specific device
xcrun simctl shutdown "iPhone 16 Pro"

# Shutdown all booted devices
xcrun simctl shutdown all
```

### Installing and Launching Apps

```bash
# Install a .app bundle (debug build from Xcode or EAS)
xcrun simctl install booted ./build/YourApp.app

# Launch the app by bundle identifier
xcrun simctl launch booted com.yourcompany.yourapp

# Uninstall
xcrun simctl uninstall booted com.yourcompany.yourapp
```

### Screenshots and Screen Recording

```bash
# Screenshot (PNG)
xcrun simctl io booted screenshot ~/Desktop/screenshot.png

# Screen recording (MOV)
xcrun simctl io booted recordVideo ~/Desktop/recording.mov
# Press Ctrl+C to stop recording

# Screenshot with device type override
xcrun simctl io "iPhone 16 Pro" screenshot --type png ~/Desktop/iphone-16-pro.png
```

### Location Simulation

```bash
# Set a fixed GPS location (lat, lon)
xcrun simctl location booted set 37.7749 -122.4194

# Clear simulated location
xcrun simctl location booted clear

# GPX route playback
xcrun simctl location booted gpx-simulate ~/route.gpx
```

### Push Notification Testing

```bash
# Send a test push notification (iOS 13+)
xcrun simctl push booted com.yourcompany.yourapp notification.json
```

`notification.json` format:

```json
{
  "aps": {
    "alert": {
      "title": "Test Notification",
      "body": "This is a test push"
    },
    "badge": 1,
    "sound": "default"
  }
}
```

### Reset and Cleanup

```bash
# Erase all content and settings (equivalent to factory reset)
xcrun simctl erase booted

# Erase by name
xcrun simctl erase "iPhone 16 Pro"

# Delete a simulator entirely
xcrun simctl delete "iPhone 16 Pro"

# Delete all unavailable simulators (frees disk space)
xcrun simctl delete unavailable
```

---

## Android Emulator

### Creating AVDs

```bash
# List available system images
sdkmanager --list | grep "system-images"

# Install a system image
sdkmanager "system-images;android-35;google_apis_playstore;x86_64"

# Create AVD
avdmanager create avd \
  -n Pixel_9_API_35 \
  -k "system-images;android-35;google_apis_playstore;x86_64" \
  -d "pixel_9"

# List existing AVDs
avdmanager list avd

# Delete an AVD
avdmanager delete avd -n Pixel_9_API_35
```

### Starting the Emulator

```bash
# Normal start (warm boot from snapshot)
emulator -avd Pixel_9_API_35

# Cold boot (ignores saved snapshot)
emulator -avd Pixel_9_API_35 -no-snapshot-load

# Headless (for CI — no window)
emulator -avd Pixel_9_API_35 -no-window -no-audio -no-boot-anim

# Wait for emulator to be ready (use in scripts)
adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done'
```

### Screenshots and Screen Recording

```bash
# Screenshot via adb
adb exec-out screencap -p > ~/Desktop/screenshot.png

# Screen recording (up to 3 min by default)
adb shell screenrecord /sdcard/recording.mp4
# Then pull the file:
adb pull /sdcard/recording.mp4 ~/Desktop/recording.mp4

# Stop recording
adb shell pkill -SIGINT screenrecord
```

### Network Conditions

The Android emulator supports network throttling through the emulator console:

```bash
# Connect to emulator console
telnet localhost 5554

# Simulate slow 3G
network speed gsm
network delay gprs

# Simulate no network
network speed 0 0

# Restore full speed
network speed full
network delay none
```

Or set at startup:

```bash
emulator -avd Pixel_9_API_35 -netspeed gsm -netdelay gprs
```

---

## Expo-Specific Tools

### expo start Flags

```bash
# Launch on iOS simulator
npx expo start --ios

# Launch on Android emulator
npx expo start --android

# Target a specific device by name
npx expo start --ios --device "iPhone 16 Pro"

# Clear Metro bundler cache on start
npx expo start --clear

# Start in tunnel mode (for testing on physical device over network)
npx expo start --tunnel
```

### Selecting Between Multiple Running Simulators

When multiple simulators are running, `expo start` prompts for selection. To avoid the prompt, boot only the target simulator before running `expo start`, or use `--device` to specify by name.

---

## Debugging on Simulators

### React Native Debugger

```bash
# Open in-app developer menu
# iOS: Cmd+D (in Simulator window)
# Android: Cmd+M (in Simulator window)
```

From the dev menu: enable "Debug JS Remotely" for Chrome DevTools, or use Expo DevTools in the browser.

### Flipper

Flipper connects to simulators over a local socket. For Expo managed workflow, Flipper requires a development build (not Expo Go). Add the `react-native-flipper` package and configure in `app.config.js`.

### React Native Logs

```bash
# Stream device logs — iOS
xcrun simctl spawn booted log stream --predicate 'process == "YourApp"'

# Stream device logs — Android
adb logcat -s ReactNativeJS:V
```

---

## Performance Profiling

### iOS

Use Xcode Instruments from Simulator:
- `Product → Profile` in Xcode runs Instruments on the simulator build.
- Time Profiler: CPU usage per function.
- Allocations: memory allocation trace.
- Core Animation: frame rate and layer compositing.

From the React Native dev menu: "Perf Monitor" shows FPS and JS thread load in the app.

### Android

```bash
# Systrace for Android performance tracing
python $ANDROID_HOME/platform-tools/systrace/systrace.py --time=10 -o trace.html sched gfx view

# Open in Chrome: chrome://tracing
```

GPU overdraw: enable in emulator `Settings → Developer options → Debug GPU overdraw`.

---

## Multi-Device Testing

For testing responsive layouts across screen sizes, run multiple simulators sequentially (not simultaneously unless testing sync scenarios):

```bash
# Test on iPhone SE (small screen)
xcrun simctl boot "iPhone SE (3rd generation)"
npx expo start --ios --device "iPhone SE (3rd generation)"

# Then test on iPad
xcrun simctl boot "iPad Pro 13-inch (M4)"
npx expo start --ios --device "iPad Pro 13-inch (M4)"
```

For Android, maintain AVDs at different screen densities:
- `Pixel_9_API_35` (420dpi, standard)
- `Nexus_7_API_35` (320dpi, tablet)
- `Pixel_Fold_API_35` (foldable)

---

## Reset and Cleanup

### iOS

```bash
# Erase one simulator
xcrun simctl erase "iPhone 16 Pro"

# Erase all simulators (nuclear option)
xcrun simctl erase all

# Delete unavailable simulators (old Xcode runtimes)
xcrun simctl delete unavailable

# Clear derived data (rebuilds from scratch)
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Android

```bash
# Wipe emulator data (cold state)
emulator -avd Pixel_9_API_35 -wipe-data

# Clear app data only
adb shell pm clear com.yourcompany.yourapp

# Delete AVD files
rm -rf ~/.android/avd/Pixel_9_API_35.avd
rm ~/.android/avd/Pixel_9_API_35.ini
```

---

## Anti-Patterns

**Running multiple simulators of the same platform** — Metro serves one instance. Two iOS simulators running at once means only one gets the bundle correctly unless you're using separate Metro instances intentionally.

**Never clearing Metro cache between architecture switches** — when switching between iOS Simulator and Android Emulator, stale transforms cause cryptic runtime errors. Always `expo start --clear` after switching.

**Testing on simulator only, never physical device** — simulators don't replicate camera, NFC, Bluetooth, GPS accuracy, or real-world network conditions. Any feature using these APIs needs physical device testing before ship.

**Using Google Play Store AVD for low-level testing** — Play Store images restrict root access and prevent adb from modifying certain system paths. Use AOSP images (`google_apis` instead of `google_apis_playstore`) when you need unrestricted access.

**Leaving simulators running between sessions** — booted simulators consume RAM and CPU even when idle. Shut down after each session: `xcrun simctl shutdown all` and close the emulator.

**Not testing on minimum supported OS version** — always test on both the latest OS and the minimum deployment target. UI behavior, APIs, and gesture recognizers differ across iOS versions.

**Relying on simulator for performance benchmarks** — simulators run on your Mac's CPU, not mobile ARM chips. Frame rate and memory behavior on simulators is not representative of real device performance.
