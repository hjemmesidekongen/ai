---
name: expo-native-ui
description: >
  Native UI patterns in Expo — platform-specific components, gestures,
  animations, and design system integration.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo native ui"
  - "react native ui"
  - "expo components"
  - "native design"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "platform_parity"
      verify: "Platform-specific behavior is tested on both iOS and Android before marking done"
      fail_action: "Add Platform.select or .ios/.android file split where behavior diverges"
    - name: "safe_area_respected"
      verify: "All screens wrap content in SafeAreaView or use useSafeAreaInsets where appropriate"
      fail_action: "Add SafeAreaView — missing it causes content clipping under notch/home indicator"
    - name: "no_inline_styles_for_layout"
      verify: "Layout and theme values use StyleSheet.create or design tokens, not ad-hoc inline objects"
      fail_action: "Extract to StyleSheet — inline objects create new references on every render"
    - name: "list_renderer_justified"
      verify: "FlashList is used for long scrollable lists; FlatList only for short or simple cases"
      fail_action: "Replace FlatList with FlashList if list length is unbounded or has performance issues"
  on_fail: "Native UI has structural issues — fix before shipping"
  on_pass: "Native UI patterns are sound"
_source:
  origin: "dev-engine"
  inspired_by: "expo-skills-main"
  ported_date: "2026-03-10"
  iteration: 1
---

# expo-native-ui

Native UI in Expo is React Native with a curated layer on top. No DOM, no CSS — layout is Yoga flexbox and platform behavior diverges in ways that matter.

## Platform Specificity

`Platform.select` for inline divergence. `.ios.tsx` / `.android.tsx` file extensions when implementations differ substantially — don't bury large platform branches in a single file.

## Safe Area

Always use `SafeAreaView` from `react-native-safe-area-context` (not core RN). For programmatic insets use `useSafeAreaInsets`. Never hardcode top/bottom padding to compensate for notches.

## Navigation

expo-router uses file-based routing on top of React Navigation. Screens live in `app/`. Layouts in `_layout.tsx`. Use `useRouter` and `useLocalSearchParams` — avoid direct React Navigation APIs unless expo-router doesn't expose what you need.

## Gestures

`react-native-gesture-handler` for all touch interactions beyond `TouchableOpacity`. Wrap the app root in `GestureHandlerRootView`. Compose conflicting gestures with `Gesture.Simultaneous` / `Gesture.Exclusive`.

## Animations

**Reanimated** for smooth 60fps animations on the UI thread — `useSharedValue`, `useAnimatedStyle`, `withSpring` / `withTiming`. Avoid JS-driven animations for anything continuous. **LayoutAnimation** works for simple one-off transitions; Reanimated's `Layout` prop is better.

## Styling

`StyleSheet.create` is not optional — it registers styles natively and avoids object allocation on re-renders. Use `useWindowDimensions` (not `Dimensions.get`) for responsive sizing — it's reactive to orientation changes.

## Design Tokens, Icons, Images

Keep a `tokens.ts` exporting spacing, color, typography, radius. No CSS variables in RN — import directly. Use `expo-vector-icons` for icons and `expo-image` over core `Image` — better caching, blurhash placeholder support.

## Lists

FlashList (`@shopify/flash-list`) over FlatList for any unbounded or large list. Set `estimatedItemSize` accurately — wrong estimates degrade performance.

## Modals and Bottom Sheets

`@gorhom/bottom-sheet` over `Modal` for bottom sheets — integrates with gesture handler and Reanimated. `Modal` is fine for simple confirmations. Always wrap form modals in `KeyboardAvoidingView`.

See `references/process.md` for platform split patterns, navigation setup, gesture composition, animation recipes, list configuration, and anti-patterns.