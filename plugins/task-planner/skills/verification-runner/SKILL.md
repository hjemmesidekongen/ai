# Verification Runner

Dispatches verification checks for completed waves. Takes a verification type and a list of checks from the plan, runs each check using the appropriate method, and returns a structured verdict.

## When This Skill Runs

1. **After each wave completes** — `plan-execute` calls this skill with the wave's `verification` block.
2. **On QA failure re-check** — After fixes are applied, the runner re-runs the failed checks.
3. **On plan resume** — `plan-resume` re-runs verification for the last in-progress wave to confirm state.

## Input

From the wave's `verification` block in the plan:

```yaml
verification:
  type: "data_validation"
  checks:
    - "brand-reference.yml colors section complete"
    - "brand-reference.yml typography section complete"
```

Plus context from the wave:
- The task list for this wave (to know which files were written)
- The plan's `verification_profile` (for profile-specific behavior)
- The working directory (brand directory, project root, etc.)

## Output

```yaml
verification_result:
  wave: 2
  type: "file_validation"
  ran_at: "2026-02-28T15:12:00Z"

  checks:
    - name: "SVG logos exist and are valid"
      status: "pass"
      details: "Found 3 SVG files in assets/logo/svg/. All valid XML with viewBox."

    - name: "Icon SVGs exist with consistent viewBox"
      status: "fail"
      details: "Found 12 icons. 2 missing viewBox attribute: arrow-right.svg, chevron-down.svg"
      fix_required: true
      suggested_fix: "Add viewBox=\"0 0 24 24\" to arrow-right.svg and chevron-down.svg"

  verdict: "fail"          # pass | fail | pass_with_warnings
  blocking_issues: 1
  warnings: 0
```

### Verdict Rules

| Condition | Verdict |
|-----------|---------|
| All checks pass | `pass` |
| All checks pass but some have non-blocking notes | `pass_with_warnings` |
| Any check has `fix_required: true` | `fail` |

A `fail` verdict blocks wave advancement. The execution engine routes the failure back to the implementing agent with the `suggested_fix`. After fixes, the runner re-checks only the failed checks.

## Dispatch Table

The runner looks up the verification type in `resources/verification-registry.yml` and dispatches to the matching method. Each method below describes what Claude does concretely.

### `data_validation` — Built-in (Claude reads and checks YAML)

Verifies that YAML data files are complete and correctly structured. This is the most common verification type — used after any wave that produces YAML output.

**Procedure:**

1. **Read the target file.** Use the Read tool to load the YAML file referenced in the check.

2. **Check required fields exist.** For each check string, identify the file and section being validated. Read that section and verify:
   - The top-level key exists
   - It is not empty (not `null`, not `""`, not `[]`, not `{}`)
   - Nested required fields are present (infer from the check description)

3. **Check value types.** Verify values match expected types:
   - Strings are non-empty strings (not just whitespace)
   - Numbers are numeric (not strings containing digits)
   - Arrays have at least one item
   - Objects have at least one key

4. **Check cross-references.** If a field references another field (e.g., a color pair references a color name from the palette), verify the referenced value exists:
   - Read the referenced section
   - Confirm the referenced key/value is present
   - Flag broken references as `fail` with the missing reference in `details`

5. **Report per check.** Each check string from the plan gets its own result entry.

**Example execution:**

```
Check: "brand-reference.yml colors section complete"

1. Read brand-reference.yml
2. Verify top-level key "colors" exists
3. Verify "colors" is not empty
4. Verify required sub-fields: primary, secondary, neutral (at minimum)
5. Verify each color has: name, hex, rgb, usage
6. Result: pass/fail with details
```

### `file_validation` — Built-in (Claude uses Glob, Read, Bash)

Verifies that expected files exist on disk and are well-formed. Used after waves that produce asset files (SVGs, PNGs, fonts, etc.).

**Procedure:**

1. **Check file existence.** For each expected file path or glob in the check:
   - Use Glob to find matching files
   - If no matches: `fail` with "Expected files not found: [pattern]"
   - If matches found: record count

2. **Check for zero-byte files.**
   ```bash
   find <directory> -type f -empty
   ```
   - If any empty files found: `fail` with file names

3. **Validate SVG files.** For each `.svg` file:
   - Read the file content
   - Verify it starts with `<svg` or `<?xml` followed by `<svg`
   - Verify a `viewBox` attribute is present on the `<svg>` element
   - Optionally check well-formed XML:
     ```bash
     xmllint --noout file.svg 2>&1
     ```
   - If `xmllint` not available, the text-based check is sufficient

