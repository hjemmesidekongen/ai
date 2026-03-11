# expo-tailwind — Process Reference

Full reference for NativeWind v4 setup, Tailwind config for RN, styling patterns, responsive design, dark mode, CSS variables, Expo Router integration, web compatibility, StyleSheet migration, performance, limitations vs web Tailwind, and anti-patterns.

---

## NativeWind v4 — Full Setup

### Install

```bash
npx expo install nativewind tailwindcss
npx tailwindcss init
```

### tailwind.config.js

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,jsx,ts,tsx}',
    './components/**/*.{js,jsx,ts,tsx}',
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {},
  },
};
```

The `nativewind/preset` configures Tailwind to understand RN's style constraints — required.

### babel.config.js

```js
module.exports = {
  presets: ['babel-preset-expo'],
  plugins: ['nativewind/babel'],
};
```

The Babel plugin transforms `className` props to NativeWind's `useColorScheme` / StyleSheet calls at build time.

### global.css

```css
@import "tailwindcss";
```

### Root layout

```tsx
// app/_layout.tsx
import '../global.css';

export default function RootLayout({ children }) {
  return <>{children}</>;
}
```

### TypeScript support

```ts
// nativewind-env.d.ts (create in project root)
/// <reference types="nativewind/types" />
```

This adds `className` to the type definitions of all React Native core components.

---

## className Prop Usage

Works on all React Native core components: `View`, `Text`, `TextInput`, `Image`, `TouchableOpacity`, `Pressable`, `ScrollView`, `FlatList`, etc.

```tsx
// Layout
<View className="flex-1 flex-row items-center justify-between px-4 py-3 bg-gray-50" />

// Typography
<Text className="text-2xl font-bold tracking-tight text-gray-900" />
<Text className="text-sm text-gray-500 leading-relaxed" />

// Interactive
<Pressable className="rounded-lg bg-brand px-4 py-3 active:opacity-75">
  <Text className="text-white font-semibold text-center">Submit</Text>
</Pressable>

// Image
<Image className="w-16 h-16 rounded-full" source={{ uri }} />
```

---

## Responsive Design in React Native

NativeWind supports Tailwind's breakpoint prefixes (`sm:`, `md:`, `lg:`, `xl:`, `2xl:`). In RN context they respond to the device's screen width, not a browser viewport.

```tsx
<View className="flex-col md:flex-row">
  <Text className="text-base lg:text-lg" />
</View>
```

For layout decisions based on device category, combine with `useWindowDimensions`:

```tsx
import { useWindowDimensions } from 'react-native';

export function ResponsiveCard() {
  const { width } = useWindowDimensions();
  return (
    <View className={`p-4 ${width >= 768 ? 'flex-row' : 'flex-col'}`}>
```

Or use platform variants — more readable than dynamic className:

```tsx
<View className="flex-col ios:p-4 android:p-3" />
```

---

## Dark Mode

### System-driven (media)

```js
// tailwind.config.js
module.exports = { darkMode: 'media', ... }
```

Responds to the device's dark mode setting automatically. No JS needed.

```tsx
<View className="bg-white dark:bg-gray-900">
  <Text className="text-gray-900 dark:text-gray-100">Content</Text>
</View>
```

### Manual toggle (class)

```js
// tailwind.config.js
module.exports = { darkMode: 'class', ... }
```

```tsx
import { useColorScheme } from 'nativewind';

export function ThemeProvider({ children }) {
  return (
    <View className={colorScheme === 'dark' ? 'dark' : ''}>
      {children}
    </View>
  );
}
```

Pick one strategy per project. Mixing causes non-deterministic behavior when OS preference and manual toggle diverge.

---

## Theme Customization

```js
// tailwind.config.js
module.exports = {
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#6366F1',
          dark: '#4F46E5',
          light: '#818CF8',
        },
        surface: '#F9FAFB',
      },
      fontFamily: {
        sans: ['Inter_400Regular'],
        bold: ['Inter_700Bold'],
        display: ['CalSans_600SemiBold'],
      },
      spacing: {
        18: '4.5rem',
        22: '5.5rem',
      },
      borderRadius: {
        card: '12px',
        pill: '9999px',
      },
    },
  },
};
```

Font family names must exactly match the string passed to `useFonts` from `expo-font`. Using `Inter_400Regular` as a class: `className="font-sans"`.

---

## CSS Variables in RN Context

NativeWind v4 supports CSS custom properties in a limited capacity. CSS variables work in the CSS layer but do not translate to RN's inline style system directly.

Approach: define design tokens in `tailwind.config.js` (not CSS `@theme`). NativeWind's `preset` bridges config values to RN styles. For dynamic values at runtime (e.g., user-selected accent color), use React context + a conditional className approach rather than CSS variables.

```tsx
// CSS variables work for web target in Expo
// For native, use config-defined tokens or inline style for dynamic values
<View
  className="bg-surface"  // static — from config
  style={{ backgroundColor: userColor }}  // dynamic — inline style
/>
```

Mixing `className` and `style` is valid and expected for this pattern.

---

## Expo Router Integration

NativeWind works with Expo Router out of the box — no special configuration.

```tsx
// app/(tabs)/index.tsx
import '../../../global.css'; // only needed in root _layout.tsx, not per-screen

