# storybook-patterns — Debugging Reference

## Common Debugging Scenarios

### Story renders blank
**Symptom:** The Storybook canvas shows a white/empty panel. No error in the canvas, but the component simply doesn't appear. The Controls panel may or may not show args.
**Root cause:** Module resolution mismatch between Storybook's Webpack/Vite bundler and the project's path aliases. The component import resolves in the app but fails silently in Storybook.
**Diagnosis:**
- Open the browser console in Storybook (not the Actions panel — the actual browser console via F12). Look for:
  - `Module not found` errors pointing to aliased paths like `@/components/...`
  - `Failed to fetch dynamically imported module` for lazy imports
- Check `.storybook/main.ts` for alias configuration:
  ```ts
  // Does it mirror the project's path aliases?
  viteFinal: (config) => {
    config.resolve.alias = { ... }
  }
  // or for Webpack:
  webpackFinal: (config) => {
    config.resolve.alias = { ... }
  }
  ```
- Verify the story file's component import path resolves correctly
- Check if the component has required providers/context that aren't available in Storybook — add them via decorators
- Test with a minimal inline component to confirm Storybook itself works:
  ```tsx
  export const Sanity = () => <div>Hello</div>
  ```
**Fix pattern:**
```ts
// .storybook/main.ts — mirror project aliases
import path from 'path'

const config: StorybookConfig = {
  // ...
  viteFinal: (config) => {
    config.resolve ??= {}
    config.resolve.alias = {
      ...config.resolve.alias,
      '@': path.resolve(__dirname, '../src'),
      '~': path.resolve(__dirname, '../src'),
    }
    return config
  },
}
```
```tsx
// If the component needs providers, add a decorator
// .storybook/preview.tsx
const preview: Preview = {
  decorators: [
    (Story) => (
      <ThemeProvider>
        <Story />
      </ThemeProvider>
    ),
  ],
}
```

### Args/Controls not appearing
**Symptom:** The Controls panel is empty or shows "No inputs found for this component." Args defined in the story's `args` object don't generate UI controls.
**Root cause:** Storybook's automatic prop detection (react-docgen or react-docgen-typescript) can't parse the component's prop types. Common with complex generics, re-exported types, or when the docgen setting is misconfigured.
**Diagnosis:**
- Check `.storybook/main.ts` for the TypeScript docgen configuration:
  ```ts
  typescript: {
    reactDocGen: 'react-docgen-typescript', // or 'react-docgen' or false
  }
  ```
- `react-docgen` (default in Storybook 8+) is faster but can't handle all TS patterns. `react-docgen-typescript` is more thorough but slower
- Check the component's prop definition — does it use:
  - Intersection types (`Props & HTMLAttributes<...>`) — can confuse docgen
  - Re-exported types from another package — docgen may not follow the import
  - `forwardRef` with generic types — needs explicit typing
- Test by adding explicit `argTypes` to the story meta to confirm controls work when manually defined
**Fix pattern:**
```ts
// .storybook/main.ts — switch docgen if needed
const config: StorybookConfig = {
  typescript: {
    reactDocGen: 'react-docgen-typescript',
    reactDocGenTypescriptOptions: {
      shouldExtractLiteralValuesFromEnum: true,
      shouldRemoveUndefinedFromOptional: true,
      propFilter: (prop) =>
        prop.parent ? !/node_modules/.test(prop.parent.fileName) : true,
    },
  },
}
```
```tsx
// Fallback — manually define argTypes in the story
const meta: Meta<typeof Button> = {
  component: Button,
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'ghost'],
    },
    disabled: { control: 'boolean' },
    size: {
      control: 'radio',
      options: ['sm', 'md', 'lg'],
    },
  },
}
```

### Play function CI failures
**Symptom:** Interaction tests pass locally in the browser but fail in CI (headless Chromium via `test-storybook`). Errors like "Unable to find element" or "element not visible" appear intermittently.
**Root cause:** `getBy*` queries throw immediately if the element isn't in the DOM. In CI, rendering is slower (no GPU, limited resources), so elements that appear instantly in a local browser aren't rendered yet when the query runs.
**Diagnosis:**
- Check which query the play function uses — `getBy*` is synchronous and fails fast; `findBy*` is async and waits up to 1000ms by default
- Review the CI logs for the specific assertion that failed — is it a timing-related element query or a genuine logic error?
- Check if the component has animations, transitions, or lazy-loaded content that delays rendering
- Run the test-storybook command locally in headless mode to reproduce:
  ```bash
  npx test-storybook --browsers chromium
  ```
- Look for `waitFor` wrapping state-dependent assertions
**Fix pattern:**
```tsx
// Before — fragile in CI
export const WithData: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)

    // Fails if data hasn't loaded yet
    const item = canvas.getByText('Item 1')
    expect(item).toBeVisible()
  },
}

// After — resilient to async rendering
export const WithData: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)

    // Waits for element to appear (default timeout: 1000ms)
    const item = await canvas.findByText('Item 1')
    expect(item).toBeVisible()

    // For state changes after interaction, wrap in waitFor
    await userEvent.click(canvas.getByRole('button', { name: 'Load more' }))
    await waitFor(() => {
      expect(canvas.getByText('Item 6')).toBeVisible()
    })
  },
}
```
```bash
# Increase timeout for slow CI environments
# In test-storybook config or via CLI
npx test-storybook --testTimeout 15000
```

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Browser console in Storybook | Catch silent import errors and rendering exceptions | F12 in Storybook browser tab |
| Storybook Interactions panel | Step through play function actions one by one | Click "Interactions" tab in story panel |
| `test-storybook` (local headless) | Reproduce CI failures locally | `npx test-storybook --browsers chromium` |
| `test-storybook --verbose` | Detailed test output with assertion details | `npx test-storybook --verbose` |
| `--no-cache` flag | Rule out stale Storybook cache | `npx storybook dev --no-cache` |
| Storybook manager logs | Debug addon loading and config issues | Browser console on the Storybook manager frame (not the preview iframe) |
| `npx sb doctor` | Diagnose common Storybook config issues | `npx storybook doctor` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