4. **Validate PNG dimensions.** For each `.png` file where dimensions are specified in the check:
   - Use `file` command or `sips` (macOS) to read dimensions:
     ```bash
     sips -g pixelWidth -g pixelHeight file.png
     ```
   - Or with ImageMagick if available:
     ```bash
     identify -format "%wx%h" file.png
     ```
   - Compare against expected dimensions from the check string
   - Dimension mismatches are `fail` (not warnings)

5. **Report per check.** Each check gets a result with file counts and any issues found.

**Example execution:**

```
Check: "SVG logos exist and are valid"

1. Glob: assets/logo/svg/*.svg → found 3 files
2. Zero-byte check: none empty
3. SVG validation:
   - logo-full.svg: valid XML, has viewBox ✓
   - logo-mark.svg: valid XML, has viewBox ✓
   - logo-wordmark.svg: valid XML, missing viewBox ✗
4. Result: fail — logo-wordmark.svg missing viewBox attribute
```

### `schema_validation` — Built-in (Claude reads and validates structure)

Validates a YAML file against the expected schema. Used for final compilation steps to ensure the complete output is structurally correct.

**Procedure:**

1. **Parse YAML.** Read the target file. If it fails to parse (invalid YAML syntax), immediately `fail`:
   - Report the parse error location and message
   - No further checks needed

2. **Check required top-level sections.** Compare the file's top-level keys against the schema's required sections:
   - For `plan-schema.yml`: verify `plan.name`, `plan.tasks`, `plan.waves` all exist
   - For domain schemas (e.g., brand-reference): verify all sections listed in the schema
   - Missing sections are `fail` with the list of missing keys

3. **Validate cross-references.** Scan for internal references and verify they resolve:
   - Task ids referenced in `depends_on` must exist in the `tasks` array
   - Task ids referenced in `waves[].tasks` must exist in the `tasks` array
   - Wave numbers in `depends_on_waves` must correspond to existing waves
   - Broken references are `fail` with specifics

4. **Type check key fields.** Verify fields match their declared types from the schema:
   - `wave` is an integer
   - `parallel` is a boolean
   - `tasks` is an array
   - `status` is one of the enum values
   - Type mismatches are `fail`

5. **Report per check.** Each check from the plan gets a result.

**Example execution:**

```
Check: "brand-reference.yml validates against schema"

1. Parse: valid YAML ✓
2. Required sections: identity ✓, audience ✓, voice ✓, colors ✓,
   typography ✓, logo ✗ (missing)
3. Cross-references: all color names in pairs resolve ✓
4. Type checks: all fields correct types ✓
5. Result: fail — missing required section "logo"
```

### `accessibility_validation` — Built-in (Claude computes or reads precomputed values)

Verifies WCAG compliance for color pairs. This type is domain-specific to brand work but built into the core plugin because accessibility is universal.

**Procedure:**

1. **Read color pair data.** Load the file section containing color pairs (e.g., `brand-reference.yml#colors`).

2. **Check contrast ratios exist.** Every foreground/background pair must have a `contrast_ratio` field. Missing ratios are `fail`.

3. **Validate WCAG AA thresholds.**
   - Body text (normal): contrast ratio must be ≥ 4.5:1
   - Large text (18px+ or 14px+ bold): contrast ratio must be ≥ 3:1
   - Pairs below threshold are `fail` with the actual ratio and the suggested fix (nearest accessible alternative)

4. **Check colorblind safety.** Each primary color must have notes for:
   - Protanopia (red-blind)
   - Deuteranopia (green-blind)
   - Tritanopia (blue-blind)
   - Missing notes are `pass_with_warnings` (non-blocking)

5. **Check dark mode.** If the brand defines dark mode:
   - Verify dark mode section exists
   - Verify dark mode pairs also pass contrast checks
   - Missing dark mode when expected is `fail`

### `manual_approval` — Interactive (Claude presents to user)

Pauses execution and asks the user to review and approve.

**Procedure:**

1. **Present the output.** Show the user what was produced in this wave — file list, key content, any previews.
2. **Ask for approval.** Use AskUserQuestion with options: "Approve", "Request changes".
3. **If approved:** `pass`.
4. **If changes requested:** `fail` with the user's feedback as `suggested_fix`.

---

## Domain-Specific Types (Stubs)

These verification types are registered by consuming plugins. The verification runner recognizes them but delegates to shell commands defined by the registering plugin. They are not available until the consuming plugin is installed.

### `web_lint` — Registered by `website-builder`

Runs code style and formatting checks on generated web code.

