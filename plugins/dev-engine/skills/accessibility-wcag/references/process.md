# accessibility-wcag — Process Reference

## WCAG 2.1 AA Checklist

### Perceivable
- [ ] All images have meaningful `alt` text; decorative images use `alt=""`
- [ ] Complex images (charts, diagrams) have extended descriptions
- [ ] Video has captions; audio has transcripts
- [ ] Color is not the sole means of conveying information
- [ ] Text contrast ≥4.5:1 (normal), ≥3:1 (large text ≥18pt / 14pt bold)
- [ ] UI component and focus indicator contrast ≥3:1 against adjacent colors
- [ ] Content reflows to single column at 320px without horizontal scroll
- [ ] Text can be resized to 200% without loss of content or functionality

### Operable
- [ ] All interactive elements keyboard-accessible (Tab, Shift+Tab, Enter, Space, arrow keys)
- [ ] No keyboard traps outside intentional modal contexts
- [ ] Skip navigation link at top of page (visible on focus)
- [ ] Focus indicators are visible and meet 3:1 contrast ratio
- [ ] No session timeouts without warning and extension option
- [ ] No content flashes more than 3 times per second
- [ ] Page titles are descriptive and unique
- [ ] Focus order matches reading order

### Understandable
- [ ] `lang` attribute set on `<html>` element
- [ ] Language changes within page marked with `lang` attribute
- [ ] Form inputs have labels; error messages identify the field and describe the fix
- [ ] Consistent navigation and labeling across pages
- [ ] No unexpected context changes on focus or input

### Robust
- [ ] Valid HTML — no duplicate IDs, properly nested elements
- [ ] ARIA used correctly: no invalid roles, states match element state, no conflicting attributes
- [ ] Custom widgets implement full ARIA authoring practice patterns
- [ ] Status messages announced without receiving focus (aria-live)

---

## Semantic HTML Elements

| Purpose | Element |
|---|---|
| Main content area | `<main>` |
| Primary navigation | `<nav>` |
| Page header | `<header>` |
| Page footer | `<footer>` |
| Complementary content | `<aside>` |
| Standalone content | `<article>` |
| Thematic grouping | `<section>` (with heading) |
| Document headings | `<h1>`–`<h6>` (one `<h1>` per page) |
| Interactive control | `<button>` (not div/span) |
| Navigation link | `<a href>` (not div with onClick) |
| Form grouping | `<fieldset>` + `<legend>` |
| Data table | `<table>` + `<th scope>` + `<caption>` |

Heading hierarchy: do not skip levels. `h1 → h2 → h3`, never `h1 → h3`.

---

## ARIA Roles, States, and Properties

### Landmark Roles (prefer HTML equivalents)
```
role="banner"        → <header>
role="navigation"    → <nav>
role="main"          → <main>
role="complementary" → <aside>
role="contentinfo"   → <footer>
role="search"        → <search> or <form role="search">
role="region"        → <section aria-labelledby="id">
```

### Widget Roles (no HTML equivalent — use with full keyboard support)
```
role="dialog"        Modal dialogs — requires aria-modal="true", aria-labelledby
role="alertdialog"   Alert dialogs requiring user response
role="combobox"      Custom dropdowns — complex pattern, follow APG
role="listbox"       Selection list widget
role="tree"          Hierarchical list widget
role="tablist"       Tab container — with role="tab" + role="tabpanel"
role="tooltip"       Hover/focus tooltip — set via aria-describedby
```

### Key States and Properties
```
aria-label           Accessible name when no visible text label exists
aria-labelledby      References an element's text as the label
aria-describedby     References supplemental description text
aria-expanded        true/false — toggleable regions (accordion, menu)
aria-hidden          true — removes from accessibility tree (decorative only)
aria-live            polite | assertive — announces dynamic content changes
aria-atomic          true — announces the entire live region on change
aria-required        true — marks required fields
aria-invalid         true | grammar | spelling — marks invalid fields
aria-disabled        true — non-interactive but visible elements
aria-selected        true/false — tabs, listbox options
aria-checked         true/false/mixed — checkboxes, radio buttons
aria-current         page | step | date — active item in a set
aria-controls        References element controlled by this element
aria-owns            References child elements not in DOM hierarchy
```

---

## Keyboard Navigation

### Focus Management Patterns

**Modal dialogs**: trap focus inside modal when open. On open, move focus to first focusable element or the dialog itself. On close, return focus to the trigger element.

