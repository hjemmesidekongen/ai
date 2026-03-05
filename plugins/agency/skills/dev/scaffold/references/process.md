# Scaffold — Detailed Process

## Prerequisites

Before starting, verify both dependencies are complete in state.yml:
- `config-generator` status = `completed` — dev-config.yml must exist
- `design-tokens` status = `completed` — tailwind.config.json and variables.css must exist

If either is missing, report `status: blocked` and stop.

---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/{skill-name}-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` — actionable suggestion for the skill/pipeline (if any)
- `design_decision` — lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED — Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---


## Step 1: Read dev-config.yml

Read `.ai/projects/[name]/dev/dev-config.yml`. Extract:

```yaml
framework:
  runtime: [next, react, vite, ...]   # primary framework
  language: typescript | javascript
  package_manager: npm | yarn | pnpm | bun

paths:
  app_root: "."                        # project root
  src_dir: "src"                       # or "app" for Next.js app router

commands:
  build: "next build"
  dev: "next dev"

design_tokens:
  tailwind_config: ".ai/projects/[name]/design/tokens/tailwind.config.json"
  variables_css: ".ai/projects/[name]/design/tokens/variables.css"
```

If `design_tokens` paths are null, fall back to:
- `.ai/projects/[name]/design/tokens/tailwind.config.json`
- `.ai/projects/[name]/design/tokens/variables.css`

**Save to findings.md after this step.**

---

## Step 2: Read Design Tokens

Read both token files extracted in Step 1.

**tailwind.config.json** — contains the Tailwind theme extension object:
```json
{
  "theme": {
    "extend": {
      "colors": { "brand": { "primary": "#2563EB", ... } },
      "fontFamily": { "sans": ["Inter", "sans-serif"] },
      "spacing": { ... },
      "borderRadius": { ... }
    }
  }
}
```

**variables.css** — contains the :root block with CSS custom properties:
```css
:root {
  --color-brand-primary: #2563EB;
  --font-sans: 'Inter', sans-serif;
  --spacing-4: 1rem;
}
```

If either file is missing, log to state.yml errors and stop with `status: blocked`.

**Save to findings.md after this step.**

---

## Step 3: Generate tailwind.config.ts

Create `{app_root}/tailwind.config.ts`. The content path pattern varies by framework.

### Next.js (app router)
```typescript
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      // [INSERT FULL THEME OBJECT FROM tailwind.config.json]
    },
  },
  plugins: [],
};

export default config;
```

### Vite / Generic React
```typescript
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      // [INSERT FULL THEME OBJECT FROM tailwind.config.json]
    },
  },
  plugins: [],
};

export default config;
```

**Merge rule:** Copy the `theme.extend` object from tailwind.config.json verbatim into the config. Do not transform key names — preserve the exact structure from the design tokens file.

**Save to findings.md after writing this file.**

---

## Step 4: Generate tokens.css

Create `{src_dir}/styles/tokens.css`. Copy the contents of variables.css verbatim.
Add a header comment:

```css
/* Design tokens — auto-generated from brand-reference.yml */
/* Do not edit directly. Re-run /agency:design tokens to regenerate. */

/* [PASTE variables.css CONTENT HERE] */
```

---

## Step 5: Generate globals.css

### Next.js (app router) — `app/globals.css`
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@import "./tokens.css";

@layer base {
  :root {
    --background: var(--color-neutral-50, #f9fafb);
    --foreground: var(--color-neutral-900, #111827);
  }

  .dark {
    --background: var(--color-neutral-900, #111827);
    --foreground: var(--color-neutral-50, #f9fafb);
  }

  * {
    border-color: var(--color-neutral-200, #e5e7eb);
  }

  body {
    background-color: var(--background);
    color: var(--foreground);
    font-family: var(--font-sans, ui-sans-serif, system-ui, sans-serif);
  }
}
```

For Next.js, place `globals.css` in `app/` and `tokens.css` in `app/` as well.
Update the import path accordingly: `@import "./tokens.css"`.

### Vite / Generic — `src/styles/globals.css`
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@import "./tokens.css";

@layer base {
  /* [same base layer as above] */
}
```

**CSS @import placement:** The `@import` statement must come before `@layer` rules
to satisfy PostCSS. If using PostCSS with `postcss-import`, the import will be
inlined at build time.

**Save to findings.md after writing these files.**

---

## Step 6: Set Up src/components/ui/

### Directory structure to create:
```
src/
  components/
    ui/
      index.ts          ← barrel file (required)
      Button.tsx        ← reference component using design tokens
      Button.test.tsx   ← minimal smoke test (optional, create if test command exists)
