---
name: expo-tailwind
description: >
  NativeWind / Tailwind CSS in React Native — setup, styling patterns,
  theme config, and platform differences for Expo projects.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo tailwind"
  - "nativewind"
  - "tailwind react native"
  - "expo css"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "nativewind_babel_plugin"
      verify: "babel.config.js includes nativewind/babel in plugins array"
      fail_action: "Add nativewind/babel plugin — className prop won't compile without it"
    - name: "tailwind_config_content_paths"
      verify: "tailwind.config.js content array covers .tsx/.ts/.jsx/.js in app source"
      fail_action: "Add source file globs to content — used classes will be purged"
    - name: "no_unsupported_utilities"
      verify: "No web-only utilities (CSS grid areas, CSS variables) used without RN compatibility check"
      fail_action: "Replace web-only utilities with RN-supported equivalents or platform guards"
    - name: "no_mixed_styling"
      verify: "No StyleSheet.create mixed with className on the same component"
      fail_action: "Pick one approach per component — mixing creates style conflicts"
  on_fail: "NativeWind setup has issues — check Babel config and Tailwind content paths"
  on_pass: "NativeWind configuration is correct"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# expo-tailwind

NativeWind brings Tailwind CSS to React Native via a Babel transform that converts `className` props to `StyleSheet` objects at compile time. Same API as web Tailwind, running on the RN style engine.

## Setup (NativeWind v4)

```bash
npx expo install nativewind tailwindcss && npx tailwindcss init
```

`tailwind.config.js`: set `content` to your source globs, add `presets: [require('nativewind/preset')]`. `babel.config.js`: add `'nativewind/babel'` to plugins. `global.css`: `@import "tailwindcss"` — import in root `_layout.tsx`.

## className Prop

```tsx
<View className="flex-1 bg-white px-4">
  <Text className="text-xl font-bold text-gray-900">Hello</Text>
</View>
```

NativeWind extends React Native's TypeScript types — `className` is typed on all core components after setup.

## Platform Variants

Built-in: `ios:`, `android:`, `web:`. Use for platform-specific spacing, font weights, or shadows.

```tsx
<View className="p-4 ios:pt-8 android:pt-6" />
```

## Dark Mode and Theming

`darkMode: 'media'` (follows system) or `'class'` (manual toggle) in `tailwind.config.js`. Usage: `className="bg-white dark:bg-gray-900"`. Extend colors, fonts, and spacing under `theme.extend`. For custom fonts, pair with `expo-font` — font family name in config must match the loaded font name.

## Expo Router Integration

`className` works on layouts and screens. Safe-area utilities via `nativewind/safe-area`: `pt-safe`, `pb-safe`. No special router config needed.

See `references/process.md` for responsive design, CSS variables, web compatibility, StyleSheet migration, performance, NativeWind v4 vs v2 differences, limitations vs web Tailwind, and anti-patterns.
