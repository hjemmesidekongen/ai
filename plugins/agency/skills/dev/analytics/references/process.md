# Analytics — Detailed Process

## Overview

The analytics skill instruments comprehensive user behavior tracking during
the build phase. It reads the confirmed analytics provider from stack.yml,
conducts a user interview to define the event taxonomy, then scaffolds all
tracking infrastructure with GDPR consent gating.

Key principle: the skill never guesses what events matter. The event taxonomy
is always derived from a user interview conducted during execution.

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

## Step 1: Read Stack Configuration

```
Read: .ai/projects/[name]/dev/stack.yml
Extract:
  - analytics_provider: posthog | mixpanel
  - analytics_key_env_var: NEXT_PUBLIC_POSTHOG_KEY | NEXT_PUBLIC_MIXPANEL_TOKEN
  - framework: (Next.js, Remix, etc. — affects route tracking approach)
  - typescript: true/false
```

If `analytics_provider` is not present in stack.yml, stop:
"Analytics provider not confirmed. Run stack-negotiation first and confirm
an analytics provider (PostHog or Mixpanel)."

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 2: Event Taxonomy Interview (Interactive — REQUIRED)

This is the critical step. Do NOT skip or pre-fill. Ask the user directly:

### Question 1 — Business Events
```
What are the key events your business cares about tracking?

Examples:
  - User signed up
  - User completed onboarding
  - User created first [resource]
  - User invited team member
  - User upgraded plan
  - User exported data

List your events (one per line), or say "suggest defaults for [app type]":
```

### Question 2 — Funnel Definitions
```
What user journeys (funnels) do you want to track?

A funnel is a sequence of steps where you want to measure drop-off.

Examples:
  - Signup funnel: landing_page_view → signup_click → form_submit → email_verify → first_login
  - Onboarding funnel: first_login → profile_setup → first_action → invite_team
  - Purchase funnel: pricing_view → plan_select → checkout_start → payment_submit → purchase_complete

Define your funnels (name: step1 → step2 → ...), or say "suggest defaults":
```

### Question 3 — User Properties
```
What user properties should be tracked alongside events?

Examples:
  - plan_tier (free/pro/enterprise)
  - company_size
  - role
  - signup_source
  - account_age_days

List your properties, or say "suggest defaults":
```

Record all answers. If user says "suggest defaults", provide sensible defaults
for the app type detected from stack.yml, then confirm with the user.

**Save confirmed taxonomy to findings.md after this step (2-Action Rule checkpoint).**

## Step 3: Scaffold analytics.ts

Generate `src/lib/analytics.ts` with the confirmed provider SDK.

### PostHog variant:
```typescript
// SDK initialization
// - Reads API key from env var
// - Configures autocapture, session recording (if consented)
// - Exposes: init(), identify(), track(), trackPageView(), reset()
```

### Mixpanel variant:
```typescript
// SDK initialization
// - Reads token from env var
// - Configures persistence, tracking options
// - Exposes: init(), identify(), track(), trackPageView(), reset()
```

### Both variants must include:

**UTM Capture (persisted to sessionStorage):**
```
On init:
  1. Parse window.location.search for utm_source, utm_medium, utm_campaign, utm_term, utm_content
  2. If any UTM param found, store all as JSON in sessionStorage key "utm_params"
  3. On subsequent page loads, read from sessionStorage (survives navigation)
  4. Attach UTM params as super properties to all events in the session
  5. Do NOT overwrite if sessionStorage already has UTM params (first-touch attribution)
```

**Scroll Depth Tracking:**
```
Export scrollDepthTracker():
  1. Listen to scroll events (throttled to 250ms)
  2. Calculate percentage: (scrollTop + viewportHeight) / documentHeight * 100
  3. Fire events at 25%, 50%, 75%, 100% thresholds
  4. Each threshold fires only once per page view
  5. Include page path and time-on-page in event properties
```

**Entry/Exit Tracking:**
```
Export entryExitTracker():
  1. On page load: record document.referrer as entry_referrer
  2. Track entry page (first page view in session)
  3. On beforeunload: fire exit event with current page path and time-on-page
  4. Distinguish internal navigation from true exits
```

**Save to findings.md after scaffolding (2-Action Rule checkpoint).**

## Step 4: Scaffold AnalyticsProvider.tsx

Generate `src/components/AnalyticsProvider.tsx`:

```
Component structure:
  1. Wraps children with analytics context
  2. On mount: call analytics.init() — but ONLY if consent is granted
  3. Route-change listener:
     - Next.js: use next/navigation usePathname()
     - Remix: use useLocation()
     - Generic: listen to popstate + pushState/replaceState
  4. On route change: call analytics.trackPageView() with path and referrer
  5. On mount: run UTM capture (reads URL params, persists to sessionStorage)
  6. On mount: start scroll depth tracker
  7. On mount: start entry/exit tracker
  8. Consent state: read from localStorage key "analytics_consent"
     - "granted" → full analytics stream
     - "denied" → anonymous mode or no tracking (depending on provider)
     - null (not yet decided) → show ConsentBanner, do NOT init analytics
```

**Declarative Click/Interaction Tracking:**
```
Export useTrackClick(eventName, properties?) hook:
  - Returns a ref to attach to any element
  - Automatically tracks clicks with the given event name
  - No manual onClick handlers needed per element

Export data-track attribute support:
  - AnalyticsProvider sets up a delegated click listener on document
  - Any element with data-track="event_name" fires that event on click
  - data-track-* attributes become event properties
  - Example: <button data-track="cta_click" data-track-location="hero">
```

