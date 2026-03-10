# tailwind-v4 — Process Reference

Full reference for v3→v4 migration, CSS-first configuration, custom utilities, variants, dark mode, container queries, responsive design, PostCSS, component extraction, and anti-patterns.

---

## v3 → v4 Migration

### Step-by-step

1. **Remove `tailwind.config.js`** (or `.ts`) — configuration moves to CSS
2. **Update import in CSS entry file**:
   ```css
   /* v3 */
   @tailwind base;
   @tailwind components;
   @tailwind utilities;

   /* v4 */
   @import "tailwindcss";
   ```
3. **Move theme customizations** into `@theme` blocks in your CSS
4. **Replace `theme()` calls** in CSS with `var(--color-brand)` etc. (CSS variables)
5. **Replace `addUtilities` / `addVariant` plugins** with `@utility` / `@variant` in CSS
6. **Update PostCSS config** — v4 uses `@tailwindcss/postcss` instead of `tailwindcss`
7. **Run the codemod** for automated class name changes:
   ```bash
   npx @tailwindcss/upgrade
   ```

### Breaking changes checklist

| v3 | v4 |
|----|-----|
| `tailwind.config.js` | `@theme {}` in CSS |
| `@tailwind base/components/utilities` | `@import "tailwindcss"` |
| `theme()` in CSS | `var(--tw-color-*)` / CSS custom properties |
| `addUtilities()` in plugin | `@utility` in CSS |
| `addVariant()` in plugin | `@variant` in CSS |
| `container` plugin | `@container` built-in |
| `opacity-{n}` (0–100) | `opacity-{n}` (0–100, same) |
| `shadow-sm` default | slightly adjusted shadow scale |
| `ring` default width 3px | `ring` default width 1px |

---

## CSS-First Configuration (@theme)

### Token namespaces

Tailwind v4 maps `@theme` variable names to utility class names by convention:

```css
@theme {
  /* colors → bg-*, text-*, border-*, fill-*, etc. */
  --color-primary: oklch(55% 0.22 265);
  --color-primary-hover: oklch(50% 0.22 265);

  /* spacing → p-*, m-*, gap-*, w-*, h-*, etc. */
  --spacing-18: 4.5rem;
  --spacing-22: 5.5rem;

  /* typography */
  --font-display: "Cal Sans", sans-serif;
  --font-body: "Inter", sans-serif;
  --text-2xs: 0.625rem;
  --leading-tighter: 1.1;

  /* borders */
  --radius-card: 0.75rem;
  --radius-pill: 9999px;

  /* shadows */
  --shadow-card: 0 2px 12px 0 oklch(0% 0 0 / 0.08);

  /* breakpoints */
  --breakpoint-xs: 480px;
  --breakpoint-3xl: 1920px;
}
```

### Extending vs overriding

```css
/* Extend: add alongside defaults */
@theme {
  --color-brand: oklch(55% 0.2 250);
}

/* Override: redefine a built-in */
@theme {
  --color-blue-500: oklch(58% 0.18 250); /* replaces Tailwind's blue-500 */
}

/* Remove: clear an entire namespace */
@theme {
  --color-*: initial; /* removes ALL color utilities — then redefine your own */
}
```

### Using theme values in CSS

```css
.card {
  background: var(--color-primary);
  padding: var(--spacing-6);
  border-radius: var(--radius-card);
}
```

Do not use `theme()` function in v4. It still works as a compatibility shim but CSS variables are the correct approach.

---

## Custom Utilities (@utility)

`@utility` creates named utilities that work with every variant, responsive prefix, and modifier:

```css
/* Single declaration */
@utility text-balance {
  text-wrap: balance;
}

/* Multi-declaration */
@utility container-padded {
  padding-inline: clamp(1rem, 5vw, 3rem);
  max-width: 80rem;
  margin-inline: auto;
}

/* With CSS variable for modifier support */
@utility opacity-{n} {
  opacity: calc(n / 100);
}
```

Usage in HTML: `text-balance`, `md:text-balance`, `hover:text-balance` — all work.

---

## Custom Variants (@variant)

```css
/* Pseudo-class */
@variant hocus {
  &:hover, &:focus {
    @slot;
  }
}

/* Attribute-based */
@variant data-loading {
  &[data-loading] {
    @slot;
  }
}

/* Parent state */
@variant peer-checked {
  .peer:checked ~ & {
    @slot;
  }
}
```

Usage: `hocus:bg-brand`, `data-loading:opacity-50`.

---

## Dark Mode

### Strategy 1: Media-based (default)

```css
/* No config needed — dark: variant responds to prefers-color-scheme */
```

```html
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
```

### Strategy 2: Class-based

```css
@variant dark (&:where(.dark, .dark *));
```

Then toggle `.dark` class on `<html>` or a root element in JS.

### Strategy 3: Data attribute

```css
@variant dark (&:where([data-theme=dark], [data-theme=dark] *));
```

### Mixing strategies

Never mix strategies in a single project. Class-based and media-based respond to different signals — mixed usage produces non-deterministic behavior when user OS preference and class state diverge.

