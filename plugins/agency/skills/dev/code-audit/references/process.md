# Code Audit -- Detailed Process

## Overview

The code audit skill scans an existing codebase to discover actual coding
conventions and patterns. It samples 50-100 representative files, analyzes
six convention categories, flags inconsistencies, and produces a
project-conventions.yml file. The user reviews and confirms canonical
patterns -- the output is NEVER auto-applied.

## Prerequisites

Before starting, verify:
1. `.ai/profiles/{profile}.yml` exists and is readable
2. `.ai/projects/{project}/dev/findings.md` exists with scan results
3. Project has source files to analyze (not a greenfield project)

If findings.md is missing, report error and suggest running project-scanner first.

## Step 0: Profile Check

```
Read .ai/profiles/{profile}.yml
Check code_audit flag:
  if code_audit == false:
    Log: "Code audit skipped -- disabled in profile {profile}"
    Exit skill with status: skipped
  if code_audit == true:
    Continue to Step 1
  if code_audit not set:
    Default based on profile type:
      work → true (proceed)
      personal → false (skip)
```

## Step 1: Build File Sample

Select 50-100 representative source files from the project.

```
Read findings.md for project structure (src_root, key_directories)

Sampling strategy:
  1. Glob for source files: **/*.{ts,tsx,js,jsx,vue,svelte,py,go,rs}
  2. Exclude: node_modules, dist, build, .next, coverage, vendor, __pycache__
  3. Exclude: generated files (*.generated.*, *.d.ts, *.min.*)
  4. Prioritize diversity:
     - Include files from every key directory
     - Include at least 5 test files (if they exist)
     - Include at least 5 component files (if they exist)
     - Include index/barrel files (for export analysis)
     - Include utility/helper files
  5. If >100 files after filtering, sample proportionally from each directory
  6. If <50 files total, use all available files

Record: files_sampled count, directories_covered count
```

**Save file list to findings.md (2-Action Rule checkpoint).**

## Step 2: Analyze Export Style

For each sampled file, detect export patterns:

```
Categories to detect:
  - default_export: "export default function/class/component"
  - named_export: "export function/const/class" (non-default)
  - barrel_export: index.ts/index.js that re-exports (export { } from or export * from)
  - mixed: file uses both default and named exports

Tally:
  default_only: N files (X%)
  named_only: N files (X%)
  barrel_files: N files
  mixed: N files (X%)

Flag inconsistency if dominant pattern is <80%.
```

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 3: Analyze State Management

For each sampled file, detect state management patterns:

```
Patterns to detect:
  - react_state: useState, useReducer (local component state)
  - redux: useSelector, useDispatch, createSlice, configureStore
  - zustand: create(set => ...), useStore
  - jotai: atom(), useAtom
  - recoil: atom(), selector(), useRecoilState
  - mobx: observable, action, observer
  - context: createContext, useContext, Provider
  - vue_state: ref(), reactive(), Pinia, Vuex
  - svelte_state: writable, derived, $store
  - none: no state management detected

Tally:
  For each pattern found: N files (X%)
  Local vs global ratio

Flag inconsistency if multiple global state libraries are used.
```

## Step 4: Analyze Styling Approach

For each sampled file, detect styling patterns:

```
Patterns to detect:
  - tailwind: className with Tailwind utility classes (flex, bg-, text-, p-, m-)
  - css_modules: import styles from "*.module.css/scss"
  - styled_components: styled.div``, css``, styled()
  - emotion: css prop, styled from @emotion
  - plain_css: import "*.css" (non-module)
  - inline_styles: style={{ }} or style={}
  - scss: import "*.scss" (non-module)
  - css_in_js_other: vanilla-extract, linaria, etc.
  - none: no styling detected (utility/logic files)

Tally (excluding "none" files):
  For each pattern found: N files (X%)

Flag inconsistency if >1 styling approach each has >20% usage.
```

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 5: Analyze Component Structure

