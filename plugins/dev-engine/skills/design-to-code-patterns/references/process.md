# Design to Code Patterns — Detailed Reference

## Token Extraction Workflow

When starting from a design file (Figma, Sketch, Pen):

### Step 1: Extract Color Palette
- Identify all unique colors in the design
- Organize into 10-step scales per hue (50, 100, 200, ... 900, 950)
- Map to semantic roles: primary, secondary, neutral, error, warning, success, info
- Create CSS custom properties:
```css
:root {
  --color-primary-50: #eff6ff;
  --color-primary-500: #3b82f6;
  --color-primary-900: #1e3a8a;
  /* Semantic */
  --color-text-primary: var(--color-neutral-900);
  --color-bg-surface: var(--color-neutral-50);
  --color-border: var(--color-neutral-200);
}
```

### Step 2: Extract Typography
- List all font sizes used in the design
- Map to a scale with semantic names
- Note font families, weights, line-heights, letter-spacing
```css
:root {
  --font-family-sans: 'Inter', system-ui, sans-serif;
  --font-family-mono: 'JetBrains Mono', monospace;
  --text-xs: 0.75rem;    /* 12px, line-height: 1rem */
  --text-sm: 0.875rem;   /* 14px, line-height: 1.25rem */
  --text-base: 1rem;     /* 16px, line-height: 1.5rem */
  --text-lg: 1.125rem;   /* 18px, line-height: 1.75rem */
  --text-xl: 1.25rem;    /* 20px, line-height: 1.75rem */
  --text-2xl: 1.5rem;    /* 24px, line-height: 2rem */
  --text-3xl: 1.875rem;  /* 30px, line-height: 2.25rem */
  --text-4xl: 2.25rem;   /* 36px, line-height: 2.5rem */
}
```

### Step 3: Extract Spacing
- Measure all padding, margin, and gap values
- Snap to the 4px base scale
- Create spacing tokens
```css
:root {
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-5: 1.25rem;  /* 20px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-10: 2.5rem;  /* 40px */
  --space-12: 3rem;    /* 48px */
  --space-16: 4rem;    /* 64px */
  --space-20: 5rem;    /* 80px */
  --space-24: 6rem;    /* 96px */
}
```

### Step 4: Extract Other Tokens
```css
:root {
  /* Border radius */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);

  /* Breakpoints (reference, not CSS vars) */
  /* sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px */
}
```

## Component Decomposition from Design

### Reading Order
1. **Page level**: identify major sections (hero, features, pricing, footer)
2. **Section level**: identify repeating groups (cards, list items, grid cells)
3. **Group level**: identify elements within groups (icon, title, description, button)
4. **Element level**: identify atomic elements (text, image, badge, avatar)

### Component Mapping Rules
| Design Pattern | Component Pattern |
|---------------|------------------|
| Repeated group with same structure | Map component with props for content |
| Same element with visual variants | Single component with `variant` prop |
| Flexible content area | Use `children` or slot pattern |
| Conditional elements | Boolean props (`showIcon`, `showBadge`) |
| Size variations | `size` prop (sm, md, lg) |

### Example: Card Component
Design shows a card with:
- Optional image at top
- Title (always present)
- Description (optional)
- Tags (0-3)
- CTA button (always present)

```tsx
interface CardProps {
  image?: string;
  title: string;
  description?: string;
  tags?: string[];
  ctaLabel: string;
  ctaHref: string;
  variant?: 'default' | 'featured';
}
```

### Naming Convention
- Component names match design system naming (PascalCase)
- Props match design variant names
- CSS classes use design token names
- File structure mirrors design hierarchy

## Responsive Grid Patterns

### Standard Grid
```
Mobile (< 640px):   4 columns, 16px gutter, 16px margin
Tablet (640-1024):  8 columns, 24px gutter, 32px margin
Desktop (> 1024):   12 columns, 24px gutter, auto margin (max-width container)
```

### Common Layouts
| Pattern | Mobile | Tablet | Desktop |
|---------|--------|--------|---------|
| Feature grid | 1 col | 2 col | 3 col |
| Sidebar + content | Stack | Stack | 3+9 col |
| Hero + image | Stack | Side-by-side | Side-by-side |
| Footer links | Stack | 2 col | 4 col |
| Pricing cards | 1 col | 2 col | 3 col |

### Implementation
```css
.grid {
  display: grid;
  gap: var(--space-6);
  grid-template-columns: 1fr;
}

@media (min-width: 640px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
}

@media (min-width: 1024px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
```

## Dark Mode Implementation

### Token Swapping (Recommended)
```css
:root {
  --color-bg: var(--color-white);
  --color-text: var(--color-neutral-900);
  --color-border: var(--color-neutral-200);
}

.dark {
  --color-bg: var(--color-neutral-950);
  --color-text: var(--color-neutral-50);
  --color-border: var(--color-neutral-800);
}
```

### Rules
- Swap semantic tokens, never palette values
- Dark mode is not inverted light mode — adjust for contrast and visual weight
- Shadows become less visible in dark mode — increase opacity or use borders
- Reduce image brightness slightly in dark mode (`filter: brightness(0.9)`)
- Test contrast ratios in both modes (4.5:1 WCAG AA)

## Design Handoff Checklist

### Before Starting Code
- [ ] All design tokens extracted (colors, typography, spacing, shadows, radii)
- [ ] Responsive designs provided for mobile, tablet, desktop
- [ ] Component states defined (default, hover, focus, active, disabled, error)
- [ ] Interactive behaviors documented (animations, transitions, loading states)
- [ ] Content edge cases noted (empty states, long text, missing images)

### During Implementation
- [ ] All values reference tokens, no hardcoded numbers
- [ ] Components match design naming
- [ ] Responsive behavior matches at each breakpoint
- [ ] All states implemented
- [ ] Touch targets are 44px minimum
- [ ] Contrast ratios meet WCAG AA (4.5:1 text, 3:1 UI)

### After Implementation
- [ ] Visual comparison at each breakpoint
- [ ] Dark mode works correctly (if applicable)
- [ ] Interactions match spec (hover, focus, transitions)
- [ ] Edge cases handled (empty, overflow, loading)
- [ ] Component API matches design variants

## Common Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Hardcoded `#3b82f6` throughout | Use `var(--color-primary-500)` |
| `padding: 13px` | Snap to scale: `var(--space-3)` (12px) or `var(--space-4)` (16px) |
| `font-size: 15px` | Use nearest scale value: `var(--text-sm)` (14px) or `var(--text-base)` (16px) |
| `@media (max-width: 800px)` | Use named breakpoint: `@media (min-width: 768px)` (mobile-first) |
| Component named `BigBlueCard` | Name by function: `FeatureCard variant="primary"` |
| Pixel-perfect at one size, broken at others | Design with fluid spacing and container queries |
