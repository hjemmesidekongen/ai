# Accessibility (WCAG 2.1 AA)

Minimum requirements for every project. AA is the floor, not the ceiling.
These are not optional — they are legal requirements in most jurisdictions.

## Color Contrast

| Context | Minimum Ratio | How to Measure |
|---------|--------------|----------------|
| Normal text (<18px) | 4.5:1 | Foreground color vs. background color |
| Large text (18px+ regular, 14px+ bold) | 3:1 | Same measurement, relaxed threshold |
| UI components (buttons, inputs, icons) | 3:1 | Component border/fill vs. adjacent background |
| Focus indicators | 3:1 | Focus ring color vs. adjacent colors on both sides |
| Non-text content (charts, graphs) | 3:1 | Meaningful graphical elements vs. background |

### Rules

- Measure contrast at every layer. A button with sufficient text contrast but
  insufficient border contrast still fails.
- Disabled states are exempt from contrast requirements but must still be
  visually distinguishable from enabled states.
- Do not rely on color alone to convey information. Use icons, text labels,
  or patterns alongside color (e.g., error states need an icon, not just red text).

## Focus Indicators

Every interactive element must have a visible focus indicator.

### Requirements

- **Minimum width:** 2px solid outline (or equivalent visual treatment)
- **Color:** Must contrast 3:1 against adjacent colors
- **Coverage:** Must surround the entire interactive area (no partial outlines)
- **Never remove:** `outline: none` without a custom replacement is an accessibility
  violation. If the default outline clashes with the design, replace it — do not remove it.

### Implementation

```css
/* Base focus style — applies to all interactive elements */
:focus-visible {
  outline: 2px solid var(--focus-ring);
  outline-offset: 2px;
}

/* Never do this without a replacement */
/* :focus { outline: none; }  <-- VIOLATION */
```

### Focus Ring Behavior

- Use `:focus-visible` (not `:focus`) to show focus rings only for keyboard
  navigation, not mouse clicks.
- Focus rings appear on: buttons, links, inputs, selects, textareas, checkboxes,
  radio buttons, custom interactive components.
- Focus rings must be visible in both light and dark modes.

## Keyboard Navigation

All functionality must be operable via keyboard alone.

### Requirements

- **Tab order:** Matches visual reading order (left-to-right, top-to-bottom).
  Never use `tabindex` values greater than 0 — they break natural flow.
- **All interactive elements reachable:** Every button, link, input, and custom
  control must be focusable via Tab.
- **No keyboard traps:** Pressing Tab must always move focus forward. Pressing
  Shift+Tab must always move backward. Modals must trap focus internally but
  release on close.
- **Escape key:** Closes modals, dropdowns, popovers, and overlays.
- **Arrow keys:** Navigate within composite widgets (tabs, menus, radio groups).
- **Enter/Space:** Activate buttons and links.

### Skip Navigation

Every page must have a "Skip to main content" link as the first focusable element.
It is visually hidden until focused.

```html
<a href="#main-content" class="skip-link">Skip to main content</a>
```

## Screen Readers

### Semantic HTML First

Use the correct HTML element before reaching for ARIA:

| Need | Use This | Not This |
|------|----------|----------|
| Navigation | `<nav>` | `<div role="navigation">` |
| Button | `<button>` | `<div role="button" tabindex="0">` |
| Heading | `<h1>` - `<h6>` | `<div role="heading" aria-level="1">` |
| List | `<ul>` / `<ol>` | `<div role="list">` |
| Link | `<a href="...">` | `<span onclick="...">` |

### ARIA Rules

- **First rule of ARIA:** Do not use ARIA if semantic HTML does the job.
- **aria-label:** For elements with no visible text (icon buttons, image links).
- **aria-labelledby:** To reference a visible heading as the label for a section.
- **aria-describedby:** For additional context (error messages linked to inputs).
- **aria-live:** For dynamic content that updates without page reload.
  Use `aria-live="polite"` for non-urgent updates, `aria-live="assertive"` for errors.
- **aria-hidden="true":** For purely decorative elements (icons next to text labels,
  background images). Never hide meaningful content.

### Heading Hierarchy

- One `<h1>` per page.
- Headings must not skip levels (h1 -> h3 without h2 is invalid).
- Headings create the document outline — screen reader users navigate by heading.

## Touch Targets

- **Minimum size:** 44x44px on mobile devices (WCAG) / 48x48px (Material recommended).
- **Spacing:** At least 8px between adjacent touch targets.
- The tap target includes padding — a 20px icon with 12px padding on each side
  meets the 44px requirement.
- Inline text links in paragraphs are exempt but should still have generous
  line-height (1.5+) for tap accuracy.

## Motion

- **prefers-reduced-motion:** Must be respected on all animations. See
  `references/motion.md` for implementation details.
- **No auto-playing video or animation** that lasts longer than 5 seconds without
  a pause/stop mechanism.
- **No content that flashes** more than 3 times per second.

## Text and Content

- **Resizable to 200%:** All text must remain readable and functional when the user
  zooms to 200%. No overflow, no truncation, no overlapping.
- **No text in images.** All text must be real HTML text. Logos are the only exception.
- **lang attribute:** Set on the `<html>` element. Change inline with `lang="xx"`
  for foreign phrases.
- **Page titles:** Every page must have a unique, descriptive `<title>`.
- **Link text:** Must describe the destination. "Click here" and "Read more" are
  meaningless to screen readers. Use "Read the accessibility guidelines" instead.

## Forms

- **Visible labels:** Every input must have a visible `<label>` element linked via
  `for`/`id`. Placeholder text is not a label.
- **Error messages:** Displayed near the input, linked with `aria-describedby`,
  and announced to screen readers via `aria-live`.
- **Required fields:** Indicated visually (asterisk or text) and programmatically
  (`aria-required="true"` or HTML `required`).
- **Input types:** Use appropriate types (`email`, `tel`, `url`, `number`) for
  mobile keyboard optimization.
- **Autocomplete:** Add `autocomplete` attributes for common fields (name, email,
  address) to assist autofill and assistive technology.
- **Error prevention:** For destructive or irreversible actions, provide a
  confirmation step or an undo mechanism.
