# Motion Design

Motion.dev (formerly Framer Motion) rules for purposeful animation.
Every animation communicates a state change. Decorative motion is anti-slop.

## Timing

Fixed duration ranges by animation category. Never exceed 500ms.

| Category | Duration | Examples |
|----------|----------|---------|
| Micro | 100-200ms | Button press, toggle switch, icon morph, tooltip show |
| Transition | 200-400ms | Tab switch, accordion expand, modal open, drawer slide |
| Entrance | 300-500ms | Page section reveal, hero animation, card stagger in |

### Rules

- If the user triggered the action, use micro timing. Feedback must feel instant.
- If the system triggered the action (route change, data load), use transition timing.
- Entrance animations happen once on first view. They are the slowest allowed.
- Never animate something the user is waiting for. Loading states should appear
  instantly — the spinner animates, not the container.

## Easing

Custom cubic-bezier curves. Do not use `ease`, `ease-in-out`, or `linear` defaults.

| Context | Cubic Bezier | Character |
|---------|-------------|-----------|
| Entrance (element appearing) | `[0.22, 1, 0.36, 1]` | Fast start, gentle settle — feels like arriving |
| Exit (element leaving) | `[0.55, 0, 1, 0.45]` | Gentle start, fast finish — feels like departing |
| Emphasis (attention pulse) | `[0.34, 1.56, 0.64, 1]` | Slight overshoot — draws the eye without being cartoonish |
| Standard (layout shift) | `[0.4, 0, 0.2, 1]` | Material-style deceleration — neutral and professional |

### Motion.dev Usage

```tsx
// Entrance
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
/>

// Exit
<motion.div
  exit={{ opacity: 0, y: -10 }}
  transition={{ duration: 0.2, ease: [0.55, 0, 1, 0.45] }}
/>
```

## Spring Physics

Interactive elements use spring dynamics instead of duration-based animation.
Springs feel responsive because they model physical behavior.

| Profile | Config | Use Case |
|---------|--------|----------|
| Snappy | `stiffness: 300, damping: 30` | Buttons, toggles, small interactive elements |
| Gentle | `stiffness: 200, damping: 25` | Cards, modals, medium-sized elements |
| Bouncy | `stiffness: 400, damping: 15` | Playful emphasis, celebratory moments only |

### Rules

- **Default to snappy** for all interactive feedback.
- **Gentle** for elements that move significant distance (>100px).
- **Bouncy** is reserved — use only when the creative direction explicitly calls for
  playful personality. Most products should never use bouncy.

```tsx
// Interactive spring
<motion.button
  whileTap={{ scale: 0.97 }}
  transition={{ type: "spring", stiffness: 300, damping: 30 }}
/>
```

## Stagger

Children of a container animate in sequence with consistent delay between each.

- **Stagger delay:** 50-80ms between children
- **Maximum children:** Stagger up to 8 items. Beyond 8, the last item waits too
  long — group remaining items or use a wave effect.
- **Direction:** Top-to-bottom or left-to-right following reading order.

```tsx
// Container stagger
<motion.ul>
  {items.map((item, i) => (
    <motion.li
      key={item.id}
      initial={{ opacity: 0, y: 15 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: i * 0.06, duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
    />
  ))}
</motion.ul>
```

## Scroll Animations

Scroll-triggered animations must be subtle and purposeful.

### Parallax

- **Maximum offset:** 10-20% of the element's height. More than 20% creates
  disorienting movement and nausea risk.
- **Apply to:** Background images, decorative elements only. Never parallax text
  or interactive elements.

### Scroll Reveal

- Use Intersection Observer (via `whileInView` in Motion.dev).
- **Trigger once:** Elements reveal on first scroll into view and stay revealed.
  Do not re-animate on scroll up.
- **Threshold:** 0.2 (element 20% visible before triggering).
- **Animation:** Fade + subtle translate (opacity 0 to 1, y 20-30px). No scale,
  no rotation, no horizontal slide for scroll reveals.

```tsx
<motion.section
  initial={{ opacity: 0, y: 24 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.2 }}
  transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
/>
```

## Reduced Motion

Non-negotiable. All animations must respect `prefers-reduced-motion`.

### Implementation

- Check the media query at the animation root level.
- When reduced motion is preferred: replace all transforms and positional animations
  with instant opacity transitions or remove animation entirely.
- Spring animations become instant (duration: 0).
- Scroll parallax is disabled completely.

```tsx
// Motion.dev handles this globally
<MotionConfig reducedMotion="user">
  {children}
</MotionConfig>
```

### What Stays in Reduced Motion

- Opacity transitions (instant or very fast, <100ms)
- Color changes (hover states, focus indicators)
- Essential state indicators (loading spinners — but simplified)

### What Gets Removed

- All positional transforms (translate, scale, rotate)
- Spring physics
- Stagger delays
- Parallax effects
- Entrance animations
