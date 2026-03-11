# Storybook Patterns — Process Reference

## CSF3 Story Format

```ts
// Button.stories.ts
import type { Meta, StoryObj } from '@storybook/react'
import { Button } from './Button'

const meta: Meta<typeof Button> = {
  title: 'Components/Button',
  component: Button,
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'ghost'],
    },
    onClick: { action: 'clicked' },
  },
}

export default meta
type Story = StoryObj<typeof Button>

// Base story — all variants extend this
export const Primary: Story = {
  args: {
    label: 'Button',
    variant: 'primary',
  },
}

export const Secondary: Story = {
  ...Primary,
  args: {
    ...Primary.args,
    variant: 'secondary',
  },
}

export const Large: Story = {
  args: {
    ...Primary.args,
    size: 'large',
  },
}
```

`tags: ['autodocs']` generates an automatic documentation page for the component. The Controls addon is powered by `argTypes` — without it, Controls infers from TypeScript types.

---

## Args and ArgTypes

### ArgTypes Configuration

```ts
argTypes: {
  // Control type override
  color: {
    control: 'color',
    description: 'Background color of the button',
  },

  // Disable control (read-only display)
  id: {
    control: false,
  },

  // Select with labels
  size: {
    control: 'select',
    options: ['small', 'medium', 'large'],
    mapping: {
      small: 'sm',
      medium: 'md',
      large: 'lg',
    },
  },

  // Range slider
  opacity: {
    control: { type: 'range', min: 0, max: 1, step: 0.1 },
  },

  // Event handler → action logger
  onChange: { action: 'changed' },
}
```

### Global Args (preview.ts)

```ts
// .storybook/preview.ts
import type { Preview } from '@storybook/react'

const preview: Preview = {
  args: {
    theme: 'light',
    locale: 'en',
  },
  argTypes: {
    theme: {
      control: 'select',
      options: ['light', 'dark'],
    },
  },
}

export default preview
```

Global args are merged with story args — story args take precedence. Use for cross-cutting concerns like theme and locale that every story needs.

---

## Decorators

### Story-Level Decorator

```ts
export const WithPadding: Story = {
  decorators: [
    (Story) => (
      <div style={{ padding: '2rem' }}>
        <Story />
      </div>
    ),
  ],
  args: { label: 'Padded Button' },
}
```

### Component-Level Decorator

```ts
const meta: Meta<typeof Button> = {
  component: Button,
  decorators: [
    (Story) => (
      <ThemeProvider theme="light">
        <Story />
      </ThemeProvider>
    ),
  ],
}
```

### Global Decorator (preview.ts)

```ts
// .storybook/preview.ts
const preview: Preview = {
  decorators: [
    (Story, context) => (
      <ThemeProvider theme={context.globals.theme}>
        <Story />
      </ThemeProvider>
    ),
  ],
}
```

Decorator execution order: global (outermost) → component → story (innermost). Keep decorators pure functions — no side effects, no local state.

---

## Play Functions — Interaction Testing

```ts
import { within, userEvent, expect } from '@storybook/test'

export const FilledForm: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)

    // Simulate user typing
    await userEvent.type(
      canvas.getByRole('textbox', { name: /email/i }),
      'test@example.com'
    )

    await userEvent.type(
      canvas.getByLabelText(/password/i),
      'supersecret'
    )

    // Click submit
    await userEvent.click(canvas.getByRole('button', { name: /sign in/i }))

    // Assert outcome
    await expect(
      canvas.getByText(/welcome back/i)
    ).toBeInTheDocument()
  },
}
```

### Accessing Args in Play

```ts
export const Controlled: Story = {
  args: { onSubmit: fn() },

  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement)
    await userEvent.click(canvas.getByRole('button'))

    // Assert the spy was called
    await expect(args.onSubmit).toHaveBeenCalledOnce()
    await expect(args.onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'test@example.com' })
    )
  },
}
```

Use `fn()` from `@storybook/test` (not `jest.fn()`) for story-compatible spies. They work in both browser and Node test environments.

### Step Breakdown (Interactions addon)

```ts
play: async ({ step }) => {
  await step('Fill email', async () => {
    await userEvent.type(canvas.getByLabelText(/email/i), 'user@test.com')
  })

  await step('Submit form', async () => {
    await userEvent.click(canvas.getByRole('button', { name: /submit/i }))
  })

  await step('Verify success message', async () => {
    await expect(canvas.getByText(/success/i)).toBeVisible()
  })
}
```

Steps appear in the Interactions panel with pass/fail indicators per step.

---

## Running Interaction Tests

```bash
# Run all story interaction tests (headless)
npx storybook test

# Watch mode
npx storybook test --watch

# Run a specific story file
npx storybook test --testPathPattern="Button"

# CI: run against a built Storybook
npx storybook test --url=http://localhost:6006
```

The test runner uses Playwright under the hood. Stories without play functions are skipped.

---

## Visual Testing with Chromatic

### Setup

```bash
npm install --save-dev chromatic
npx chromatic --project-token=<token> --build-script-name=build-storybook
```

### CI Configuration (GitHub Actions)

```yaml
name: Visual Tests
on: push
jobs:
  chromatic:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # Required for Chromatic TurboSnap
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - uses: chromaui/action@latest
        with:
          projectToken: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}
          buildScriptName: build-storybook
          onlyChanged: true   # TurboSnap — test only changed stories
```