```js
// Focus trap — collect all focusable elements
const focusable = modal.querySelectorAll(
  'a[href], button:not([disabled]), input:not([disabled]), ' +
  'select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
);
const first = focusable[0];
const last = focusable[focusable.length - 1];

modal.addEventListener('keydown', (e) => {
  if (e.key !== 'Tab') return;
  if (e.shiftKey && document.activeElement === first) {
    e.preventDefault(); last.focus();
  } else if (!e.shiftKey && document.activeElement === last) {
    e.preventDefault(); first.focus();
  }
});
```

**Tab order**: follows DOM order unless `tabindex` overrides it. Do not use positive tabindex values — they break natural order. Use `tabindex="0"` to make a non-interactive element focusable; `tabindex="-1"` for programmatic-only focus.

**Arrow key navigation**: required for composite widgets (tabs, menubars, listboxes, trees). Arrow keys move between items inside the widget; Tab moves focus out of the widget entirely (roving tabindex pattern).

### Keyboard Traps

Traps are only acceptable inside modal dialogs and similar contained contexts. Outside modals, focus must be able to leave any component via Tab or Shift+Tab.

### Skip Links

```html
<a href="#main-content" class="skip-link">Skip to main content</a>
<main id="main-content">...</main>
```

```css
.skip-link {
  position: absolute;
  left: -9999px;
}
.skip-link:focus {
  left: 0;
  top: 0;
  /* visible styles */
}
```

---

## Screen Reader Testing

### Testing Matrix
| Tool | Platform | Browser |
|---|---|---|
| VoiceOver | macOS / iOS | Safari (primary), Chrome |
| NVDA | Windows | Firefox (primary), Chrome |
| JAWS | Windows | Chrome, Edge, Firefox |
| TalkBack | Android | Chrome |

### VoiceOver Basics (macOS)
- Toggle: `Cmd + F5`
- Read next item: `VO + Right` (VO = Ctrl + Option)
- Click: `VO + Space`
- Navigate headings: `VO + Cmd + H`
- Navigate landmarks: `VO + Cmd + L`
- Open rotor: `VO + U`

### NVDA Basics (Windows)
- Toggle: `Ctrl + Alt + N`
- Browse mode / forms mode: `Ins + Space`
- Navigate headings: `H`
- Navigate landmarks: `D`
- Navigate links: `K`

### What to Verify
- Every interactive element has an announced name
- Button states (expanded, pressed, checked) are announced on change
- Error messages are read when fields become invalid
- Dynamic content updates (toasts, live regions) are announced
- Modal open/close announces title and focus moves correctly
- Images: meaningful alt text is read; decorative images are skipped

---

## Color Contrast

### Ratios (WCAG 2.1 AA)
| Content type | Minimum ratio |
|---|---|
| Normal text (<18pt, <14pt bold) | 4.5:1 |
| Large text (≥18pt or ≥14pt bold) | 3:1 |
| UI components (borders, icons) | 3:1 |
| Focus indicators | 3:1 against adjacent colors |
| Disabled elements | Exempt |
| Logos and decorative content | Exempt |

### Tools
- **WebAIM Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **Colour Contrast Analyser** (desktop app) — eyedrop any pixel on screen
- **axe DevTools** — flags contrast failures in-browser
- **Figma**: Contrast plugin or A11y Annotation Kit

---

## Form Accessibility

```html
<!-- Explicit label (preferred) -->
<label for="email">Email address</label>
<input id="email" type="email" aria-required="true" />

<!-- aria-label (when visible label isn't possible) -->
<input type="search" aria-label="Search products" />

<!-- aria-labelledby (label text elsewhere in DOM) -->
<h2 id="billing-heading">Billing address</h2>
<input aria-labelledby="billing-heading" ... />

<!-- Error state -->
<input
  id="email"
  type="email"
  aria-invalid="true"
  aria-describedby="email-error"
/>
<span id="email-error" role="alert">Enter a valid email address</span>

<!-- Grouped inputs -->
<fieldset>
  <legend>Shipping method</legend>
  <label><input type="radio" name="ship" value="standard" /> Standard</label>
  <label><input type="radio" name="ship" value="express" /> Express</label>
</fieldset>
```

Placeholder text is not a label. It disappears on input and has insufficient contrast in most browsers. Always use `<label>` or `aria-label`.

---

## Image Alt Text

```html
<!-- Informative image -->
<img src="chart.png" alt="Bar chart showing Q3 revenue up 22% over Q2" />

<!-- Decorative image -->
<img src="divider.png" alt="" role="presentation" />

<!-- Functional image (icon button) -->
<button><img src="search-icon.svg" alt="Search" /></button>

<!-- Complex image -->
<figure>
  <img src="org-chart.png" alt="Organisation chart — described below" />
  <figcaption>
    CEO reports to Board. Three VPs report to CEO: Engineering, Sales, Marketing.
  </figcaption>
</figure>

<!-- SVG -->
<svg role="img" aria-labelledby="svg-title">
  <title id="svg-title">Upward trend in monthly active users</title>
  ...
</svg>

<!-- Decorative SVG -->
<svg aria-hidden="true" focusable="false">...</svg>
```