## Step 5: Scaffold ConsentBanner.tsx

Generate `src/components/ConsentBanner.tsx`:

```
Component structure:
  1. Only renders when localStorage "analytics_consent" is null
  2. Displays consent message with Accept and Decline buttons
  3. Accept path:
     - Set localStorage "analytics_consent" = "granted"
     - Call analytics.init() with full tracking enabled
     - Fire "consent_granted" event
     - Dismiss banner
  4. Decline path:
     - Set localStorage "analytics_consent" = "denied"
     - Either: init analytics in anonymous mode (no PII, no session recording)
     - Or: do not init analytics at all (configurable)
     - Dismiss banner
  5. Both paths fully scaffolded — neither is a stub
  6. Banner text is configurable via props (default: GDPR-compliant copy)
  7. Styling uses design tokens from the project (if available)
```

**GDPR requirements scaffolded:**
- No tracking fires before consent decision
- Consent choice persists across sessions (localStorage)
- User can change consent later (expose resetConsent() function)
- Anonymous mode collects no PII, no cookies, no session recording

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 6: Generate analytics-events.ts

Generate `src/lib/analytics-events.ts` from the confirmed taxonomy:

```typescript
// Type-safe event definitions from user interview
// - Event name constants (prevents typos)
// - Event property types (TypeScript interfaces)
// - Funnel definitions (ordered step arrays)
// - User property types
// - Helper functions: trackSignup(), trackOnboarding(), etc.
```

### Structure:

```
1. Event name enum/constants:
   - Map each user-defined event to a constant
   - Use SCREAMING_SNAKE for constants, snake_case for event names sent to provider

2. Event property interfaces:
   - Each event gets a typed properties interface
   - Common properties (page, timestamp, session_id) are inherited

3. Funnel definitions:
   - Each funnel is an ordered array of event names
   - Export as named constants for use in provider dashboard setup

4. User properties:
   - Typed interface for identify() calls
   - Includes properties from Question 3 of the interview

5. Convenience functions:
   - One function per major event (trackSignup, trackPurchase, etc.)
   - Type-safe — accepts only the correct properties for that event
```

## Step 7: Error Page Analytics (ties to dec-02)

Add error page tracking that integrates with the error page system:

```
Export trackErrorPageView(context):
  Properties captured:
    - error_type: "404" | "500" | "generic"
    - url: the URL the user tried to access
    - referrer: document.referrer (where they came from)
    - session_id: current analytics session ID
    - utm_params: from sessionStorage (if present)
    - timestamp: ISO8601
    - user_action: "suggestion_clicked" | "back_clicked" | "bounced" | "search_used"
    - suggestion_clicked_url: (if user clicked a suggestion link)
    - time_on_error_page: seconds before user took action

  Integration:
    - Error page components call trackErrorPageView() on mount
    - Track which recovery action the user takes (click suggestion, go back, bounce)
    - If user clicks a suggested link, track which suggestion and whether it resolved
```

This provides full error page analytics context as specified in dec-02.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 8: Run Checkpoint

Verify all 7 checkpoint checks pass:

1. **sdk_configured** — analytics.ts exists, exports init() using the provider from stack.yml
2. **provider_scaffolded** — AnalyticsProvider.tsx wraps app with SDK init and route-change page view tracking
3. **utm_capture** — UTM params are extracted from URL on first load, stored in sessionStorage, attached to all events
4. **consent_gating** — ConsentBanner.tsx exists with working Accept (full stream) and Decline (anonymous/nothing) paths
5. **event_taxonomy_confirmed** — analytics-events.ts contains event definitions that match the user interview answers
6. **error_page_analytics** — trackErrorPageView captures URL, referrer, session_id, user_action with full context
7. **funnel_definitions** — at least one funnel is defined in analytics-events.ts as an ordered step array

On failure: fix the failing check and re-run.
On pass: update state.yml — set analytics phase to `completed`.

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- analytics.ts exists and exports init, identify, track, trackPageView, reset
- AnalyticsProvider.tsx exists with route-change listener and consent check
- ConsentBanner.tsx exists with both Accept and Decline paths implemented
- analytics-events.ts exists with at least one event constant and one funnel
- UTM capture reads from URL and persists to sessionStorage
- Error page tracking function exists with url, referrer, session_id, user_action params

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- SDK init uses correct provider API (PostHog vs Mixpanel — not mixed)
- Consent gating prevents any tracking before user decision
- UTM params use first-touch attribution (don't overwrite existing)
- Scroll depth thresholds fire only once per page view
- Event names follow consistent naming convention
- Funnel steps reference valid event names from the taxonomy
- Error page analytics captures all required context fields
- No hardcoded API keys — all from environment variables

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only analytics files and findings.md updates
2. Commit: `[plan_name]: analytics [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

---

## Common Issues

**Wrong provider API:** PostHog uses `posthog.capture()`, Mixpanel uses
`mixpanel.track()`. Read stack.yml carefully and use the correct API.

**UTM params lost on navigation:** Store in sessionStorage on first load.
Read from sessionStorage on subsequent page views. Never re-read from URL
after initial capture (SPA navigation strips query params).

**Consent race condition:** AnalyticsProvider must check consent state
synchronously on mount. Do not init the SDK and then check consent —
check first, init only if granted.

**Scroll depth double-firing:** Use a Set to track which thresholds have
fired. Reset the Set on route change (new page view).

**Missing event properties:** Every track() call should include at minimum:
page path, timestamp, and session UTM params (if present).

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
