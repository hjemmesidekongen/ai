/**
 * Example: CVA button component with Tailwind v4
 * Pack: tailwind
 * Tags: tailwind, cva, component
 *
 * Demonstrates class-variance-authority for type-safe variant props,
 * and Tailwind v4 CSS custom property tokens (OKLCH color system).
 */

import { cva, type VariantProps } from 'class-variance-authority'
import { forwardRef } from 'react'

// CVA variant definition — types are inferred automatically
const buttonVariants = cva(
  // Base styles applied to every button
  'inline-flex items-center justify-center gap-2 rounded-[--radius-md] font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[--color-ring] disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        primary:
          'bg-[--color-primary] text-[--color-primary-foreground] hover:bg-[--color-primary]/90',
        secondary:
          'bg-[--color-secondary] text-[--color-secondary-foreground] hover:bg-[--color-secondary]/80',
        destructive:
          'bg-[--color-destructive] text-white hover:bg-[--color-destructive]/90',
        outline:
          'border border-[--color-border] bg-transparent hover:bg-[--color-accent] hover:text-[--color-accent-foreground]',
        ghost:
          'hover:bg-[--color-accent] hover:text-[--color-accent-foreground]',
        link: 'text-[--color-primary] underline-offset-4 hover:underline',
      },
      size: {
        sm: 'h-8 px-3 text-xs',
        md: 'h-9 px-4 text-sm',
        lg: 'h-10 px-6 text-base',
        icon: 'h-9 w-9',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  },
)

// Props type — combines HTML button attrs with CVA variant props
export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  isLoading?: boolean
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, isLoading, children, disabled, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={buttonVariants({ variant, size, className })}
        disabled={disabled || isLoading}
        aria-busy={isLoading}
        {...props}
      >
        {isLoading && (
          <svg
            className="h-4 w-4 animate-spin"
            viewBox="0 0 24 24"
            fill="none"
            aria-hidden="true"
          >
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
          </svg>
        )}
        {children}
      </button>
    )
  },
)

Button.displayName = 'Button'

export { buttonVariants }
