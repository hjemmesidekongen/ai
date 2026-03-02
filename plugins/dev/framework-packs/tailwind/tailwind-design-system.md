---
origin: "wshobson/agents"
origin_skill: "tailwind-design-system"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "All sections — Key v4 Changes, Quick Start (@theme blocks, OKLCH tokens, dark mode), Core Concepts, all 6 Patterns (CVA variants, compound components, form components, responsive grid, native animations, dark mode), Utility Functions, Advanced v4 Patterns, v3-to-v4 migration checklist, Best Practices"
sections_removed: "Resources list"
---

# Tailwind Design System (v4)

Production-ready design systems with Tailwind CSS v4. CSS-first configuration, OKLCH tokens, CVA variants, dark mode.

> **This skill targets Tailwind CSS v4 (2024+).** For v3 projects, use `tailwind.config.ts` patterns and the v3 docs.

## Key v4 Changes

| v3 Pattern | v4 Pattern |
|------------|------------|
| `tailwind.config.ts` | `@theme` in CSS |
| `@tailwind base/components/utilities` | `@import "tailwindcss"` |
| `darkMode: "class"` | `@custom-variant dark (&:where(.dark, .dark *))` |
| `theme.extend.colors` | `@theme { --color-*: value }` |
| `require("tailwindcss-animate")` | CSS `@keyframes` inside `@theme` |

## Quick Start — CSS-First Configuration

```css
/* app.css */
@import "tailwindcss";

@theme {
  /* Semantic color tokens using OKLCH */
  --color-background: oklch(100% 0 0);
  --color-foreground: oklch(14.5% 0.025 264);
  --color-primary: oklch(14.5% 0.025 264);
  --color-primary-foreground: oklch(98% 0.01 264);
  --color-secondary: oklch(96% 0.01 264);
  --color-secondary-foreground: oklch(14.5% 0.025 264);
  --color-muted: oklch(96% 0.01 264);
  --color-muted-foreground: oklch(46% 0.02 264);
  --color-accent: oklch(96% 0.01 264);
  --color-destructive: oklch(53% 0.22 27);
  --color-border: oklch(91% 0.01 264);
  --color-ring: oklch(14.5% 0.025 264);
  --color-card: oklch(100% 0 0);
  --color-card-foreground: oklch(14.5% 0.025 264);

  /* Radius tokens */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;

  /* Animation tokens */
  --animate-fade-in: fade-in 0.2s ease-out;
  --animate-slide-in: slide-in 0.3s ease-out;

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  @keyframes slide-in {
    from { transform: translateY(-0.5rem); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
}

/* Dark mode — class-based */
@custom-variant dark (&:where(.dark, .dark *));

.dark {
  --color-background: oklch(14.5% 0.025 264);
  --color-foreground: oklch(98% 0.01 264);
  --color-primary: oklch(98% 0.01 264);
  --color-primary-foreground: oklch(14.5% 0.025 264);
  --color-muted: oklch(22% 0.02 264);
  --color-muted-foreground: oklch(65% 0.02 264);
  --color-border: oklch(22% 0.02 264);
  --color-card: oklch(14.5% 0.025 264);
}

@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground antialiased; }
}
```

## Design Token Hierarchy

```
Brand Tokens (abstract oklch values)
    └── Semantic Tokens (--color-primary, --color-muted)
        └── Component Tokens (bg-primary, text-muted-foreground)
```

Use semantic tokens in components (`bg-primary`), never raw OKLCH values.

## Pattern 1: CVA (Class Variance Authority) Components

> Note: All component examples use React 19 `ref`-as-prop pattern (no `forwardRef`). See `composition-patterns.md` for the React 19 upgrade rule.

```typescript
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-border bg-background hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'text-primary underline-offset-4 hover:underline',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
        icon: 'size-10',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
)

export function Button({
  className, variant, size, asChild = false, ref, ...props
}: ButtonProps & { ref?: React.Ref<HTMLButtonElement> }) {
  const Comp = asChild ? Slot : 'button'
  return <Comp className={cn(buttonVariants({ variant, size, className }))} ref={ref} {...props} />
}
```

## Pattern 2: Compound Components (React 19)

