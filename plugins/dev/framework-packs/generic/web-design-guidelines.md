---
origin: "vercel-labs/agent-skills"
origin_skill: "web-design-guidelines"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "Fetch-based pattern, 16-category UI quality checklist (rules extracted from web-interface-guidelines). Full rules included inline since the original skill dynamically fetches them."
sections_removed: "Dynamic fetch instruction (replaced with inline rules for offline use)"
---

# Web Interface Guidelines

UI quality review across 16 categories. Use when asked to review UI code, audit design, check accessibility, or verify best practices.

> See also: `accessibility.md` for deep WCAG 2.1 compliance (contrast ratios, ARIA patterns, focus trap implementation, testing checklist). This skill covers breadth; that skill covers depth.

## How to Use

Review files against all rules below. Output findings in `file:line: issue` format. High signal-to-noise.

For always-fresh rules, fetch: `https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md`

---

## Rules by Category

### Accessibility

- Icon-only buttons need `aria-label`
- Form controls need `<label>` or `aria-label`
- Interactive elements need keyboard handlers (`onKeyDown`/`onKeyUp`)
- `<button>` for actions, `<a>`/`<Link>` for navigation (not `<div onClick>`)
- Images need `alt` (or `alt=""` if decorative)
- Decorative icons need `aria-hidden="true"`
- Async updates (toasts, validation) need `aria-live="polite"`
- Use semantic HTML before ARIA
- Headings hierarchical `<h1>`–`<h6>`; include skip link for main content
- `scroll-margin-top` on heading anchors

### Focus States

- Interactive elements need visible focus: `focus-visible:ring-*` or equivalent
- Never `outline-none` without focus replacement
- Use `:focus-visible` over `:focus`
- Group focus with `:focus-within` for compound controls

### Forms

- Inputs need `autocomplete` and meaningful `name`
- Use correct `type` (`email`, `tel`, `url`, `number`) and `inputmode`
- Never block paste (`onPaste` + `preventDefault`)
- Labels clickable (`htmlFor` or wrapping control)
- Disable spellcheck on emails, codes, usernames (`spellCheck={false}`)
- Submit button stays enabled until request starts; spinner during request
- Errors inline next to fields; focus first error on submit
- Placeholders end with `…` and show example pattern
- Warn before navigation with unsaved changes

### Animation

- Honor `prefers-reduced-motion`
- Animate `transform`/`opacity` only (compositor-friendly)
- Never `transition: all` — list properties explicitly
- Set correct `transform-origin`
- Animations interruptible — respond to user input mid-animation

### Typography

- `…` not `...`
- Curly quotes `"` `"` not straight `"`
- Non-breaking spaces: `10&nbsp;MB`, `⌘&nbsp;K`, brand names
- Loading states end with `…`: `"Loading…"`, `"Saving…"`
- `font-variant-numeric: tabular-nums` for number columns
- Use `text-wrap: balance` or `text-pretty` on headings

### Content Handling

- Text containers handle long content: `truncate`, `line-clamp-*`, or `break-words`
- Flex children need `min-w-0` to allow text truncation
- Handle empty states — don't render broken UI for empty arrays
- User-generated content: anticipate short, average, and very long inputs

### Images

- `<img>` needs explicit `width` and `height` (prevents CLS)
- Below-fold images: `loading="lazy"`
- Above-fold critical images: `priority` or `fetchpriority="high"`
- Use `next/image` for Next.js projects

### Performance

- Avoid render-blocking resources
- Dynamic import heavy components (`next/dynamic`, `React.lazy`)
- Avoid layout thrashing (read then write DOM)
- `will-change` only when animation is imminent; remove after

### Navigation

- Current page: `aria-current="page"` on active nav link
- External links: `target="_blank"` with `rel="noopener noreferrer"` and visual indicator
- Breadcrumbs: `<nav aria-label="Breadcrumb">` with `<ol>`
- Back button behavior: preserve scroll position and form state

### Touch & Interaction

- Touch targets minimum `44×44px` (WCAG 2.5.5)
- No hover-only interactions on touch devices
- Swipe gestures need visible alternatives
- Long-press menus need keyboard equivalent

### Safe Areas

- Use `env(safe-area-inset-*)` for notched device padding
- Bottom-fixed elements: `padding-bottom: env(safe-area-inset-bottom)`

### Dark Mode

- Test all states in both light and dark
- No hardcoded `#fff` or `#000` — use semantic tokens
- SVG icons: use `currentColor` for fill/stroke
- `color-scheme: light dark` on `:root`

### Locale & i18n

- Dates/numbers: use `Intl.DateTimeFormat` and `Intl.NumberFormat`
- RTL: use logical properties (`margin-inline-start` not `margin-left`)
- Avoid string concatenation for translated phrases

### Hydration Safety

- No `window`/`document` access during SSR — wrap in `useEffect` or `typeof window !== 'undefined'`
- Avoid rendering dates/times on server (hydration mismatch)
- `suppressHydrationWarning` only for known, intentional mismatches

### Hover States

- Hover styles on `:hover` only, not as default state
- Combine `:hover` and `:focus-visible` for interactive elements
- No critical information visible only on hover (mobile inaccessible)

### Content & Copy

- Button labels: verb + noun (`Save changes`, not `Save`)
- Error messages: explain what happened and what to do
- Empty states: explain why empty and provide action
- Loading states: show progress, not just a spinner
- Destructive actions: require confirmation

---

## Review Output Format

```
components/Header.tsx:24: icon button missing aria-label
components/Form.tsx:45: input missing autocomplete attribute
pages/dashboard.tsx:12: flex container missing min-w-0 on text child
```

Flag only real issues. No praise.
