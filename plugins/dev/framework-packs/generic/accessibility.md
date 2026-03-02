---
origin: "addyosmani/web-quality-skills"
origin_skill: "accessibility"
origin_version: "1.0"
forked_date: "2026-03-02"
sections_kept: "WCAG principles (POUR), conformance levels, Perceivable (text alternatives, color contrast ratios, media), Operable (keyboard access, focus visible, skip links, motion), Understandable (language, labels, errors), Robust (valid HTML, ARIA), Testing checklist (automated + manual), Common issues by impact"
sections_removed: "Screen reader command tables (reference-only content, available elsewhere); external links/references section"
---

# Accessibility (WCAG 2.1)

WCAG 2.1 compliance guide. Use when auditing for a11y, adding keyboard support, fixing contrast issues, or implementing screen reader support.

> See also: `web-design-guidelines.md` for a broad 16-category UI review checklist (includes concise accessibility rules alongside forms, animation, dark mode, i18n, etc.). `e2e-testing-patterns.md` Pattern 5 for automated accessibility testing with axe-core in Playwright.

## WCAG Principles: POUR

| Principle | Description |
|-----------|-------------|
| **P**erceivable | Content can be perceived through different senses |
| **O**perable | Interface can be operated by all users |
| **U**nderstandable | Content and interface are understandable |
| **R**obust | Content works with assistive technologies |

**Conformance levels:** A (minimum), AA (standard — legal requirement in many jurisdictions), AAA (enhanced)

---

## Perceivable

### Text Alternatives (1.1)

```html
<!-- ❌ Missing alt -->
<img src="chart.png">

<!-- ✅ Descriptive alt -->
<img src="chart.png" alt="Bar chart showing 40% increase in Q3 sales">

<!-- ✅ Decorative image -->
<img src="decorative-border.png" alt="" role="presentation">

<!-- ✅ Complex image with description -->
<figure>
  <img src="infographic.png" alt="2024 market trends" aria-describedby="infographic-desc">
  <figcaption id="infographic-desc">Full description...</figcaption>
</figure>

<!-- ✅ Icon button with accessible name -->
<button aria-label="Open menu">
  <svg aria-hidden="true"><!-- menu icon --></svg>
</button>
```

**Visually hidden class (screen-reader only):**
```css
.visually-hidden {
  position: absolute; width: 1px; height: 1px;
  padding: 0; margin: -1px; overflow: hidden;
  clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0;
}
```

### Color Contrast (1.4.3)

| Text Size | AA Minimum | AAA Enhanced |
|-----------|------------|--------------|
| Normal (< 18px regular / < 14px bold) | **4.5:1** | 7:1 |
| Large (≥ 18px regular / ≥ 14px bold) | **3:1** | 4.5:1 |
| UI components & graphics | **3:1** | 3:1 |

```css
/* ❌ Low contrast (2.5:1) */
.low { color: #999; background: #fff; }

/* ✅ AA compliant (7:1) */
.high { color: #333; background: #fff; }

/* Don't rely on color alone */
/* ❌ Only color indicates error */
<input class="error-border">

/* ✅ Color + icon + text */
<span id="email-error" class="error-message">
  <svg aria-hidden="true"><!-- error icon --></svg>
  Please enter a valid email address
</span>
```

### Media Alternatives (1.2)

```html
<!-- Video with captions -->
<video controls>
  <source src="video.mp4" type="video/mp4">
  <track kind="captions" src="captions.vtt" srclang="en" label="English" default>
</video>

<!-- Audio with transcript -->
<audio controls><source src="podcast.mp3"></audio>
<details>
  <summary>Transcript</summary>
  <p>Full transcript text...</p>
</details>
```

---

## Operable

### Keyboard Accessible (2.1)

```typescript
// ❌ Click only
element.addEventListener('click', handleAction)

// ✅ Click + keyboard
element.addEventListener('click', handleAction)
element.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ' ') {
    e.preventDefault()
    handleAction()
  }
})
```

**Modal focus trap:**
```typescript
function openModal(modal: HTMLElement) {
  const focusable = modal.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  const first = focusable[0] as HTMLElement
  const last = focusable[focusable.length - 1] as HTMLElement

  modal.addEventListener('keydown', (e) => {
    if (e.key === 'Tab') {
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault(); last.focus()
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault(); first.focus()
      }
    }
    if (e.key === 'Escape') closeModal()
  })

  first.focus()
}
```

### Focus Visible (2.4.7)