---

## Live Regions

Use live regions to announce dynamic content without moving focus.

```html
<!-- Polite: waits for user to finish current task -->
<div aria-live="polite" aria-atomic="true">
  <!-- Inject status messages here -->
</div>

<!-- Assertive: interrupts — use only for critical errors -->
<div aria-live="assertive" role="alert"></div>

<!-- Status role (polite by default) -->
<div role="status">3 results found</div>
```

Inject content into the live region after it's in the DOM. Empty on page load, then populate. Screen readers only announce changes — adding a populated element is unreliable.

---

## Focus Indicators

Do not suppress focus outlines with `outline: none` unless you provide an equivalent custom indicator that meets 3:1 contrast.

```css
/* Minimum viable focus style */
:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}

/* High-visibility option */
:focus-visible {
  outline: 3px solid #ffbf47;
  outline-offset: 3px;
  border-radius: 2px;
}
```

Use `:focus-visible` (not `:focus`) to avoid showing outlines on mouse clicks while preserving them for keyboard navigation.

---

## Responsive Accessibility

- Do not disable zoom (`user-scalable=no`) — required by WCAG 1.4.4
- Touch targets: minimum 44×44px (WCAG 2.5.5 — AAA; 24×24px is AA in WCAG 2.2)
- Reflow at 320px width without horizontal scroll or loss of content (1.4.10 AA)
- Orientation: do not lock to portrait or landscape unless essential (1.3.4 AA)

---

## Testing Tools

| Tool | Type | What it finds |
|---|---|---|
| **axe DevTools** | Browser extension | ~57% of WCAG issues automatically |
| **Lighthouse** | Chrome DevTools / CI | Accessibility score + flagged issues |
| **WAVE** | Browser extension | Visual overlay of errors and structure |
| **VoiceOver** | Manual | Screen reader experience on macOS/iOS |
| **NVDA** | Manual | Screen reader experience on Windows |
| **Colour Contrast Analyser** | Desktop app | Pixel-level contrast checking |
| **axe-core** | npm / jest-axe | Automated testing in unit/integration tests |
| **playwright-axe** | E2E | Page-level axe scan in Playwright tests |

### axe-core in Tests

```js
// jest-axe
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);

it('has no accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

---

## React Accessibility Patterns

### Accessible button with icon
```jsx
// Wrong — icon only, no accessible name
<button><Icon name="close" /></button>

// Correct — visually hidden label
<button>
  <Icon name="close" aria-hidden="true" />
  <span className="sr-only">Close dialog</span>
</button>
```

### Screen-reader-only utility class
```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

### Dialog component (React)
```jsx
function Dialog({ isOpen, onClose, title, children }) {
  const dialogRef = useRef(null);

  useEffect(() => {
    if (isOpen) {
      dialogRef.current?.focus();
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="dialog-title"
      tabIndex={-1}
      ref={dialogRef}
    >
      <h2 id="dialog-title">{title}</h2>
      {children}
      <button onClick={onClose}>Close</button>
    </div>
  );
}
```

### useId for label association (React 18+)
```jsx
function FormField({ label, type = 'text' }) {
  const id = useId();
  return (
    <>
      <label htmlFor={id}>{label}</label>
      <input id={id} type={type} />
    </>
  );
}
```

---

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `<div onClick={...}>` | Not keyboard accessible, no role | Use `<button>` |
| `<a>` without `href` | Acts as non-focusable text | Add `href` or use `<button>` |
| `outline: none` globally | Removes keyboard visibility | Use `:focus-visible` with custom style |
| `aria-label` on `<div>` with no role | Label has nothing to label | Add appropriate role or use correct element |
| Positive `tabindex` values | Breaks tab order unpredictably | Use only `0` and `-1` |
| `aria-hidden="true"` on focusable elements | Element still receives focus | Remove from tab order with `tabindex="-1"` |
| `role="presentation"` on interactive elements | Strips semantics without removing behavior | Use correct element or remove interactivity |
| Placeholder as label substitute | Disappears, fails contrast | Always use `<label>` |
| Icon-only buttons without text | No accessible name | Add `aria-label` or visually hidden text |
| Missing `lang` attribute | Screen readers use wrong language profile | Add `lang="en"` (or appropriate code) to `<html>` |
| `display:none` to hide content from all | Removes from accessibility tree | Use `visibility:hidden` or `aria-hidden` as appropriate |
