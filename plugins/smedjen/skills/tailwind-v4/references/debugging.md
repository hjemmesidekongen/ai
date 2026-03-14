# tailwind-v4 — Debugging Reference

## Common Debugging Scenarios

### Classes not applying after v3 to v4 migration
**Symptom:** Tailwind utility classes that worked in v3 produce no styling in v4. No build errors, but the compiled CSS is missing the expected rules.
**Root cause:** Tailwind v4 replaces `tailwind.config.js` with a CSS-first configuration. The CSS entry point must use `@import "tailwindcss"` instead of the v3 `@tailwind` directives.
**Diagnosis:**
- Open the main CSS entry point (usually `app.css` or `globals.css`)
- Check for old v3 directives: `@tailwind base;`, `@tailwind components;`, `@tailwind utilities;` — these are ignored in v4
- Check for `@import "tailwindcss"` — this is the v4 entry point
- Inspect the compiled CSS output in the browser: DevTools > Sources > find the CSS file, search for a known utility like `.flex`
- If using PostCSS, verify `@tailwindcss/postcss` is installed and configured instead of the old `tailwindcss` PostCSS plugin
**Fix pattern:**
```css
/* v4 CSS entry point — replaces all @tailwind directives */
@import "tailwindcss";

/* Custom theme extensions go here using @theme */
@theme {
  --color-brand: #3b82f6;
}
```
```js
// postcss.config.js for v4
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
}
```

### Custom @theme tokens not generating utilities
**Symptom:** Custom tokens defined in `@theme` don't produce corresponding utility classes. Using `bg-brand` where `--color-brand` is defined does nothing.
**Root cause:** The `@theme` variable name doesn't follow Tailwind's namespace convention, or the `@theme` block is placed incorrectly.
**Diagnosis:**
- Inspect the compiled CSS output: search for the custom token name. If the CSS variable exists but no utility, the namespace is wrong
- Check the `@theme` block syntax — variables must use Tailwind's namespace prefixes:
  - Colors: `--color-*`
  - Spacing: `--spacing-*`
  - Font sizes: `--font-size-*`
  - Border radius: `--radius-*`
- Open browser DevTools > Elements > check computed styles on the element — is the class present but no rule, or is the class missing entirely?
- Run the Tailwind CLI in watch mode with verbose output to see which tokens are registered
**Fix pattern:**
```css
@import "tailwindcss";

@theme {
  /* Correct namespacing — generates bg-brand, text-brand, etc. */
  --color-brand: #3b82f6;
  --color-brand-light: #93c5fd;

  /* Correct — generates text-display, font-display */
  --font-family-display: "Inter", sans-serif;
  --font-size-display: 3rem;

  /* Wrong — no utility generated (not a recognized namespace) */
  --my-brand-color: #3b82f6;  /* won't work */
}
```

### @apply specificity conflicts
**Symptom:** Styles applied via `@apply` are overridden by other utility classes or base styles in unexpected ways.
**Root cause:** In v4, `@apply` inlines the utility's declarations at the point of use. If the `@apply` rule has lower specificity than a competing rule, or appears before it in source order, it loses.
**Diagnosis:**
- Open browser DevTools > Elements > Styles panel
- Find the element with the conflict — check which rules are crossed out
- Compare specificity: a class selector (0,1,0) vs an `@apply`'d utility inside a simple class selector (also 0,1,0) — source order wins
- Check if the competing rule comes from a CSS layer with higher priority
- Look for `!important` on either side
**Fix pattern:**
```css
/* If @apply conflicts with component styles, restructure to avoid @apply */

/* Instead of: */
.btn {
  @apply bg-blue-500 text-white;
}
/* ...which can conflict with inline utilities */

/* Prefer: use utilities directly in the template, or scope with a layer */
@layer components {
  .btn {
    @apply bg-blue-500 text-white;
  }
}
/* Component layer has lower priority than utilities, so inline overrides work */
```
If the conflict is with third-party CSS, check `@layer` ordering. Tailwind v4 uses CSS Cascade Layers: `@layer theme, base, components, utilities` — utilities always win.

### Dark mode strategy inconsistency
**Symptom:** Dark mode works on some components but not others. Some use `dark:` variants, others rely on CSS variables or manual class toggling.
**Root cause:** Mixed dark mode strategies in the codebase. v4 defaults to `@media (prefers-color-scheme: dark)` for `dark:` variants. If some components expect a `.dark` class on `<html>`, they'll break.
**Diagnosis:**
- Search the codebase for dark mode usage patterns:
  ```bash
  # Check for dark: variant usage
  rg 'dark:' --type css --type vue --type html -c

  # Check for manual dark class toggling
  rg 'classList.*dark|\.dark' --type js --type ts

  # Check for prefers-color-scheme media queries
  rg 'prefers-color-scheme' --type css
  ```
- Check the CSS entry point for dark mode configuration — in v4, selector-based dark mode requires explicit config
- Test by toggling system dark mode preference vs adding/removing `.dark` class on `<html>`
**Fix pattern:**
```css
@import "tailwindcss";

/* Selector-based dark mode (class strategy) */
@variant dark (&:where(.dark, .dark *));

/* Or media-based (default — no config needed) */
/* dark: variants automatically use prefers-color-scheme */
```
Pick one strategy and apply it project-wide. Selector-based is better when you need a manual toggle.

### Container queries not working
**Symptom:** `@container` size queries or Tailwind's `@` container variants (`@sm:`, `@md:`) have no effect on child elements.
**Root cause:** The parent element is missing `container-type: inline-size` (or `size`). Container queries only work when an ancestor establishes a containment context.
**Diagnosis:**
- Open browser DevTools > Elements > select the parent element
- Check Computed styles for `container-type` — if it's `normal` (default), no containment is established
- Search for the Tailwind class `@container` on the parent element in the HTML
- If using custom container names, verify the name matches between parent (`@container/sidebar`) and child (`@sm/sidebar:`)
**Fix pattern:**
```html
<!-- Parent must establish containment -->
<div class="@container">
  <!-- Children can use container query variants -->
  <div class="@sm:grid-cols-2 @lg:grid-cols-3">
    ...
  </div>
</div>

<!-- Named containers for multiple query contexts -->
<aside class="@container/sidebar">
  <nav class="@md/sidebar:flex-col">...</nav>
</aside>
```
```css
/* If using vanilla CSS container queries alongside Tailwind */
.sidebar {
  container-type: inline-size;
  container-name: sidebar;
}
```

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| Browser DevTools Styles panel | Inspect computed styles, specificity conflicts, layer order | F12 > Elements > Styles |
| Compiled CSS inspection | Verify utilities are generated and tokens resolved | DevTools > Sources > find compiled CSS file |
| Tailwind CLI (watch mode) | See real-time compilation output | `npx @tailwindcss/cli -i app.css -o out.css --watch` |
| `@theme` token list | Dump all registered theme tokens | Inspect compiled CSS for `--color-*`, `--spacing-*` variables in `:root` |
| PostCSS debug | Trace plugin execution order | `DEBUG=postcss:* npx postcss app.css` |
| CSS Cascade Layers view | Check layer priority in DevTools | DevTools > Styles > toggle layer view (Chrome 113+) |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
