# expo-native-ui — Debugging Reference

## Common Debugging Scenarios

### Gesture handler not responding

**Symptom:** Tap, swipe, or pan gestures don't trigger callbacks. The component renders but is not interactive.
**Root cause:** Missing `GestureHandlerRootView` wrapper at the app root, gesture handler obscured by overlapping views, or z-index stacking issues.
**Diagnosis:**
- Verify `GestureHandlerRootView` wraps the entire app tree (must be at or near the root)
- Check for `pointerEvents="none"` or `pointerEvents="box-none"` on ancestor views that might block touches
- Inspect z-index: use React DevTools or add temporary `backgroundColor` to gesture areas to visualize overlap
- For `react-native-gesture-handler` v2+: ensure gestures are created with `Gesture.Tap()` etc., not the old `TapGestureHandler` component API (both work but mixing can cause issues)
- On Android: confirm `GestureHandlerRootView` is not nested inside a `ScrollView` that steals touches
- Check if `simultaneousHandlers` or `waitFor` refs are stale or pointing to unmounted handlers
**Fix pattern:** Wrap app root with `<GestureHandlerRootView style={{flex: 1}}>`. If z-index is the issue, restructure the view hierarchy or set explicit `zIndex` on the gesture target. For scroll conflicts, use `simultaneousHandlers` to coordinate gesture precedence.

### Animation frame drops

**Symptom:** Animations stutter, skip frames, or lag visibly. Gesture-driven animations feel unresponsive.
**Root cause:** Animation logic running on the JS thread instead of the UI thread, or expensive re-renders during animation.
**Diagnosis:**
- Open React Native Perf Monitor (shake > "Show Perf Monitor") and watch JS/UI thread FPS during the animation
- If JS FPS drops but UI stays at 60: the animation is on the UI thread but JS work is interfering — look for heavy renders
- If UI FPS drops: the animation itself is on the JS thread — needs migration to worklets
- Check for `Animated.Value` usage — standard Animated API runs on JS thread by default unless `useNativeDriver: true` is set
- For `react-native-reanimated`: verify callbacks use `'worklet'` directive and `useAnimatedStyle` instead of inline styles
- Profile with Flipper Performance plugin or Xcode Instruments (Time Profiler template)
**Fix pattern:** Move animations to `react-native-reanimated` worklets. Use `useAnimatedStyle` and `useSharedValue` — these run on the UI thread. Set `useNativeDriver: true` for standard Animated API (supports only `transform` and `opacity`). Reduce re-renders during animation with `React.memo` and stable references.

### Platform-specific rendering differences

**Symptom:** Component looks correct on iOS but broken on Android (or vice versa). Layout shifts, shadows missing, fonts different.
**Root cause:** Platform-specific default styles, shadow APIs, or font rendering behavior.
**Diagnosis:**
- Shadows: iOS uses `shadowColor/shadowOffset/shadowOpacity/shadowRadius`; Android uses `elevation`. Neither works on the other platform.
- Fonts: default system font differs (San Francisco on iOS, Roboto on Android). Custom fonts may have different metrics.
- Check `Platform.OS` conditional logic for typos or missing cases
- Use `Platform.select({ ios: {...}, android: {...} })` to isolate which platform-specific styles are applied
- Test on real devices, not just simulators — rendering differences are more pronounced on physical hardware
- Check for `overflow: 'hidden'` behavior — Android clips differently than iOS with border radius
**Fix pattern:** Use `Platform.select` for platform-divergent styles. For shadows, use a cross-platform shadow library (`react-native-shadow-2`) or apply both iOS shadow props and Android `elevation`. Test both platforms after every visual change. Use `StyleSheet.hairlineWidth` instead of hardcoded 1px borders.

### Safe area inset calculation wrong

**Symptom:** Content overlaps the notch, status bar, home indicator, or navigation bar. Padding looks correct on one device but wrong on another.
**Root cause:** Missing `SafeAreaProvider` at the app root, or using hardcoded padding instead of dynamic insets.
**Diagnosis:**
- Verify `SafeAreaProvider` wraps the entire app tree (from `react-native-safe-area-context`)
- Check that the consuming component uses `useSafeAreaInsets()` hook, not hardcoded values
- On iOS: test on devices with notch (iPhone 14+) AND without (iPhone SE) — insets differ significantly
- On Android: check if `StatusBar.translucent` is set — without it, the system adds its own padding and your inset calculation double-pads
- For navigation libraries (React Navigation): verify `SafeAreaProvider` is above the navigator — React Navigation provides its own, but only if the provider exists
- Check landscape orientation — insets change on rotation
**Fix pattern:** Wrap the app root with `<SafeAreaProvider>`. Use `useSafeAreaInsets()` in layout components and apply insets via `paddingTop: insets.top`, etc. For screens inside React Navigation, use `<SafeAreaView edges={['bottom']}>` to control which edges get insets (prevents double-padding from the navigator's header).

### Native component not rendering

**Symptom:** A native component (from a library or custom native module) renders as empty space or doesn't appear at all. No crash, just invisible.
**Root cause:** Component not registered with the native runtime, wrong import path, or zero-size layout.
**Diagnosis:**
- Check the component has explicit `width` and `height` or `flex: 1` — React Native doesn't have intrinsic sizing for most native views
- Add a temporary `backgroundColor: 'red'` to the component's style to see if it has layout dimensions
- Verify the import: `requireNativeComponent('ComponentName')` must match the exact string registered on the native side
- For Expo Modules: check `expo-module.config.json` for the `ios.modules` and `android.modules` entries
- Run `npx expo prebuild --clean` to ensure native code is up to date
- Check the native registration code: iOS `RCT_EXPORT_MODULE()` macro or Android `@ReactModule` annotation
**Fix pattern:** Give the component explicit dimensions. If the component isn't registered, rebuild native projects with `npx expo prebuild --clean`. For custom native modules, verify the registration string matches exactly between JS `requireNativeComponent()` and native `RCT_EXPORT_MODULE()` / `@ReactModule`.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| React DevTools | Inspect component tree, props, and styles | `npx react-devtools` |
| Perf Monitor | Watch JS/UI thread FPS in real time | Shake > "Show Perf Monitor" |
| Flipper | Layout inspector, network, performance profiling | Open Flipper desktop app with device connected |
| Xcode Instruments | iOS-specific profiling (Time Profiler, Core Animation) | Xcode > Product > Profile |
| Android Studio Profiler | Android CPU, memory, rendering profiling | Android Studio > View > Tool Windows > Profiler |
| Layout Inspector | Visualize Android view hierarchy | Android Studio > Layout Inspector |
| Reanimated logger | Trace worklet execution | `import { LogLevel, logger } from 'react-native-reanimated'; logger.setLevel(LogLevel.verbose)` |
| Platform check | Verify platform-specific code paths | `console.log(Platform.OS, Platform.Version)` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