`onlyChanged: true` enables TurboSnap — Chromatic traces which stories changed based on git diff and only snapshots those. Significant cost reduction on large Storybooks.

### Storybook Build Script

```json
// package.json
{
  "scripts": {
    "build-storybook": "storybook build",
    "chromatic": "chromatic --project-token=$CHROMATIC_PROJECT_TOKEN"
  }
}
```

---

## MDX Documentation

```mdx
{/* Button.mdx */}
import { Meta, Story, Canvas, Controls, ArgTypes } from '@storybook/blocks'
import * as ButtonStories from './Button.stories'

<Meta of={ButtonStories} />

# Button

Buttons trigger actions. Use the primary variant for the main action on a page,
secondary for supporting actions, ghost for low-emphasis actions.

<Canvas of={ButtonStories.Primary} />

<Controls of={ButtonStories.Primary} />

## Variants

<Canvas of={ButtonStories.Secondary} />
<Canvas of={ButtonStories.Large} />

## All Args

<ArgTypes of={ButtonStories} />
```

MDX documentation pages replace auto-generated docs when you need prose, custom layout, or curated story selection. Reference story files with `of={Stories}` rather than duplicating story content in MDX.

---

## Framework-Specific Notes

### React

```ts
// .storybook/main.ts
import type { StorybookConfig } from '@storybook/react-vite'

const config: StorybookConfig = {
  framework: '@storybook/react-vite',
  stories: ['../src/**/*.stories.@(ts|tsx|mdx)'],
  addons: [
    '@storybook/addon-essentials',
    '@storybook/addon-interactions',
    '@storybook/addon-a11y',
  ],
}
```

### Vue

```ts
import type { StorybookConfig } from '@storybook/vue3-vite'

const config: StorybookConfig = {
  framework: '@storybook/vue3-vite',
}
```

Vue stories use the same CSF3 format. The `component` field in meta must be the Vue component object.

### Angular

```ts
import type { StorybookConfig } from '@storybook/angular'

const config: StorybookConfig = {
  framework: '@storybook/angular',
}
```

Angular stories require `moduleMetadata` decorator for providers and imports:

```ts
import { moduleMetadata } from '@storybook/angular'

export const WithRouter: Story = {
  decorators: [
    moduleMetadata({
      imports: [RouterModule.forRoot([])],
      providers: [{ provide: ActivatedRoute, useValue: mockRoute }],
    }),
  ],
}
```

---

## Addon Configuration

```ts
// .storybook/main.ts
addons: [
  '@storybook/addon-essentials',    // Controls, Actions, Docs, Viewport, Backgrounds, Toolbars
  '@storybook/addon-interactions',  // Play function step viewer
  '@storybook/addon-a11y',          // Accessibility audit panel
  '@storybook/addon-coverage',      // Coverage reporting for test runner
  'storybook-dark-mode',            // Dark/light mode toggle
]
```

### Backgrounds Addon Config

```ts
// preview.ts
const preview: Preview = {
  parameters: {
    backgrounds: {
      default: 'light',
      values: [
        { name: 'light', value: '#ffffff' },
        { name: 'dark', value: '#1a1a2e' },
        { name: 'gray', value: '#f5f5f5' },
      ],
    },
  },
}
```

### Viewport Addon Config

```ts
parameters: {
  viewport: {
    viewports: {
      mobile: { name: 'Mobile', styles: { width: '375px', height: '812px' } },
      tablet: { name: 'Tablet', styles: { width: '768px', height: '1024px' } },
      desktop: { name: 'Desktop', styles: { width: '1440px', height: '900px' } },
    },
    defaultViewport: 'desktop',
  },
}
```

---

## Common Anti-Patterns

**Hardcoding props in the render function instead of args.** Props in render bypass the Controls addon and make stories non-composable.

```ts
// WRONG
export const Bad: Story = {
  render: () => <Button label="Click me" variant="primary" />,
}

// CORRECT
export const Good: Story = {
  args: { label: 'Click me', variant: 'primary' },
}
```

**One story per component with every variant in a single story.** This defeats the purpose of stories — each significant state or variant should be a separate named story for independent testing and documentation.

**Side effects in decorators.** Decorators that modify global state, register event listeners, or have setup/teardown logic cause flaky interaction tests. Keep decorators as pure rendering wrappers.

**Using `fireEvent` instead of `userEvent` in play functions.** `fireEvent` dispatches DOM events directly without the browser-native interaction chain (focus, pointer events, input events). `userEvent` simulates realistic user behavior and catches more real bugs.

**Importing story files with default import.** Story files must be imported with namespace import (`import * as Stories`) so Storybook's blocks can reference individual stories by name.

**Not excluding stories from production bundles.** Story files and `@storybook/test` dependencies should be dev-only. Ensure `*.stories.*` files are excluded from the production build via bundler config.

**Skipping `tags: ['autodocs']` on public components.** Without autodocs, there's no documentation page — consumers of a component library have to read source to understand the API. Tag every exported component story.

**Play functions that don't await all interactions.** Missing `await` causes tests to pass before assertions run. Every `userEvent` call and every `expect` must be awaited.