```

### index.ts — barrel file
```typescript
export { Button } from "./Button";
```

### Button.tsx — reference component

Use design token CSS variables (not raw hex values) so the component respects
the token system. Language: TypeScript if `conventions.language = typescript`,
otherwise JavaScript.

```typescript
import { type ButtonHTMLAttributes, forwardRef } from "react";

type Variant = "primary" | "secondary" | "ghost";
type Size = "sm" | "md" | "lg";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
}

const variantClasses: Record<Variant, string> = {
  primary: "bg-brand-primary text-white hover:bg-brand-primary/90",
  secondary: "bg-brand-secondary text-white hover:bg-brand-secondary/90",
  ghost: "bg-transparent text-brand-primary hover:bg-brand-primary/10",
};

const sizeClasses: Record<Size, string> = {
  sm: "px-3 py-1.5 text-sm",
  md: "px-4 py-2 text-base",
  lg: "px-6 py-3 text-lg",
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", size = "md", className = "", ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={[
          "inline-flex items-center justify-center rounded font-medium",
          "transition-colors focus-visible:outline-none focus-visible:ring-2",
          "focus-visible:ring-brand-primary disabled:opacity-50 disabled:pointer-events-none",
          variantClasses[variant],
          sizeClasses[size],
          className,
        ].join(" ")}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";
```

**Token class names:** Use the Tailwind class names that match the keys from
tailwind.config.json. For example if tokens define `colors.brand.primary`, the
Tailwind class is `bg-brand-primary`. If the color key differs, adjust the
class names to match actual token keys.

**Save to findings.md after writing these files.**

---

## Step 7: Verify the Scaffold

Run the project's build command from dev-config.yml:

```bash
cd {app_root} && {commands.build}
```

**On success:** Note in findings.md that the build passes. Update state.yml:
- `scaffold.status = completed`
- `scaffold.build_verified = true`

**On failure:** Diagnose the error. Common issues:

| Error | Fix |
|-------|-----|
| `tailwind.config.ts` not found | Verify file was written to correct app_root |
| CSS @import parse error | Move @import before @layer blocks |
| Unknown Tailwind class | Check token key names match tailwind.config.json |
| TypeScript error in Button.tsx | Adjust ButtonHTMLAttributes import, remove forwardRef if not available |
| Module not found | Check that globals.css is imported in layout.tsx (Next.js) or main.tsx (Vite) |

Attempt one fix per error. Log each fix to state.yml errors array. If build
still fails after one fix attempt, report `status: failed` with the error.

---

## Framework-Specific Notes

### Next.js app router
- `globals.css` goes in `app/` — imported in `app/layout.tsx`
- Check if `app/layout.tsx` already imports a globals.css — if so, replace
  that file rather than creating a new one
- Next.js resolves `@import` in CSS files automatically

### Next.js pages router
- `globals.css` goes in `styles/` — imported in `pages/_app.tsx`
- `tokens.css` goes in `styles/` as well

### Vite
- `globals.css` goes in `src/styles/` — imported in `src/main.tsx`
- Check if `src/main.tsx` imports any CSS — avoid duplicating global styles

### Generic / unknown framework
- Use `src/styles/` for both files
- Document the import location in findings.md for the dev team

---

## Checkpoint Verification

After completing all steps, verify each checkpoint check:

1. **tailwind_config_exists** — Read `{app_root}/tailwind.config.ts`. Confirm it
   exists and contains the `colors` key from design tokens.

2. **globals_css_imports_tokens** — Read globals.css. Confirm it contains all
   three `@tailwind` directives and the `@import "./tokens.css"` line.

3. **component_dir_exists** — Glob for `src/components/ui/index.ts`. Confirm it
   exists and exports at least one component.

4. **build_passes** — Run build command. Confirm exit code is 0.

All 4 checks must pass. If any fail, fix and re-run that check before reporting
completion.

---

## Findings.md Template

Append this section to `.ai/projects/[name]/dev/findings.md`:

```markdown
## Scaffold

**Status:** completed
**Framework:** {framework}
**App root:** {app_root}

### Files Written
- `{app_root}/tailwind.config.ts` — {token count} color tokens, {font count} font families
- `{app_root}/src/styles/tokens.css` — {variable count} CSS custom properties
- `{app_root}/src/styles/globals.css` — Tailwind directives + token import
- `{app_root}/src/components/ui/index.ts` — barrel file
- `{app_root}/src/components/ui/Button.tsx` — reference component

### Build Result
- Command: `{build_command}`
- Result: passed / failed
- Notes: {any warnings or issues}

### Decisions
- {Any decisions made, e.g. "Used app/ instead of src/ for Next.js app router"}
```

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
