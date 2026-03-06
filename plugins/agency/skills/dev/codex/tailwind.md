# Tailwind CSS Conventions

## cn() for Class Merging

Always use `cn()` (clsx + tailwind-merge) for conditional classes. Import from `@/lib/utils`. Never concatenate class strings manually.

```tsx
// Correct
<div className={cn("flex gap-4", isActive && "bg-primary", className)} />

// Wrong — string concatenation breaks merge logic
<div className={`flex gap-4 ${isActive ? "bg-primary" : ""}`} />
```

## No @apply

Never use `@apply` in CSS files. Extract a component instead. The only exception is base-layer resets in `globals.css`.

## Token-Only Spacing

Use Tailwind's spacing scale exclusively: `p-4`, `gap-6`, `mt-8`. No arbitrary values like `p-[13px]` or `gap-[22px]`. If the design needs a non-standard value, use the closest token.

## No Magic Numbers

No arbitrary values for colors, sizes, or breakpoints. Use design tokens from the Tailwind config. If a custom value is genuinely needed, define it as a named token in `tailwind.config.ts`:

```ts
// tailwind.config.ts
theme: {
  extend: {
    spacing: { "header": "4.5rem" },
    colors: { "brand": "hsl(var(--brand))" },
  },
}
```

## Responsive Mobile-First

Write mobile styles first, then layer breakpoints upward: `sm:`, `md:`, `lg:`, `xl:`. Never write desktop-first with smaller-screen overrides.

```tsx
// Correct — mobile first
<div className="flex flex-col md:flex-row lg:gap-8" />

// Wrong — desktop first with mobile overrides
<div className="flex flex-row md:flex-col" />
```

## Dark Mode

Use the `dark:` variant with CSS custom properties. Define colors as CSS variables toggled by a class on `<html>`. Never hardcode dark values inline.

```css
/* globals.css */
:root { --background: 0 0% 100%; }
.dark { --background: 0 0% 4%; }
```

```tsx
<div className="bg-background text-foreground" />
```

## Class Organization Order

Order classes consistently: layout > spacing > sizing > typography > colors > borders > effects.

```tsx
<div className="flex items-center gap-4 w-full text-sm text-muted-foreground border-b shadow-sm" />
//               layout          spacing sizing typography  colors         borders effects
```

## No Inline Styles

Use Tailwind classes exclusively. The `style` attribute is only acceptable for truly dynamic values — CSS custom properties or calculated positions that cannot be expressed as utilities.
