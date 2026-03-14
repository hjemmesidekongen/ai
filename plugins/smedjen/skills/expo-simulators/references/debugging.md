# expo-simulators — Debugging Reference

## Common Debugging Scenarios

### iOS Simulator not booting

**Symptom:** `xcrun simctl boot` hangs, times out, or returns "Unable to boot device in current state." Expo shows "No booted simulators found."
**Root cause:** No compatible simulator runtime installed, device in an invalid state, or macOS resource exhaustion.
**Diagnosis:**
- List all available devices and their states: `xcrun simctl list devices`
- List installed runtimes: `xcrun simctl list runtimes` — if the target runtime is missing, it needs to be downloaded
- Check if a device is stuck in "Booting" state: `xcrun simctl list devices | grep Booting`
- If stuck, force shutdown: `xcrun simctl shutdown <device-udid>` then retry boot
- Check disk space — simulators need several GB of free space to boot
- Check if Xcode command line tools are set: `xcode-select -p` — should point to Xcode.app, not CommandLineTools
- Verify Xcode license accepted: `sudo xcodebuild -license accept`
**Fix pattern:** If no runtime is installed: open Xcode > Settings > Platforms > download the iOS runtime. If a device is stuck, erase it: `xcrun simctl erase <device-udid>`. If all simulators are broken, delete and recreate: `xcrun simctl delete all` then reopen Xcode (it recreates defaults). For Expo specifically: `npx expo run:ios --device` to pick from available simulators.

### Android Emulator hardware acceleration

**Symptom:** Emulator is extremely slow (1-2 FPS), shows "HAXM is not installed" warning, or fails to launch with a virtualization error.
**Root cause:** Hardware acceleration not enabled or not available. Intel machines need HAXM; AMD machines need Hyper-V or AEHD; Apple Silicon uses HVF natively.
**Diagnosis:**
- macOS (Apple Silicon): acceleration is built in via Hypervisor.framework — if emulator is slow, check you're using an `arm64` system image, not `x86_64`
- macOS (Intel): check HAXM: `kextstat | grep intel` — look for `com.intel.kext.intelhaxm`
- Linux: check KVM: `ls /dev/kvm` — if missing, enable in BIOS or install `qemu-kvm`
- Windows: check Hyper-V or WHPX: `systeminfo | findstr "Hyper-V"`
- Check emulator is using the right ABI: `emulator -list-avds` then check the AVD's `abi.type` in `~/.android/avd/<name>.avd/config.ini`
- Run emulator with diagnostics: `emulator -avd <name> -verbose 2>&1 | grep -i accel`
**Fix pattern:** On Apple Silicon: use `arm64-v8a` system images (Google APIs ARM 64). On Intel Mac: install HAXM from Android Studio > SDK Manager > SDK Tools. On Linux: `sudo apt install qemu-kvm && sudo adduser $USER kvm`. Verify with `emulator -accel-check`.

### Screenshots not capturing

**Symptom:** Screenshot commands return empty files, black images, or error out. Visual verification scripts fail.
**Root cause:** Simulator/emulator window not in focus, app not fully rendered, or wrong capture command.
**Diagnosis:**
- iOS Simulator: `xcrun simctl io booted screenshot /tmp/test.png` — check the booted device UDID if multiple sims are running
- If multiple simulators are booted, specify UDID: `xcrun simctl io <udid> screenshot /tmp/test.png`
- Android Emulator: `adb exec-out screencap -p > /tmp/test.png` — check `adb devices` shows the emulator
- For headless/CI environments: iOS simulators render without a visible window, but the GPU must be available
- Check if the screenshot is just a black image: the app may not have finished rendering — add a delay or wait for a specific element
- Verify file size: a valid screenshot should be >10KB; if it's 0 bytes, the command failed silently
**Fix pattern:** For iOS, use `xcrun simctl io booted screenshot <path>` — it works regardless of window focus. For Android, use `adb exec-out screencap -p > <path>`. In CI, ensure the simulator is fully booted before capturing: wait for `xcrun simctl bootstatus <udid>` to return. Add a 2-3 second delay after navigation before capturing.

### Emulator networking issues

**Symptom:** App can't reach the local dev server, API calls to localhost fail, or the emulator has no internet connectivity.
**Root cause:** Emulator network stack uses a virtual NAT; `localhost` inside the emulator refers to the emulator itself, not the host machine.
**Diagnosis:**
- Android: the host machine's localhost is at `10.0.2.2` from the emulator's perspective
- iOS Simulator: shares the host machine's network stack — `localhost` works directly
- Test connectivity from Android emulator: `adb shell ping 10.0.2.2`
- For Metro specifically: set up reverse port forwarding: `adb reverse tcp:8081 tcp:8081`
- Check if corporate VPN interferes: some VPNs route all traffic and break emulator NAT
- For API servers on non-standard ports: each port needs its own `adb reverse` rule
- Check DNS resolution: `adb shell nslookup google.com`
**Fix pattern:** For Android Metro connection: `adb reverse tcp:8081 tcp:8081`. For API servers: `adb reverse tcp:<api-port> tcp:<api-port>`. For iOS Simulator, no special config needed — it uses host networking. If VPN interferes, add emulator subnet to VPN split-tunnel exclusions, or use `--host tunnel` with Expo.

### Hot reload not connecting

**Symptom:** Code changes don't appear in the app running on the simulator/emulator. Metro terminal shows no activity when files are saved.
**Root cause:** Metro WebSocket connection broken, wrong port, or emulator can't reach the Metro server.
**Diagnosis:**
- Check Metro is running and on which port: look at the terminal output for `Metro waiting on exp://...`
- Verify the port: default is 8081, but it auto-increments if the port is taken
- Android: set up port forwarding for the correct port: `adb reverse tcp:<port> tcp:<port>`
- iOS Simulator: check if another process is on port 8081: `lsof -i :8081`
- Check if the app is pointing to the correct bundler URL: shake > "Configure Bundler" (or check the dev menu)
- Look for Metro WebSocket errors in the device logs: `adb logcat | grep -i websocket` or Xcode console
- If Metro was restarted, the app needs a manual reload (`Cmd+R` on iOS sim, `R` twice on Android)
**Fix pattern:** Kill any process on the Metro port: `kill $(lsof -t -i :8081)`. Restart Metro with cache clear: `npx expo start -c`. For Android, ensure port forwarding is active: `adb reverse tcp:8081 tcp:8081`. If the app is stale, force reload from dev menu or reinstall the dev client.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| simctl list | View all iOS simulators and their states | `xcrun simctl list devices` |
| simctl boot status | Wait for simulator to fully boot | `xcrun simctl bootstatus <udid>` |
| simctl screenshot | Capture iOS simulator screen | `xcrun simctl io booted screenshot <path>` |
| simctl log | Stream iOS simulator logs | `xcrun simctl spawn booted log stream --level debug` |
| adb devices | List connected Android emulators/devices | `adb devices -l` |
| adb reverse | Forward port from emulator to host | `adb reverse tcp:<port> tcp:<port>` |
| adb screencap | Capture Android emulator screen | `adb exec-out screencap -p > <path>` |
| adb logcat | Stream Android logs with filters | `adb logcat -s ReactNative:V ReactNativeJS:V` |
| emulator accel-check | Verify hardware acceleration status | `emulator -accel-check` |
| AVD manager | Create/edit Android virtual devices | Android Studio > Device Manager |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
