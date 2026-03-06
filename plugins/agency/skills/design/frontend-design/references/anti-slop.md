# Anti-Slop Rules

Design quality enforcement. These are hard rules, not guidelines.
Violating any of these produces generic, forgettable interfaces.

## Layout

- **No generic hero sections with stock gradients.** Every hero must have a clear
  visual concept tied to the brand narrative. A gradient is not a concept.
- **No centered-everything layouts.** Center alignment is a choice, not a default.
  Use intentional asymmetry — left-align body text, offset headings, vary column widths.
- **No cookie-cutter card grids.** If you have 6 cards in a 3x2 grid with identical
  sizing, you have a spreadsheet. Vary rhythm: feature one card large, stagger rows,
  mix horizontal and vertical orientations.
- **Whitespace is structural, not filler.** Every gap must create grouping, separation,
  or breathing room with intent. If you cannot explain why a space exists, remove it.

## Visual Treatment

- **No decorative elements without purpose.** Every shape, line, icon, and illustration
  must serve communication. Floating circles and abstract blobs are not design.
- **No default shadows or borders.** Every visual effect must be intentional.
  Box shadows from a UI kit applied uniformly across all cards is slop. Choose:
  does this element need elevation? If yes, how much and why?
- **Color usage must be strategic.** Color draws attention. If everything is colorful,
  nothing stands out. Use color to create hierarchy: primary action gets brand color,
  secondary gets neutral, destructive gets red. That is it.

## Typography

- **Typography hierarchy must be visually distinct.** Changing font size from 18px to
  20px is not hierarchy. Distinct hierarchy uses weight, case, spacing, color, or
  font family changes — not just incremental size bumps.
- **Never use more than 2 font families.** One for headings (serif or display),
  one for body (sans-serif). A third font is a sign of indecision.

## Motion

- **No animations without purpose.** Every motion must communicate a state change:
  element entering, leaving, expanding, collapsing, loading, or confirming.
  Hover animations that just "look nice" are decorative motion — that is slop.
- **No animation longer than 500ms.** If your transition takes longer than half a
  second, the user is waiting for your design instead of using the product.

## Component Variation

- **Same component type must not look identical across pages.** A testimonial card on
  the homepage and a testimonial card on the about page should share DNA but differ
  in presentation. Identical repetition signals copy-paste, not design.
- **Avoid component libraries out-of-the-box.** Untitled UI is the default starting
  point, but every component must be adapted to the project's creative direction.
  Default props and default spacing produce default-looking products.

## The Test

Before shipping any UI section, ask: "Could this section belong to any other product?"
If yes, it is slop. Every section must carry the specific brand's voice, color intent,
typographic personality, and spatial rhythm.
