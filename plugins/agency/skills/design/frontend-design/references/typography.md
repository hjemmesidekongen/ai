# Typography System

Mathematical typographic scales for consistent, harmonious type sizing.
All values derive from a base size and a ratio — no arbitrary numbers.

## Scale Ratios

| Ratio | Name | Use Case |
|-------|------|----------|
| 1.25 | Major Third | Body-heavy layouts: blogs, documentation, long-form content |
| 1.333 | Perfect Fourth | Headline-heavy layouts: marketing, landing pages, portfolios |

Pick one ratio per project. Do not mix ratios.

## Base Size

- **Base:** 16px (1rem). This is non-negotiable — it is the browser default and
  the foundation of all rem calculations.

## Scale Steps

Computed from base and ratio. Example using 1.25 (Major Third):

| Token | Size | Calculation |
|-------|------|-------------|
| `text-xs` | 0.8rem (12.8px) | base / ratio |
| `text-sm` | 0.875rem (14px) | base / ratio^0.5 (rounded) |
| `text-base` | 1rem (16px) | base |
| `text-lg` | 1.125rem (18px) | base * ratio^0.5 (rounded) |
| `text-xl` | 1.25rem (20px) | base * ratio |
| `text-2xl` | 1.563rem (25px) | base * ratio^2 |
| `text-3xl` | 1.953rem (31.25px) | base * ratio^3 |
| `text-4xl` | 2.441rem (39.06px) | base * ratio^4 |
| `text-5xl` | 3.052rem (48.83px) | base * ratio^5 |
| `text-6xl` | 3.815rem (61.04px) | base * ratio^6 |

For 1.333 (Perfect Fourth), replace the multiplier. The token names stay the same.

## Line Heights

Line height is not a single value. It changes by context:

| Context | Line Height | Why |
|---------|-------------|-----|
| Headings (h1-h3) | 1.1 - 1.2 | Tight leading for large text — prevents visual gaps |
| Subheadings (h4-h6) | 1.2 - 1.3 | Slightly more room at smaller heading sizes |
| Body text | 1.5 - 1.75 | Optimal readability for paragraph content |
| UI elements (buttons, labels) | 1.25 | Compact but not cramped |
| Captions and small text | 1.4 - 1.5 | Small text needs proportionally more leading |

## Font Pairing

- **Maximum 2 families.** One heading font, one body font. No exceptions.
- **Heading font:** Serif or display typeface. Must have personality — this carries
  the brand voice in type.
- **Body font:** Sans-serif with excellent legibility at small sizes. Neutral enough
  to not compete with headings.
- **Fallback stacks:** Always include system font fallbacks. Example:
  `'Inter', ui-sans-serif, system-ui, -apple-system, sans-serif`

### Pairing Principles

- Contrast in structure: pair a geometric sans with a humanist serif, not two
  geometric faces.
- Match x-height: heading and body fonts should have similar x-heights so they
  feel cohesive at the same size.
- Test at body size: a heading font that looks beautiful at 48px may be unreadable
  at 14px. Verify both extremes.

## Measure (Line Length)

- **Body text:** 45-75 characters per line. 66 characters is the ideal.
- **Wide layouts:** Use `max-width: 65ch` on text containers.
- **Narrow contexts (sidebars, cards):** 30-45 characters is acceptable.
- Never let body text run full-width on large screens. Uncontrolled measure
  destroys readability.

## Vertical Rhythm

All vertical spacing derives from the base line-height unit:

- **Rhythm unit:** base font size * body line height = 16px * 1.5 = 24px
- **Paragraph spacing:** 1 rhythm unit (24px)
- **Section spacing:** 2-3 rhythm units (48-72px)
- **Component internal padding:** 0.5 or 1 rhythm unit (12px or 24px)
- **Page section gaps:** 4-6 rhythm units (96-144px)

This creates a consistent vertical grid. Every element snaps to multiples of the
rhythm unit, producing visual harmony without effort.

## Letter Spacing

- **Headings (large):** -0.02em to -0.01em (tighten — large text has natural gaps)
- **Body text:** 0 (default tracking is optimized by the type designer)
- **All caps text:** +0.05em to +0.1em (uppercase needs extra tracking to breathe)
- **Small text (<14px):** +0.01em (slight loosening improves legibility)
