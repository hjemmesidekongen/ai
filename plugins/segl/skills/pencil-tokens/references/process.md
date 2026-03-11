# Pencil Tokens — Process Reference

## Variable Format

Pencil `set_variables` expects a flat object where each key is a variable name:

```json
{
  "variable_name": { "type": "color|string|number", "value": "<actual_value>" }
}
```

Inside `.pen` files, agents reference these as `$variable_name`.

## Mapping Algorithm

### Step 1: Read and Parse tokens.yml

Parse the YAML. The file has these top-level sections:
- `primitives` — raw color scales (50-950 per palette)
- `semantic` — intent-mapped tokens (primary, foreground, surface, etc.) + `dark` overrides
- `typography` — family, scale, weight
- `spacing` — base unit + numbered scale
- `radius` — named stops (sm through full)
- `shadow` — named elevation levels (sm through xl)

### Step 2: Resolve All References

**This step is critical.** Semantic values in tokens.yml are often YAML reference
strings like `"{primitives.color.primary.500}"` rather than resolved hex values.

Before mapping ANY value, check if it's a reference string. If so:
1. Parse the reference path (e.g., `primitives.color.primary.500`)
2. Walk the parsed YAML tree to find the target node
3. Extract the `value` field (hex string) from the target
4. Use the resolved hex, never the reference string

Pencil will reject or misinterpret unresolved reference strings.

### Step 3: Map Semantic Colors

Map ALL keys under `semantic.color.*` to Pencil color variables. Use shortened
names for common tokens:

| tokens.yml key | Pencil variable name |
|---|---|
| `primary` | `primary` |
| `primary-hover` | `primary-hover` |
| `primary-active` | `primary-active` |
| `secondary` | `secondary` |
| `accent` | `accent` |
| `accent-hover` | `accent-hover` |
| `success` | `success` |
| `warning` | `warning` |
| `error` | `error` |
| `info` | `info` |
| `background` | `bg` |
| `surface` | `surface` |
| `surface-elevated` | `surface-elevated` |
| `foreground` | `fg` |
| `foreground-secondary` | `fg-secondary` |
| `foreground-muted` | `fg-muted` |
| `border` | `border` |
| `border-strong` | `border-strong` |
| `ring` | `ring` |

**Important:** If a key exists in `semantic.color` but is not in this table,
still map it — use the key name as-is for the Pencil variable name. The table
above covers known tokens but tokens.yml may have additional semantic colors.

**Exclude:** `semantic.dark.*` — dark mode tokens are not loaded by default.

### Step 4: Map Primitive Color Highlights

Include selected primitive stops for design flexibility. Not all 10 stops per
palette — just the ones designers typically need:

- `{palette}-50` — lightest tint (backgrounds, hover states)
- `{palette}-100` — light tint (section backgrounds)
- `{palette}-900` — darkest shade (dark backgrounds, text)

Skip `-500` — already covered by semantic `primary`/`secondary`/`accent`.

Only map palettes: primary, secondary, accent, neutral. Skip status palettes
(green, amber, red) — they only have 500/600 stops (not 50/100/900), and their
anchor colors are already covered by semantic tokens (success, warning, error).

Use the `value` (hex) field, not the `oklch` field.

### Step 5: Map Typography

```json
{
  "font-heading": { "type": "string", "value": "'Lato', sans-serif" },
  "font-body": { "type": "string", "value": "'Lato', sans-serif" },
  "font-mono": { "type": "string", "value": "'JetBrains Mono', monospace" }
}
```

Source: `typography.family.heading`, `typography.family.body`, `typography.family.mono`.
Use the full value including fallback stack as stored in tokens.yml.
If a family key doesn't exist (e.g., no mono font), skip it.

### Step 6: Map Spacing

Read `spacing.scale` which uses numeric keys (1, 2, 3, ..., 24). Map to
semantic names using the scale positions:

| spacing.scale key | Pencil variable | Typical value |
|---|---|---|
| 1 | `spacing-xs` | 4px |
| 2 | `spacing-sm` | 8px |
| 4 | `spacing-md` | 16px |
| 6 | `spacing-lg` | 24px |
| 8 | `spacing-xl` | 32px |
| 12 | `spacing-2xl` | 48px |
| 16 | `spacing-3xl` | 64px |

Parse the string values to numbers (strip `px` suffix). Type: `number`.

### Step 7: Map Radius

Read `radius.*`. Map ALL named stops from tokens.yml:

| tokens.yml key | Pencil variable | Typical value |
|---|---|---|
| `sm` | `radius-sm` | 4 |
| `md` | `radius-md` | 6 |
| `lg` | `radius-lg` | 8 |
| `xl` | `radius-xl` | 12 |
| `2xl` | `radius-2xl` | 16 |
| `full` | `radius-full` | 9999 |

Parse rem values to px (1rem = 16px). Type: `number`.
Skip `none` (value 0).

### Step 8: Map Shadows

Read `shadow.*`. Map ALL named stops from tokens.yml:

| tokens.yml key | Pencil variable |
|---|---|
| `sm` | `shadow-sm` |
| `md` | `shadow-md` |
| `lg` | `shadow-lg` |
| `xl` | `shadow-xl` |

Type: `string`. Value: the CSS shadow string as-is from tokens.yml.

## Edge Cases

- **Missing section**: skip that category, warn in output. Don't fail the whole operation.
- **Unresolvable reference**: if a reference path doesn't exist in primitives, warn and skip that variable. Log the broken reference.
- **OKLCH values**: always use the `value` (hex) field, never the `oklch` field.
- **Font family format**: keep the full CSS value including fallback stack.
- **Dark mode**: excluded by default. Can be loaded separately by passing a flag or running the skill with `dark: true` context.

## Expected Variable Count

A well-formed tokens.yml should produce approximately:
- 19 semantic color variables
- 12 primitive color highlights (4 palettes × 3 stops)
- 2-3 font variables
- 5-7 spacing variables
- 5-6 radius variables
- 3-4 shadow variables
- **Total: ~50 variables**
