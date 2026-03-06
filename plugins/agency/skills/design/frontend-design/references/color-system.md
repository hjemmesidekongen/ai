# Color System

Structured color architecture. Every color in the system has a role.
Raw hex values never appear in component code — only tokens.

## Architecture

Two palette types, always present:

1. **Base palette** — Neutral scale for structure (backgrounds, borders, text)
2. **Accent palette** — Brand colors for identity (primary, secondary, optional tertiary)

Plus **semantic colors** for universal meanings (success, error, warning, info).

## Neutral Scale

A 10-step grayscale from near-white to near-black. Each step has a defined role:

| Step | Token | Role |
|------|-------|------|
| 50 | `neutral-50` | Page background, lightest surface |
| 100 | `neutral-100` | Card backgrounds, raised surfaces |
| 200 | `neutral-200` | Borders, dividers, subtle separators |
| 300 | `neutral-300` | Disabled states, inactive borders |
| 400 | `neutral-400` | Placeholder text, tertiary content |
| 500 | `neutral-500` | Secondary text, icons |
| 600 | `neutral-600` | Primary body text (light backgrounds) |
| 700 | `neutral-700` | Strong body text, headings on light backgrounds |
| 800 | `neutral-800` | High-emphasis text, dark surfaces |
| 900 | `neutral-900` | Maximum contrast text, darkest surface |

The neutral scale does not have to be pure gray. Warm neutrals (hint of yellow/brown)
or cool neutrals (hint of blue) add personality. Choose one temperature and apply
it consistently.

## Accent Colors

Each accent color gets its own 10-step scale (50-900), derived from the brand's
primary color:

- **Primary:** The dominant brand color. Used for CTAs, active states, links, and
  key interactive elements. This is the color users associate with the product.
- **Secondary:** A complementary color for supporting elements — secondary buttons,
  tags, highlights, section accents. Must contrast with primary.
- **Tertiary (optional):** Only add if the brand genuinely uses three colors. Most
  products need only primary and secondary. A forced tertiary dilutes the palette.

### Generating Accent Scales

From a single brand color (e.g., primary-500):
- Steps 50-200: progressively desaturate and lighten (tints for backgrounds)
- Steps 300-400: softer versions for hover states and subtle fills
- Step 500: the source brand color
- Steps 600-700: darken for text-on-light and active states
- Steps 800-900: deep shades for dark mode surfaces or high-emphasis use

## Semantic Colors

Always present regardless of brand. These carry universal meaning:

| Token | Color Family | Use |
|-------|-------------|-----|
| `success` | Green | Confirmations, completed states, positive feedback |
| `warning` | Amber | Cautions, pending states, attention needed |
| `error` | Red | Errors, destructive actions, validation failures |
| `info` | Blue | Informational messages, tips, neutral highlights |

Each semantic color gets a mini-scale: `{semantic}-50` (background tint),
`{semantic}-500` (default), `{semantic}-700` (text on light backgrounds).

## Contrast Requirements (WCAG 2.1 AA)

These are minimums, not targets. Exceed them.

| Context | Minimum Ratio |
|---------|--------------|
| Normal text (<18px) | 4.5:1 |
| Large text (18px+ or 14px bold) | 3:1 |
| UI components and graphical objects | 3:1 |
| Focus indicators | 3:1 against adjacent colors |

### Practical Rules

- Body text: use `neutral-600` or darker on `neutral-50`/`neutral-100` backgrounds.
- Never place `neutral-400` text on `neutral-100` — it will fail contrast.
- Primary accent on white: verify the 500 step passes 4.5:1. Many brand blues and
  greens fail. Use 600 or 700 for text, keep 500 for large UI elements only.
- Test every combination. Do not assume — measure.

## Dark Mode

Dark mode is not "invert the colors." It is a semantic token remap:

| Light Mode | Dark Mode |
|------------|-----------|
| `neutral-50` (background) | `neutral-900` (background) |
| `neutral-100` (surface) | `neutral-800` (surface) |
| `neutral-200` (border) | `neutral-700` (border) |
| `neutral-700` (text) | `neutral-200` (text) |
| `primary-500` (accent) | `primary-400` (accent — lighter for dark backgrounds) |

### Dark Mode Rules

- Design in both modes simultaneously. Never retrofit dark mode.
- Reduce accent saturation by 10-15% in dark mode — vivid colors on dark backgrounds
  cause eye strain.
- Shadows become less visible on dark backgrounds. Replace with subtle border or
  lighter surface color for elevation.
- Test contrast in dark mode separately — ratios change when backgrounds darken.

## Token Usage

Components reference semantic tokens, never raw values:

```
CORRECT:  color: var(--text-primary)       /* resolves per theme */
WRONG:    color: #1a1a1a                    /* breaks in dark mode */

CORRECT:  background: var(--surface-raised) /* adapts to context */
WRONG:    background: var(--neutral-100)    /* light-mode assumption */
```

The token layer is the contract between design and code. Change a token value
once, and every component updates. Change a hex value, and you hunt through
every file.
