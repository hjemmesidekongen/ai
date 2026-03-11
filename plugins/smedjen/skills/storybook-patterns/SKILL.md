---
name: storybook-patterns
description: >
  Storybook stories, args, decorators, interaction tests, visual testing, and addon
  configuration. Use when writing CSF3 stories, setting up play functions for interaction
  tests, configuring addons, integrating with Chromatic for visual regression, writing
  MDX documentation, or structuring stories for React, Vue, or Angular.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "storybook"
  - "stories"
  - "component docs"
  - "visual testing"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "csf3_format"
      verify: "Stories use CSF3 format with named exports and a default export meta object"
      fail_action: "Convert to CSF3: default export is meta, named exports are stories with args"
    - name: "args_not_hardcoded"
      verify: "Story props use args/argTypes, not hardcoded values in render functions"
      fail_action: "Move hardcoded props to args so Controls addon can manipulate them"
    - name: "play_functions_use_userEvent"
      verify: "Interaction tests use @storybook/testing-library userEvent, not fireEvent"
      fail_action: "Replace fireEvent with userEvent — it better simulates real browser input"
  on_fail: "Storybook stories have structural issues — fix before review"
  on_pass: "Stories follow Storybook best practices"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for smedjen"
---

# Storybook Patterns

Storybook isolates components for development, documentation, and testing. Its value comes from CSF3's composable story model — args flow through the component tree, play functions automate interactions, and the same stories drive visual regression in CI.

## CSF3 Stories

Every story file has one default export (the meta) and named exports (the stories). The meta sets the component, title, argTypes, and decorators. Each story is an object with an `args` property and optionally a `play` function.

Stories should compose: define a base story with common args, then spread it for variants. This keeps variant stories focused on what differs.

## Args and ArgTypes

Args are the inputs to a story. They map directly to component props. `argTypes` control how Controls renders and labels each arg. Storybook infers argTypes from TypeScript types and JSDoc, but explicit declarations override inference when needed.

Global args (defined in `preview.js`) apply to every story — useful for theme providers, locale, and other cross-cutting concerns.

## Decorators

Decorators wrap stories in additional context: providers, layout wrappers, mock data, CSS resets. They compose in order — story-level decorators run innermost, global decorators outermost. Keep decorators stateless; side effects in decorators cause flaky tests.

## Play Functions and Interaction Testing

Play functions run after the story renders. They use `@storybook/testing-library` to simulate user interactions and `@storybook/jest` for assertions. The Interactions addon shows each step and its pass/fail status.

Play functions run automatically in `storybook test` (Storybook's test runner) — the same story drives both the visual preview and the interaction test.

## Visual Testing

Visual tests capture screenshots and compare against baselines. Chromatic is the primary integration — it runs on CI, tracks story changes, and manages baselines through a review workflow. Storybook's built-in `--test` mode runs interaction tests locally.

See `references/process.md` for CSF3 examples, argTypes config, decorator patterns, play function examples, visual testing setup, MDX documentation, Chromatic CI config, framework-specific notes, and anti-patterns.
