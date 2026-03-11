# expo-dom-components — Process Reference

## DOM Components Concept

Expo DOM components (SDK 52+) allow a React component file to be rendered as a web document inside a native WebView. The `'use dom'` directive at the top of a file signals the Metro bundler to compile it as a web bundle and mount it in an embedded `react-native-webview` instance at runtime.

This is distinct from running a full web app — DOM components are leaf nodes in the native component tree, designed for isolated web UI islands.

## How the Bridge Works

When native code renders a DOM component, Expo creates a WebView and loads the compiled web bundle. Props are serialized (JSON) and posted to the web context via the WebView message channel. Callback props are proxied: when the web code calls `onSave(value)`, the bridge posts a message back to native, which deserializes and invokes the native function.

The bridge is transparent but not free — every prop update re-posts to the WebView. Avoid high-frequency prop updates (e.g., tying a DOM component prop to scroll position).

## Direct WebView Patterns

When you need control the DOM component abstraction doesn't expose, use `react-native-webview` directly.

### Loading a local HTML string

```tsx
import { WebView } from 'react-native-webview';

const html = `
  <!DOCTYPE html>
  <html>
    <body><div id="root"></div></body>
    <script>document.getElementById('root').innerText = 'Hello';</script>
  </html>
`;

<WebView source={{ html }} style={{ flex: 1 }} />
```

### Injecting JavaScript into a loaded page

```tsx
const webviewRef = useRef<WebView>(null);

// After page loads:
webviewRef.current?.injectJavaScript(`
  document.querySelector('.banner').style.display = 'none';
  true; // required — last expression must be truthy
`);
```

### Receiving messages from web

In the web page:
```js
window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'input', value: text }));
```

In native:
```tsx
<WebView
  onMessage={(event) => {
    const data = JSON.parse(event.nativeEvent.data);
    if (data.type === 'input') handleInput(data.value);
  }}
/>
```

## Communication Between Native and Web

| Direction | Mechanism |
|-----------|-----------|
| Native → Web | Props (DOM components) or `injectJavaScript` (direct WebView) |
| Web → Native | Callback props (DOM components) or `window.ReactNativeWebView.postMessage` (direct WebView) |

Keep message payloads small. Large serialized objects on every update degrade frame rate.

## Shared State Patterns

DOM components and native code run in separate JS runtimes — no shared memory. Options for coordination:

- **Props + callbacks**: sufficient for most cases. Native owns state; web reports back via callbacks.
- **AsyncStorage / MMKV**: write from native, read from web on mount. Good for persisted preferences.
- **Server as source of truth**: both native and web poll or subscribe to the same API. Scales to complex sync requirements.
- **URL parameters**: embed state in the WebView `source.uri` query string for read-only config.

Avoid trying to sync React state across the boundary in real time — the serialization overhead is not worth it for high-frequency updates.

## Use Cases

**Appropriate for DOM components:**
- Rich text editors (Quill, TipTap, ProseMirror) — no viable native equivalent
- Data visualization (D3, Chart.js, Recharts) — rendering SVG via web is simpler than native SVG
- Markdown renderers (marked, remark)
- Code editors (Monaco, CodeMirror)
- Complex tables and grids with web-native sorting/filtering

**Not appropriate:**
- Simple text display — use `<Text>` and RN styling
- Forms with basic inputs — use native `TextInput`, `Switch`, etc.
- Anything performance-critical that updates on every frame

## Performance Considerations

- Each DOM component instance creates a WebView process. On low-end Android, this is 30–60MB of RAM per instance.
- Do not render DOM components inside `FlatList` items that scroll — instantiating many WebViews kills performance.
- If a DOM component is conditionally shown, unmounting it destroys the WebView. Consider keeping it mounted with `display: none` via a wrapper if re-init cost is high.
- Prefer one DOM component with internal routing over multiple parallel DOM components.

## Debugging

- DOM component web code runs in a WebView — React DevTools for web (not RN DevTools) is the right tool.
- On iOS simulator, use Safari → Develop menu → Simulator to attach to the WebView.
- On Android, use `chrome://inspect` in Chrome.
- For the native bridge layer, add logging in `onMessage` and verify payload shapes.

## Anti-Patterns

**Passing non-serializable props:**
Functions that reference complex closures, class instances, Dates, Maps, and Sets all break silently. Stick to plain JSON-compatible values.

**High-frequency prop updates:**
Updating DOM component props on every scroll or animation frame posts a new message on every tick. The web context lags behind. Debounce or batch updates.

**Multiple DOM components in a list:**
Putting a DOM component inside a `FlatList` item renders a WebView per row. Avoid this entirely — render the list in web or use a native list with a single DOM component for expanded detail.

**Using DOM components for navigation:**
DOM components are isolated — they can't push a native screen or trigger navigation. Keep navigation in native code; use callbacks to signal intent.

**Omitting the cleanup of injectedJavaScript side effects:**
If you inject event listeners via `injectJavaScript`, they accumulate on reload. Either inject idempotent code or track whether injection has run.
