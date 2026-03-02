---
origin: "vercel-labs/agent-skills"
origin_skill: "composition-patterns"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "architecture-compound-components, architecture-avoid-boolean-props, react19-no-forwardref. Condensed to single reference per findings.md."
sections_removed: "state-decouple-implementation, state-context-interface, state-lift-state, patterns-explicit-variants, patterns-children-over-render-props (out of scope for condensed reference)"
---

# React Composition Patterns

Compound components and boolean prop rule. Source: Vercel Engineering.

> See also: `tailwind-design-system.md` for production CVA component examples (Button, Card, Input) that apply these patterns with Tailwind v4.

## When to Apply

- Component has many boolean props (`isOpen`, `hasIcon`, `withBorder`…)
- Building reusable component libraries
- Designing flexible component APIs

## Rule: Avoid Boolean Props (HIGH)

**Problem:** Boolean props multiply combinatorially. 5 boolean props = 32 possible states, most impossible or nonsensical.

```typescript
// ❌ Boolean prop explosion
<Button
  isPrimary
  isLarge
  hasIcon
  isLoading
  isDisabled
/>

// ✅ Explicit variants via CVA or union types
<Button variant="primary" size="large" state="loading" />
```

**Pattern — explicit variant components:**
```typescript
// Instead of <Button isPrimary> and <Button isSecondary>
export function PrimaryButton(props: ButtonProps) {
  return <Button {...props} className={cn('bg-primary text-white', props.className)} />
}

export function SecondaryButton(props: ButtonProps) {
  return <Button {...props} className={cn('bg-secondary', props.className)} />
}
```

## Rule: Compound Components (HIGH)

**Problem:** A single component with many props becomes a "god component" that's hard to customize.

**Pattern:** Split into a parent (context provider) and named sub-components (consumers).

```typescript
// ❌ God component
<Modal
  title="Confirm"
  description="Are you sure?"
  primaryButtonText="Yes"
  secondaryButtonText="No"
  onPrimary={handleYes}
  onSecondary={handleNo}
  showCloseButton
  closeOnBackdrop
/>

// ✅ Compound component — compose only what you need
<Modal>
  <Modal.Header>
    <Modal.Title>Confirm</Modal.Title>
    <Modal.CloseButton />
  </Modal.Header>
  <Modal.Body>Are you sure?</Modal.Body>
  <Modal.Footer>
    <Button variant="secondary" onClick={handleNo}>No</Button>
    <Button variant="primary" onClick={handleYes}>Yes</Button>
  </Modal.Footer>
</Modal>
```

**Implementation:**
```typescript
// context shared between parent and children
const ModalContext = createContext<ModalContextType | null>(null)

function useModal() {
  const ctx = useContext(ModalContext)
  if (!ctx) throw new Error('useModal must be used within Modal')
  return ctx
}

// Parent sets up context
function Modal({ children, onClose }: ModalProps) {
  return (
    <ModalContext.Provider value={{ onClose }}>
      <div role="dialog" aria-modal="true">
        {children}
      </div>
    </ModalContext.Provider>
  )
}

// Children consume context
Modal.CloseButton = function CloseButton() {
  const { onClose } = useModal()
  return <button onClick={onClose} aria-label="Close">×</button>
}

Modal.Header = function Header({ children }: { children: React.ReactNode }) {
  return <div className="modal-header">{children}</div>
}

// Attach sub-components
export { Modal }
```

## React 19: No forwardRef

React 19 passes `ref` as a regular prop. Remove `forwardRef` wrappers.

```typescript
// ❌ React 18 pattern
const Input = forwardRef<HTMLInputElement, InputProps>((props, ref) => {
  return <input ref={ref} {...props} />
})

// ✅ React 19 pattern — ref is just a prop
function Input({ ref, ...props }: InputProps & { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />
}
```

Also: use `use()` instead of `useContext()` in React 19:
```typescript
// ✅ React 19
import { use } from 'react'
const value = use(MyContext)
```