export default function HomeScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-white">
      <Text className="text-2xl font-bold">Home</Text>
    </View>
  );
}
```

### Safe area utilities

```bash
npx expo install react-native-safe-area-context
```

```tsx
import { SafeAreaView } from 'react-native-safe-area-context';

<SafeAreaView className="flex-1 bg-white">
```

Or with NativeWind safe-area preset:

```tsx
<View className="pt-safe pb-safe px-4" />
```

---

## Web Compatibility

Expo with `expo-router` supports a web target via Metro. NativeWind uses Tailwind's PostCSS on the web target, so you get proper web CSS output.

Web-specific considerations:
- `cursor-pointer` applies on web, no-ops on native — safe to use
- `select-none` / `select-text` work on web, no-ops on native
- CSS grid (`grid`, `grid-cols-*`) does NOT work on native — use `flex-row flex-wrap` instead
- `overflow-hidden` behaves differently: clips on web, may not clip on Android without `elevation`
- `shadow-*` utilities generate CSS box-shadow on web and `elevation` on Android
- `ring-*` utilities only apply on web — no native equivalent

Use `web:` prefix to apply web-only styles and avoid unintended native behavior:

```tsx
<View className="flex-row web:grid web:grid-cols-3" />
```

---

## StyleSheet Migration

When migrating a component from `StyleSheet.create` to NativeWind:

1. Remove the `StyleSheet.create` call and import
2. Move style properties to `className` equivalents
3. Keep `style` prop only for dynamic values (calculated at runtime)
4. Verify layout matches — RN flex defaults differ from web (`flexDirection: 'column'` is default, not `row`)

```tsx
// Before
const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  title: { fontSize: 24, fontWeight: 'bold', color: '#111827' },
});
<View style={styles.container}>
  <Text style={styles.title}>Hello</Text>
</View>

// After
<View className="flex-1 p-4 bg-white">
  <Text className="text-2xl font-bold text-gray-900">Hello</Text>
</View>
```

Do not mix `StyleSheet` and `className` on the same component for the same properties — precedence is not guaranteed.

---

## Performance Considerations

- NativeWind compiles `className` at build time via Babel — zero runtime overhead for static classes
- Dynamic class construction (`className={condition ? 'bg-red' : 'bg-green'}`) involves a runtime string evaluation, but StyleSheet lookup is still pre-generated
- Avoid constructing class strings with template literals from large computed values — Tailwind's static analysis may not tree-shake them correctly
- Class purging depends on the `content` glob in `tailwind.config.js` — ensure all files using className are included

---

## NativeWind v4 vs v2

| Feature | v2 | v4 |
|---------|----|----|
| Config format | JS config | JS config (same, unlike web v4) |
| Babel plugin | `nativewind/babel` | `nativewind/babel` |
| Tailwind version | v3 | v4 |
| `@theme` CSS-first | No | Optional (web target) |
| Platform variants | Basic | `ios:`, `android:`, `web:` |
| Dark mode | ✓ | ✓ (improved) |
| Safe area | External | `nativewind/safe-area` |
| TypeScript types | Manual | Auto via `nativewind-env.d.ts` |

Migration from v2: update `nativewind` and `tailwindcss` versions, add `presets: [require('nativewind/preset')]` to config, update TypeScript reference.

---

## Limitations vs Web Tailwind

| Tailwind feature | Web | React Native |
|-----------------|-----|--------------|
| CSS Grid (`grid`, `grid-cols-*`) | ✓ | ✗ (use flexbox) |
| CSS custom properties in class | ✓ | Limited |
| `ring-*` utilities | ✓ | Web only |
| `backdrop-blur-*` | ✓ | Platform-limited |
| `cursor-*` | ✓ | No-op on native |
| `transition-*` / `animate-*` | ✓ | ✗ (use Reanimated) |
| `::before` / `::after` pseudo | ✓ | ✗ |
| `@container` queries | ✓ | ✗ |
| `hover:` variant | ✓ | Web only |
| `focus:` variant | ✓ | Limited (TextInput) |

For animation: use `react-native-reanimated` with `className` for layout and `animatedStyle` for motion properties.

---

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Forgetting `nativewind/babel` in Babel config | `className` not transformed — silently ignored | Add to plugins array |
| Missing file globs in `content` | Classes used in those files get purged | Add all source dirs to content |
| Using CSS grid utilities on native | Not supported — layout breaks | Use `flex-row flex-wrap` |
| Constructing class strings dynamically from arrays | Tailwind can't statically analyze them — classes may be purged | Use conditional ternary: `condition ? 'class-a' : 'class-b'` |
| Mixing `StyleSheet` and `className` for same properties | Undefined precedence — visual bugs | Pick one per component |
| Using `theme()` CSS function | Not applicable in RN config context | Use config `theme.extend` values |
| Assuming web Tailwind behavior | RN flex model differs (`flexDirection: 'column'` default) | Test layout on device — RN flex ≠ CSS flex |
| Adding `transition-*` for animations | No-op on native | Use Reanimated for motion |
