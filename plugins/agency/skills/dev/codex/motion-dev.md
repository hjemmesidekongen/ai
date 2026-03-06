# Motion.dev Conventions

Motion.dev (formerly Framer Motion) is the sole animation library for React projects. These rules are non-negotiable defaults.

## Library Exclusivity

- Motion.dev is the ONLY animation dependency permitted
- No GSAP, React Spring, anime.js, or CSS animation libraries (e.g., Animate.css)
- If a third-party package pulls in another animation lib, flag it and find an alternative
- Override requires explicit project-level exception documented in state.yml

## LazyMotion for Bundle Size

- Always wrap app root with `<LazyMotion features={domAnimation}>`
- Use `domAnimation` (~4.6KB) as the default feature set
- Only switch to `domMax` when layout animations or drag gestures are required
- Never import `motion` directly — use `m` component from LazyMotion

## AnimatePresence for Exit Animations

- Never conditionally render animated components without wrapping in `<AnimatePresence>`
- Every mount/unmount gets an `exit` prop — no exceptions
- Use `mode="wait"` for sequential transitions (one exits before next enters)
- Use `mode="sync"` only when overlapping transitions are intentional

## Spring Physics for Interactions

- Use `type: "spring"` for all interactive elements: buttons, toggles, drag, modals
- Default spring config: `stiffness: 300, damping: 30`
- Tween (`type: "tween"`) is permitted only for decorative, non-interactive animations
- Never use underdamped springs (damping < 15) for UI controls

## Easing Curves

- Entrance (ease-out): `[0.22, 1, 0.36, 1]`
- Exit (ease-in): `[0.55, 0, 1, 0.45]`
- Emphasis (overshoot): `[0.34, 1.56, 0.64, 1]`
- Never use `linear` for UI elements — linear is only for progress bars or looping decorations

## Duration Ranges

- Micro-interactions (hover, press): 100-200ms
- Component transitions (expand, slide): 200-400ms
- Page/section entrances: 300-500ms
- Hard ceiling: 500ms — never exceed for any UI animation
- Stagger children: 50-80ms offset via `staggerChildren`

## prefers-reduced-motion

- Always call `useReducedMotion()` in animated components
- When reduced motion is active: replace animations with instant state changes or opacity-only fades (duration <100ms)
- Never skip this check — wrap every animated component
- Test with `(prefers-reduced-motion: reduce)` enabled in devtools

## Layout Animations

- Use `layout` prop for shared layout transitions within a component
- Use `layoutId` for cross-component element animations (e.g., tab indicators)
- Avoid `layout` on large DOM trees (>50 elements) — isolate with `layoutScroll` or `layoutRoot`
- Pair with `AnimatePresence` when layout-animated elements mount/unmount

## Declarative API

- Co-locate animation state with components via `initial`, `animate`, `exit` props
- Define reusable variants as named objects outside the component
- No imperative `.start()` or `controls.start()` unless orchestrating multi-step sequences
- Prefer `whileHover`, `whileTap`, `whileDrag` over manual event-driven animations