```css
/* ❌ Never remove focus outlines */
*:focus { outline: none; }

/* ✅ Keyboard-only focus ring */
:focus { outline: none; }
:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}

/* ✅ Custom focus style */
button:focus-visible {
  box-shadow: 0 0 0 3px rgba(0, 95, 204, 0.5);
}
```

### Skip Links (2.4.1)

```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <header><!-- nav --></header>
  <main id="main-content" tabindex="-1"><!-- content --></main>
</body>
```

```css
.skip-link {
  position: absolute; top: -40px; left: 0;
  background: #000; color: #fff; padding: 8px 16px; z-index: 100;
}
.skip-link:focus { top: 0; }
```

### Reduced Motion (2.3)

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

---

## Understandable

### Language (3.1.1)

```html
<html lang="en">
<p>The French for hello is <span lang="fr">bonjour</span>.</p>
```

### Form Labels (3.3.2)

```html
<!-- ❌ No association -->
<input type="email" placeholder="Email">

<!-- ✅ Explicit label -->
<label for="email">Email address</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<!-- ✅ With instructions -->
<label for="password">Password</label>
<input type="password" id="password" aria-describedby="password-requirements">
<p id="password-requirements">Must be at least 8 characters with one number.</p>
```

### Error Handling (3.3.1, 3.3.3)

```html
<input type="email" id="email"
       aria-invalid="true"
       aria-describedby="email-error">
<p id="email-error" class="error" role="alert">
  Please enter a valid email address (e.g., name@example.com)
</p>
```

```typescript
// Focus first error on submit
form.addEventListener('submit', (e) => {
  const firstError = form.querySelector('[aria-invalid="true"]') as HTMLElement
  if (firstError) {
    e.preventDefault()
    firstError.focus()
  }
})
```

---

## Robust

### Valid HTML (4.1.1)

```html
<!-- ❌ Duplicate IDs -->
<div id="content">...</div>
<div id="content">...</div>

<!-- ❌ Invalid nesting -->
<a href="/"><button>Click</button></a>

<!-- ✅ Prefer native elements over ARIA -->
<button>Click me</button>                       <!-- not <div role="button"> -->
<label><input type="checkbox"> Option</label>   <!-- not role="checkbox" -->
```

### ARIA When Needed (4.1.2)

```html
<!-- Custom tabs -->
<div role="tablist" aria-label="Product information">
  <button role="tab" id="tab-1" aria-selected="true" aria-controls="panel-1">Description</button>
  <button role="tab" id="tab-2" aria-selected="false" aria-controls="panel-2" tabindex="-1">Reviews</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">...</div>
<div role="tabpanel" id="panel-2" aria-labelledby="tab-2" hidden>...</div>
```

### Live Regions (4.1.3)

```html
<!-- Polite: announces after current content -->
<div aria-live="polite" aria-atomic="true">
  <!-- Status updates, validation feedback -->
</div>

<!-- Assertive: interrupts immediately (use sparingly) -->
<div role="alert" aria-live="assertive">
  <!-- Critical errors only -->
</div>
```

---

## Testing Checklist

### Automated

```bash
# Lighthouse
npx lighthouse https://example.com --only-categories=accessibility

# axe-core CLI
npm install @axe-core/cli -g
axe https://example.com

# In Playwright tests
import AxeBuilder from '@axe-core/playwright'
const results = await new AxeBuilder({ page }).analyze()
expect(results.violations).toEqual([])
```

### Manual Checklist

- [ ] **Keyboard navigation:** Tab through entire page; Enter/Space activate elements
- [ ] **Tab order:** Logical sequence following visual layout
- [ ] **Screen reader:** Test with VoiceOver (Mac) or NVDA (Windows)
- [ ] **200% zoom:** Content still usable, no horizontal scroll
- [ ] **High contrast:** Test Windows High Contrast Mode
- [ ] **Reduced motion:** `prefers-reduced-motion: reduce` applied
- [ ] **Focus visible:** Every interactive element has visible focus indicator
- [ ] **Error flow:** Submit empty form, verify errors announced to screen readers

---

## Common Issues by Impact

**Critical (fix immediately):**
1. Missing form labels
2. Missing image alt text
3. Insufficient color contrast
4. Keyboard traps
5. No focus indicators

**Serious (fix before launch):**
1. Missing page language (`<html lang="en">`)
2. Missing heading structure
3. Non-descriptive link text ("click here")
4. Auto-playing media
5. Missing skip links

**Moderate (fix soon):**
1. Missing ARIA labels on icon buttons
2. Inconsistent navigation across pages
3. Missing error identification
4. Timing without controls
5. Missing landmark regions (`<nav>`, `<main>`, `<footer>`)