For component files specifically (tsx, jsx, vue, svelte):

```
Patterns to detect:

File organization:
  - flat: Component.tsx alongside Component.test.tsx, Component.module.css
  - folder: ComponentName/index.tsx + ComponentName.test.tsx + styles
  - atomic: atoms/, molecules/, organisms/, templates/
  - feature: feature-name/components/, feature-name/hooks/

Prop patterns:
  - inline_props: function Component({ prop1, prop2 }: Props)
  - interface_props: separate interface/type declaration above component
  - external_props: props type imported from another file
  - no_typing: props without TypeScript types (JS projects)

Composition:
  - render_props: children as function, render prop pattern
  - hoc: withAuth(), withTheme() higher-order components
  - hooks: custom hooks (useXxx) for logic extraction
  - compound: Parent.Child pattern (compound components)

Tally each sub-category separately.
Flag inconsistency within each sub-category if dominant pattern <80%.
```

## Step 6: Analyze Test Patterns

For test files specifically (*test*, *spec*, __tests__):

```
Patterns to detect:

Naming:
  - suffix_test: Component.test.tsx
  - suffix_spec: Component.spec.tsx
  - folder_tests: __tests__/Component.tsx
  - mixed naming

Structure:
  - describe_it: describe("Component", () => { it("should...") })
  - test_only: test("should...", () => {})
  - nested_describe: multiple levels of describe nesting
  - flat: no grouping, top-level test/it calls

Coverage approach:
  - comprehensive: tests cover happy path + edge cases + error cases
  - happy_path: mostly happy path testing
  - snapshot: heavy use of snapshot tests
  - integration_heavy: tests that render full components with providers

Tally each sub-category.
Flag inconsistency if <80% consistency in naming or structure.
```

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 7: Analyze Naming Conventions

Across all sampled files:

```
File naming:
  - kebab_case: my-component.tsx
  - PascalCase: MyComponent.tsx
  - camelCase: myComponent.tsx
  - snake_case: my_component.tsx

  Tally by file type:
    Components: N kebab, N Pascal, N camel
    Utilities: N kebab, N camel, N snake
    Tests: N kebab, N Pascal (should match source)
    Hooks: N camelCase (useXxx convention)

Variable/function naming:
  - camelCase functions/variables
  - PascalCase components/classes
  - UPPER_SNAKE constants
  - Consistency of these within files

Directory naming:
  - kebab-case directories
  - camelCase directories
  - PascalCase directories

Flag inconsistency if file naming pattern <80% consistent within a file type.
```

## Step 8: Generate project-conventions.yml

Compile all findings into the output file:

```yaml
# project-conventions.yml
# Generated by code-audit skill
# Status: PENDING_REVIEW -- user must confirm before use
# Generated at: {ISO8601 timestamp}

meta:
  files_sampled: {count}
  directories_covered: {count}
  generated_at: "{ISO8601}"
  status: "pending_review"

export_style:
  dominant: "{pattern}"
  consistency: {percentage}
  breakdown:
    default_only: {count}
    named_only: {count}
    barrel_files: {count}
    mixed: {count}
  recommendation: "{canonical pattern}"
  # USER_ACTION_REQUIRED if consistency < 80%
  needs_decision: {true/false}

state_management:
  primary: "{pattern}"
  secondary: "{pattern or none}"
  local_vs_global: "{ratio description}"
  consistency: {percentage}
  recommendation: "{canonical pattern}"
  needs_decision: {true/false}

styling:
  dominant: "{approach}"
  consistency: {percentage}
  breakdown:
    tailwind: {count}
    css_modules: {count}
    styled_components: {count}
    # ... other patterns found
  recommendation: "{canonical approach}"
  needs_decision: {true/false}

component_structure:
  file_organization:
    dominant: "{pattern}"
    consistency: {percentage}
    needs_decision: {true/false}
  prop_patterns:
    dominant: "{pattern}"
    consistency: {percentage}
    needs_decision: {true/false}
  composition:
    dominant: "{pattern}"
    consistency: {percentage}
    needs_decision: {true/false}

test_patterns:
  naming:
    dominant: "{pattern}"
    consistency: {percentage}
    needs_decision: {true/false}
  structure:
    dominant: "{pattern}"
    consistency: {percentage}
    needs_decision: {true/false}
  coverage_approach:
    dominant: "{pattern}"
    needs_decision: false  # informational only

naming:
  file_naming:
    components: "{pattern}"
    utilities: "{pattern}"
    tests: "{pattern}"
    consistency: {percentage}
    needs_decision: {true/false}
  variable_naming:
    functions: "{pattern}"
    components: "{pattern}"
    constants: "{pattern}"
  directory_naming:
    dominant: "{pattern}"
    consistency: {percentage}
    needs_decision: {true/false}
```