---

## Container Queries

Built-in — no plugin required.

```html
<!-- Parent: establish a containment context -->
<div class="@container">
  <!-- Children: style based on container size, not viewport -->
  <div class="grid @sm:grid-cols-2 @lg:grid-cols-3">
```

### Named containers

```html
<div class="@container/sidebar">
  <nav class="@sm/sidebar:flex @lg/sidebar:flex-col">
```

### Container breakpoints (default)

| Variant | Min-width |
|---------|-----------|
| `@xs`   | 320px |
| `@sm`   | 384px |
| `@md`   | 448px |
| `@lg`   | 512px |
| `@xl`   | 576px |
| `@2xl`  | 672px |

### Arbitrary container sizes

```html
<div class="@[600px]:grid-cols-3">
```

---

## Responsive Design

Breakpoints work identically to v3. Custom breakpoints via `@theme`:

```css
@theme {
  --breakpoint-xs: 480px;
  --breakpoint-3xl: 1920px;
}
```

Usage: `xs:flex`, `3xl:max-w-screen-3xl`.

Mobile-first by default. Use `max-sm:`, `max-md:` etc. for max-width variants.

---

## Arbitrary Values

Syntax unchanged from v3:

```html
<div class="w-[327px] bg-[oklch(60%_0.15_200)] mt-[13px]">
<div class="text-[clamp(1rem,5vw,2rem)] grid-cols-[1fr_2fr_1fr]">
```

CSS variables in arbitrary values:

```html
<div class="bg-[var(--color-brand)] p-[var(--spacing-18)]">
```

---

## @apply — Usage and Limits

### When @apply is acceptable

Base element resets and global styles where you can't control the markup:

```css
@layer base {
  h1, h2, h3 {
    @apply font-display tracking-tight;
  }

  a {
    @apply text-brand underline underline-offset-2;
  }
}
```

### When to avoid @apply

Do not use `@apply` to extract component classes:

```css
/* Anti-pattern — defeats Tailwind's purpose */
.btn-primary {
  @apply rounded-lg bg-brand px-4 py-2 text-white font-medium;
}
```

Instead: keep the classes in markup, or use a JS component abstraction. If the pattern appears in 3+ places, create a component — not a CSS class.

### Exception: @utility is better

If you need a named utility, use `@utility` — it participates in variants. `@apply` does not produce a utility class; it inlines styles.

---

## PostCSS Integration

```bash
npm install -D @tailwindcss/postcss
```

```js
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
}
```

No `tailwindcss` plugin entry — `@tailwindcss/postcss` handles everything including autoprefixer. Do not add autoprefixer separately; it's included.

### Vite (preferred)

```bash
npm install -D @tailwindcss/vite
```

```ts
// vite.config.ts
import tailwindcss from '@tailwindcss/vite'

export default {
  plugins: [tailwindcss()],
}
```

Vite plugin is faster than PostCSS — prefer it for Vite projects.

---

## Component Extraction Patterns

### Preferred: JS/framework component

```tsx
// Button.tsx — classes live in markup, variant logic in JS
const variants = {
  primary: 'bg-brand text-white hover:bg-brand-hover',
  ghost: 'border border-current text-brand hover:bg-brand/10',
}

export function Button({ variant = 'primary', ...props }) {
  return <button className={`rounded-lg px-4 py-2 ${variants[variant]}`} {...props} />
}
```

### Acceptable: @layer components for third-party HTML

When you cannot control the markup (CMS output, markdown rendering):

```css
@layer components {
  .prose h2 { @apply text-2xl font-display tracking-tight mt-8 mb-3; }
  .prose p  { @apply text-base leading-relaxed text-gray-700; }
}
```

### Avoid: Component classes for things you own

If you own the markup, put classes there. Extracting to CSS adds indirection, hides what a component looks like at a glance, and breaks Tailwind's tree-shaking model.

---

## Plugins

v4 plugins use CSS-only APIs. No JS plugin function needed for most cases.

For utility and variant extensions: use `@utility` and `@variant` directly in CSS.

For complex plugins that ship as npm packages, they export a CSS file:

```css
@import "tailwindcss";
@import "@some/tailwind-plugin"; /* imports @utility/@variant definitions */
```

If you need JS-level plugin logic (e.g., dynamic utilities based on config), the plugin API still exists but is scoped to edge cases.

---

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Keeping `tailwind.config.js` | Dual config source — CSS theme ignored | Migrate to `@theme` |
| `@tailwind` directives | Not supported in v4 | Use `@import "tailwindcss"` |
| `theme()` in CSS | Deprecated compatibility shim | Use `var(--color-*)` |
| `@apply` for component styles | Hides classes, breaks variants | Use framework components |
| Mixing dark mode strategies | Non-deterministic behavior | Pick one, apply globally |
| Inline `@theme` in component files | Duplicated token definitions | Single `@theme` in root CSS |
| Adding autoprefixer to PostCSS | Conflicts with built-in prefixing | Remove it — already included |
| Arbitrary value overuse | Undermines design token discipline | Define token in `@theme` instead |