**When available, runs:**

```bash
npx eslint . --max-warnings 0
npx prettier --check .
```

**Pass criteria:** Both commands exit 0.
**Fail behavior:** Report ESLint errors and Prettier diffs. The `suggested_fix` includes the specific files and rules violated.

**Not available until `website-builder` plugin is installed.** If this type is referenced in a plan but the plugin is not installed, the runner reports:

```yaml
- name: "web_lint"
  status: "fail"
  details: "Verification type 'web_lint' requires the website-builder plugin (not installed)"
  fix_required: false
```

### `web_build` — Registered by `website-builder`

Verifies the project builds without errors.

**When available, runs:**

```bash
npm run build
```

**Pass criteria:** Exit code 0, no TypeScript errors in output.
**Extended checks (if configured):**
- Bundle size within budget (parsed from build output or `bundlesize` config)
- No new build warnings compared to baseline

**Not available until `website-builder` plugin is installed.**

### `web_test` — Registered by `website-builder`

Runs the project's test suite.

**When available, runs:**

```bash
npm test
```

**Pass criteria:** Exit code 0, coverage meets threshold.
**Extended checks (if configured):**
- Coverage percentage parsed from output (e.g., Jest `--coverage`)
- Coverage must meet threshold defined in the plan or plugin config
- Individual file coverage below threshold is `pass_with_warnings`

**Not available until `website-builder` plugin is installed.**

### `seo_audit` — Registered by `seo-plugin`

Validates SEO requirements for generated web content.

**When available, checks:**
- All pages have unique `<title>` and `<meta name="description">`
- Every page has exactly one `<h1>`
- Structured data (JSON-LD) validates against schema.org
- `sitemap.xml` exists and lists all pages

**Not available until `seo-plugin` plugin is installed.**

---

## Error Logging to state.yml

When any check results in `status: "fail"`, the verification runner MUST log the failure to the `errors` array in state.yml. This ensures errors persist across `/compact` and session restarts.

### Logging Procedure

After producing the verification result, for each failed check:

1. **Read state.yml** to get the current `errors` array.
2. **Check for duplicates.** If an error with the same `skill` and `error` text already exists and has `result: "unresolved"`, do NOT add a duplicate. Instead, update the existing entry's `attempted_fix` and `next_approach`.
3. **Append a new error entry** (if not a duplicate):

```yaml
errors:
  - timestamp: "[ISO timestamp]"
    skill: "[current phase/skill name from state.yml]"
    error: "[check name]: [failure details from verification result]"
    attempted_fix: "[suggested_fix from the check, or 'pending' if no fix attempted yet]"
    result: "unresolved"
    next_approach: "[suggested_fix text, so the next attempt knows what to try]"
```

4. **On successful re-run**, if a previously failed check now passes, find the matching error entry and update:

```yaml
    result: "resolved"
    next_approach: null
```

### Example

A checkpoint fails for missing viewBox on an SVG:

```yaml
# Added to state.yml errors array:
errors:
  - timestamp: "2026-03-01T10:30:00Z"
    skill: "visual-identity"
    error: "Icon SVGs exist with consistent viewBox: 2 missing viewBox attribute"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "Add viewBox=\"0 0 24 24\" to arrow-right.svg and chevron-down.svg"
```

After the fix is applied and re-verification passes:

```yaml
  - timestamp: "2026-03-01T10:30:00Z"
    skill: "visual-identity"
    error: "Icon SVGs exist with consistent viewBox: 2 missing viewBox attribute"
    attempted_fix: "Added viewBox=\"0 0 24 24\" to arrow-right.svg and chevron-down.svg"
    result: "resolved"
    next_approach: null
```

---

## Error Handling

### Unknown Verification Type

If the plan references a type not in `verification-registry.yml`:

```yaml
- name: "unknown_type"
  status: "fail"
  details: "Unknown verification type 'unknown_type'. Check verification-registry.yml for available types."
  fix_required: false
```

Verdict: `pass_with_warnings` — an unknown type does not block the plan, but is flagged.

### Tool Not Available

If a verification type requires a tool that isn't installed (e.g., `xmllint`, `sips`):

- Fall back to text-based validation where possible
- Report the fallback in `details`: "xmllint not available, used text-based XML check"
- Only `fail` if no fallback exists and the check cannot be performed

### Re-Run After Fix

When the runner is called after a fix:

1. Only re-run checks that previously had `status: "fail"`
2. Keep previous `pass` results as-is
3. Produce a new verdict from the combined results
4. Maximum 3 re-run rounds before escalating to manual approval
