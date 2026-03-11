---
name: expo-dom-components
description: >
  Web components in native Expo context — DOM component bridges, WebView patterns, and hybrid rendering
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo dom components"
  - "expo web components"
  - "expo webview"
  - "expo hybrid"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "use_dom_directive_present"
      verify: "'use dom' directive is the first line of every DOM component file, before any imports"
      fail_action: "Add 'use dom' as the first line — without it the component renders as native, not web"
    - name: "communication_pattern_safe"
      verify: "Props passed to DOM components are plain serializable values — no functions referencing closures, no class instances"
      fail_action: "Replace non-serializable props with primitives or structured objects; use callback props for web→native communication"
    - name: "webview_deps_declared"
      verify: "react-native-webview is in dependencies and added to expo-plugins in app.json when WebView is used directly"
      fail_action: "Add react-native-webview and its config plugin — missing plugin breaks native builds"
  on_fail: "DOM component setup has issues that will cause runtime failures or silent render errors — fix before device testing"
  on_pass: "DOM component configuration is valid"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for smedjen"
---

# Expo DOM Components

Expo SDK 52+ lets you render web content inside a native view using a `'use dom'` directive. The file is bundled as a separate web bundle and mounted in an embedded WebView — no manual wiring required.

## The `'use dom'` Directive

`'use dom'` must be the first line of the component file (before imports):

```tsx
'use dom';
export default function RichEditor({ content }: { content: string }) {
  return <div contentEditable suppressContentEditableWarning>{content}</div>;
}
```

Import and use it in native code like any React Native component. The bridge handles serialization.

## Props and Callbacks

Props cross a serialization boundary — pass primitives and plain objects only. Function props work for web→native callbacks; the bridge serializes the call automatically.

## DOM Components vs Direct WebView

Use DOM components for self-contained web UI embedded in a native screen: rich text editors, D3/Chart.js visualizations, markdown renderers, or any web-only library with no RN equivalent.

Use `react-native-webview` directly when you need full control: `injectedJavaScript`, `onMessage`, remote `source.uri`, or navigation hooks.

## Shared State

DOM components run in a separate JS context — they don't share React state with native. Coordinate through props (native→web) and callbacks (web→native). For complex sync, use a shared data layer (AsyncStorage, MMKV, or server) as source of truth.

## Performance

Each DOM component spawns a WebView process. Keep the count low — prefer one DOM component managing its own internal complexity over multiple small ones mounted simultaneously.

See `references/process.md` for WebView patterns, `injectedJavaScript` usage, communication protocols, debugging, and anti-patterns.