## Step 9: Present to User for Review (Interactive -- CRITICAL)

This step is mandatory. Conventions are NEVER auto-applied.

```
Present summary grouped by decision-needed status:

## Consistent Patterns (no action needed)
For each category where consistency >= 80%:
  {category}: {dominant pattern} ({percentage}% consistent)

## Inconsistent Patterns -- Your Decision Required
For each category where needs_decision == true:
  {category}: {dominant pattern} ({percentage}%)
    Alternative: {second pattern} ({percentage}%)
    Recommendation: {dominant pattern}
    Your choice: [1] {dominant} / [2] {alternative} / [3] other

Wait for user response on EACH inconsistent category.
```

Rules for this step:
- Present ALL inconsistent categories before writing final file
- User can accept recommendation, pick alternative, or specify custom pattern
- If user wants to skip a decision, mark it as "deferred" in the file
- Do not proceed until user has addressed every needs_decision item

**Save user decisions to findings.md (2-Action Rule checkpoint).**

## Step 10: Write Reviewed Conventions

After user confirms all decisions:

1. Update project-conventions.yml:
   - Set `meta.status` to `"reviewed"`
   - Set `meta.reviewed_at` to current timestamp
   - For each category where user made a decision:
     - Set `canonical` field to user's choice
     - Set `needs_decision` to `false`
   - For deferred items: keep `needs_decision: true`, add `deferred: true`

2. Present final summary:
```
## Convention Audit Complete

Analyzed: {N} files across {N} directories
Consistent: {N} categories
User decisions: {N} categories resolved
Deferred: {N} categories (if any)

Conventions saved to: .ai/projects/{project}/dev/project-conventions.yml
Status: reviewed

These conventions will be used as a project-specific overlay
on generic tech skills for all future code generation.
```

3. Save completion to findings.md:
```markdown
## Code Audit -- Final
- Status: reviewed
- Conventions path: .ai/projects/{project}/dev/project-conventions.yml
- Files sampled: {N}
- Categories consistent: {N}/6
- User decisions made: {N}
- Completed at: {timestamp}
```

## Error Handling

1. **Profile not found:** Log to state.yml errors. Default to code_audit: true
   for work context, false for personal. Ask user if ambiguous.

2. **Too few source files (<10):** Log warning. Analyze what exists but note
   low confidence in conventions file. Flag all categories as needs_decision.

3. **No test files found:** Skip test_patterns category. Note in conventions
   file: `test_patterns: { status: "no_tests_found", needs_decision: true }`.

4. **File read errors:** Skip unreadable files, log to state.yml errors array.
   Continue with remaining files. Note skipped count in conventions file.

5. **Before retrying:** Check state.yml errors array for previous failures.
   Never repeat the same approach.

## Trace Support

If `state.yml` trace.enabled is true, follow standard trace protocol:
- Create trace file at `.ai/projects/{project}/traces/code-audit-{timestamp}.yml`
- Record each analysis step with decision, reasoning, uncertainty
- Include reflections section (required by Stop hook)
- Write trace entries every 2 steps per the 2-Action Rule
