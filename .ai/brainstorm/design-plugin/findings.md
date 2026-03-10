# Design Plugin — Research Findings

## Steal Wholesale

### Canvas Design Philosophy (anthropics:skills)
- `external-references/anthropics:skills-main/skills/canvas-design/SKILL.md`
- Two-step: philosophy creation (aesthetic vision) → visual expression
- 75+ professional fonts in canvas-fonts/
- Emphasis on "meticulously crafted" — anti-AI-slop rules
- Use as conceptual foundation for visual identity creation

### Frontend Design Aesthetics (anthropics:skills)
- `external-references/anthropics:skills-main/skills/frontend-design/SKILL.md`
- Extreme aesthetic direction (minimalist, maximalist, retro, organic, luxury)
- Typography: distinctive display + refined body (avoid Inter/Arial)
- Motion/interaction, spatial composition, background details
- Critical: never use generic AI aesthetics (purple gradients, overused fonts)

### Color Systems — OKLCH Deep Dive
- `external-references/agents-main/plugins/ui-design/skills/visual-design-foundations/references/color-systems.md`
- Perceptually uniform scales using OKLCH
- Programmatic color scale generation with lightness stops
- Two-tier: Primitive → Semantic → Component tokens
- Dark mode CSS with data-theme
- WCAG contrast checker TypeScript functions
- Color harmony functions: complementary, triadic, analogous, split-complementary
- Colorblind simulation matrices

### Design Tokens — Comprehensive Schema
- `external-references/agents-main/plugins/ui-design/skills/design-system-patterns/references/design-tokens.md`
- Naming: `[category]-[property]-[variant]-[state]`
- CSS custom properties, Style Dictionary transforms
- Platform outputs: iOS Swift, Android XML, Web CSS/JS
- Governance: change management, deprecation, validation

### DTCG Token Template (JSON)
- `external-references/agent-toolkit-main/skills/design-system-starter/templates/design-tokens-template.json`
- W3C-compliant JSON schema
- Primitive color scales (50-950 stops), semantic colors, typography, spacing, shadows
- Component tokens referencing base tokens via `{path.to.token}`

### Tailwind Design System
- `external-references/antigravity-awesome-skills-main/skills/tailwind-design-system/SKILL.md`
- `external-references/antigravity-awesome-skills-main/skills/tailwind-design-system/resources/implementation-playbook.md`
- Token hierarchy: Brand → Semantic → Component
- CVA pattern for type-safe variants
- Dark mode with ThemeProvider, cn() utility

## Adapt

### Mobile Color System
- `external-references/antigravity-awesome-skills-main/skills/mobile-design/mobile-color-system.md`
- OLED: battery-aware, #000 vs #121212
- Semantic colors per platform (iOS vs Android)
- Dynamic Color (Material You)
- Colorblind accessibility, outdoor visibility

### Mobile Typography
- `external-references/antigravity-awesome-skills-main/skills/mobile-design/mobile-typography.md`
- System fonts: SF Pro (iOS), Roboto (Android)
- Type scales per platform, Dynamic Type
- Dark mode halation: text appears thinner, may need medium weight
- Font loading: subsetting, WOFF2, preload

### Radix UI Patterns
- `external-references/antigravity-awesome-skills-main/skills/radix-ui-design-system/SKILL.md`
- Accessibility-first: keyboard nav, screen readers, focus management
- Headless architecture, composition over configuration
- Theming: CSS Variables, Tailwind + CVA, Stitches

## Key Insights

1. Color generation must handle 3 tiers: primitives → semantic → component
2. OKLCH is the modern standard for perceptually uniform color scales
3. DTCG JSON is becoming the W3C standard for token interchange
4. Typography needs platform awareness (pt vs sp vs rem)
5. Every system needs WCAG contrast validation built in
6. "Craft" emphasis: multiple passes to avoid AI-generic output
7. Token naming convention: `[category]-[property]-[variant]-[state]`