```typescript
// React 19: ref as regular prop, no forwardRef
export function Card({ className, ref, ...props }: React.HTMLAttributes<HTMLDivElement> & { ref?: React.Ref<HTMLDivElement> }) {
  return <div ref={ref} className={cn('rounded-lg border border-border bg-card text-card-foreground shadow-sm', className)} {...props} />
}

export function CardHeader({ className, ref, ...props }: React.HTMLAttributes<HTMLDivElement> & { ref?: React.Ref<HTMLDivElement> }) {
  return <div ref={ref} className={cn('flex flex-col space-y-1.5 p-6', className)} {...props} />
}

export function CardTitle({ className, ref, ...props }: React.HTMLAttributes<HTMLHeadingElement> & { ref?: React.Ref<HTMLHeadingElement> }) {
  return <h3 ref={ref} className={cn('text-2xl font-semibold leading-none tracking-tight', className)} {...props} />
}

export function CardContent({ className, ref, ...props }: React.HTMLAttributes<HTMLDivElement> & { ref?: React.Ref<HTMLDivElement> }) {
  return <div ref={ref} className={cn('p-6 pt-0', className)} {...props} />
}
```

## Pattern 3: Accessible Form Components

```typescript
export function Input({ className, type, error, ref, ...props }: InputProps) {
  return (
    <div className="relative">
      <input
        type={type}
        className={cn(
          'flex h-10 w-full rounded-md border border-border bg-background px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
          error && 'border-destructive focus-visible:ring-destructive',
          className
        )}
        ref={ref}
        aria-invalid={!!error}
        aria-describedby={error ? `${props.id}-error` : undefined}
        {...props}
      />
      {error && (
        <p id={`${props.id}-error`} className="mt-1 text-sm text-destructive" role="alert">
          {error}
        </p>
      )}
    </div>
  )
}
```

## Pattern 4: Responsive Grid

```typescript
const gridVariants = cva('grid', {
  variants: {
    cols: {
      1: 'grid-cols-1',
      2: 'grid-cols-1 sm:grid-cols-2',
      3: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3',
      4: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4',
    },
    gap: {
      sm: 'gap-2', md: 'gap-4', lg: 'gap-6', xl: 'gap-8',
    },
  },
  defaultVariants: { cols: 3, gap: 'md' },
})
```

## Pattern 5: Native CSS Animations (v4)

```css
/* @starting-style for entry animations — native Popover API */
[popover] {
  transition: opacity 0.2s, transform 0.2s, display 0.2s allow-discrete;
  opacity: 0;
  transform: scale(0.95);
}
[popover]:popover-open { opacity: 1; transform: scale(1); }
@starting-style {
  [popover]:popover-open { opacity: 0; transform: scale(0.95); }
}
```

```typescript
// Radix Dialog with v4 animations
<DialogPrimitive.Content
  className={cn(
    'fixed left-1/2 top-1/2 z-50 -translate-x-1/2 -translate-y-1/2 ...',
    'data-[state=open]:animate-dialog-in data-[state=closed]:animate-dialog-out'
  )}
/>
```

## Pattern 6: Dark Mode Provider

```typescript
'use client'
export function ThemeProvider({ children, defaultTheme = 'system', storageKey = 'theme' }) {
  const [theme, setTheme] = useState<Theme>(defaultTheme)

  useEffect(() => {
    const root = document.documentElement
    root.classList.remove('light', 'dark')
    const resolved = theme === 'system'
      ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
      : theme
    root.classList.add(resolved)
  }, [theme])

  return (
    <ThemeContext.Provider value={{ theme, setTheme: (t) => { localStorage.setItem(storageKey, t); setTheme(t) } }}>
      {children}
    </ThemeContext.Provider>
  )
}
```

## Utility Functions

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

## Advanced v4 Patterns

**Custom utilities with `@utility`:**
```css
@utility text-gradient {
  @apply bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent;
}
```

**Clear default colors:**
```css
@theme {
  --color-*: initial;  /* Clear all defaults */
  --color-primary: oklch(45% 0.2 260);
}
```

**Color-mix for alpha variants:**
```css
@theme {
  --color-primary-50: color-mix(in oklab, var(--color-primary) 5%, transparent);
  --color-primary-100: color-mix(in oklab, var(--color-primary) 10%, transparent);
}
```

## v3 to v4 Migration Checklist

- [ ] Replace `tailwind.config.ts` with CSS `@theme` block
- [ ] Change `@tailwind base/components/utilities` to `@import "tailwindcss"`
- [ ] Move color definitions to `@theme { --color-*: value }`
- [ ] Replace `darkMode: "class"` with `@custom-variant dark`
- [ ] Move `@keyframes` inside `@theme` blocks
- [ ] Replace `require("tailwindcss-animate")` with native CSS animations
- [ ] Update `h-10 w-10` to `size-10`
- [ ] Remove `forwardRef` (React 19 passes ref as prop)
- [ ] Use OKLCH colors for better color perception

## Best Practices

**Do:** Use `@theme` blocks, OKLCH colors, CVA for variants, `size-*` shorthand, semantic tokens

**Don't:** Use `tailwind.config.ts`, `@tailwind` directives, `forwardRef`, arbitrary values, hardcoded colors
