# Visual Verification — Detailed Process

## Screenshot Capture

### Playwright Configuration

```javascript
// Breakpoint configs for screenshot capture
const breakpoints = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1280, height: 800 },
];
```

### Capture Flow

1. Start dev server (or use running server).
2. For each changed view/page:
   a. Navigate to the route.
   b. Wait for network idle + layout stable.
   c. For each breakpoint: resize viewport, capture full-page screenshot.
   d. Save to `.ai/tasks/visual/<task-id>/<view>-<breakpoint>.png`.

### Trigger Detection

Files that trigger visual verification:
```
components/**/*.{tsx,vue,svelte}
pages/**/*.{tsx,vue,svelte}
layouts/**/*.{tsx,vue,svelte}
styles/**/*.{css,scss,less}
app/**/*.{tsx,vue,svelte}    # Next.js app router
```

Non-triggers (skip verification):
```
*.test.*, *.spec.*           # Test files
utils/*, helpers/*           # Logic-only files
types/*, interfaces/*        # Type definitions
*.config.*                   # Config files
```

## Tier 1: Automated Checks

Basic layout assertions run on each screenshot:

| Check | Pass condition |
|-------|---------------|
| No horizontal overflow | Page width matches viewport width |
| No overlapping text | OCR-detected text boxes don't intersect |
| Correct viewport | Screenshot dimensions match breakpoint |
| No blank page | Screenshot is not all-white or all-black |
| No error overlays | No "Error" or stack trace text detected |

## Tier 2: LLM Vision Comparison

Compare screenshot against reference:

1. **Design reference available**: Compare side-by-side against Figma export
   or previous screenshot. Check color accuracy, spacing consistency,
   typography, alignment.

2. **No reference, intent-based**: Read the task description to understand
   what was intended. Verify the screenshot matches the stated goal.
   Score confidence 0.0-1.0.

### Comparison Prompt Template

```
Compare these two images:
- Reference: [design spec or previous version]
- Current: [new screenshot]

Check: layout structure, color accuracy, typography, spacing, alignment.
Rate confidence 0.0-1.0 that the current matches the reference intent.
List any discrepancies.
```

## Tier 3: Human Escalation

Triggered when LLM vision confidence < 0.7.

Escalation report format:
```yaml
view: "dashboard"
breakpoint: "mobile"
confidence: 0.45
concern: "Navigation menu overlaps content area below 375px"
reference: ".ai/tasks/visual/st-3/dashboard-mobile-ref.png"
current: ".ai/tasks/visual/st-3/dashboard-mobile.png"
action_needed: "Human review required — low confidence in layout correctness"
```

## Expo / Mobile Verification

For React Native / Expo projects, use Expo MCP local server instead of Playwright:

1. Ensure `EXPO_UNSTABLE_MCP_SERVER=1` is set.
2. Use Expo MCP tools to capture screenshots from iOS Simulator.
3. Same 3-tier verification applies.
4. Breakpoints map to device sizes instead of viewport widths.

## Comparison Results Schema

```yaml
task_id: "st-3"
views:
  - name: "dashboard"
    breakpoints:
      mobile:
        screenshot: "dashboard-mobile.png"
        tier_1: pass
        tier_2: { confidence: 0.92, discrepancies: [] }
        result: pass
      tablet:
        screenshot: "dashboard-tablet.png"
        tier_1: pass
        tier_2: { confidence: 0.85, discrepancies: ["spacing differs from ref by 4px"] }
        result: pass
      desktop:
        screenshot: "dashboard-desktop.png"
        tier_1: fail
        tier_2: null
        tier_1_failure: "horizontal overflow detected"
        result: fail
overall: fail
escalations: []
```
