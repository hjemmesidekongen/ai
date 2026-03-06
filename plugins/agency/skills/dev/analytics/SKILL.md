---
name: analytics
user-invocable: false
description: >
  Instruments full user behavior tracking during the build phase. Scaffolds
  analytics SDK (PostHog or Mixpanel from stack negotiation), automatic page
  view tracking, UTM capture, click/interaction tracking, scroll depth,
  entry/exit tracking, funnel definitions, error page analytics (ties to
  dec-02), and GDPR consent gating. Requires user interview for event taxonomy.
phase: 3
depends_on: [stack-negotiation]
reads:
  - ".ai/projects/[name]/dev/stack.yml"
writes:
  - "src/lib/analytics.ts"
  - "src/lib/analytics-events.ts"
  - "src/components/AnalyticsProvider.tsx"
  - "src/components/ConsentBanner.tsx"
model_tier: senior
model: sonnet
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "sdk_configured"
      verify: "analytics.ts exports init function using provider from stack.yml"
      fail_action: "Re-read stack.yml and scaffold correct SDK"
    - name: "provider_scaffolded"
      verify: "AnalyticsProvider.tsx wraps app with SDK init and page view tracking"
      fail_action: "Generate AnalyticsProvider with route-change listener"
    - name: "utm_capture"
      verify: "UTM params captured on first load and persisted to sessionStorage"
      fail_action: "Add UTM extraction to AnalyticsProvider mount"
    - name: "consent_gating"
      verify: "ConsentBanner.tsx exists with both consent and denial paths"
      fail_action: "Scaffold ConsentBanner with full-stream and anonymous paths"
    - name: "event_taxonomy_confirmed"
      verify: "analytics-events.ts contains user-confirmed event definitions"
      fail_action: "Re-run event taxonomy interview"
    - name: "error_page_analytics"
      verify: "Error page tracking captures URL, referrer, session ID, and user action"
      fail_action: "Add error page analytics hook with full context"
    - name: "funnel_definitions"
      verify: "At least one user-defined funnel exists in analytics-events.ts"
      fail_action: "Re-prompt user for funnel definitions"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Analytics

Build-phase skill that instruments full user behavior tracking. Reads the
confirmed analytics provider from stack.yml (PostHog or Mixpanel) and
scaffolds SDK integration, automatic tracking, GDPR consent gating, and
user-defined event taxonomies with funnel support.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | stack.yml (confirmed analytics provider) |
| **Writes** | analytics.ts, analytics-events.ts, AnalyticsProvider.tsx, ConsentBanner.tsx |
| **Checkpoint** | 7 checks: SDK, provider, UTM, consent, taxonomy, error analytics, funnels |
| **Dependencies** | stack-negotiation (must confirm analytics provider first) |

## Process Summary

1. Read stack.yml for confirmed analytics provider (PostHog/Mixpanel)
2. Run event taxonomy interview — ask user about business events, funnels, user properties
3. Scaffold analytics.ts with SDK init, page views, UTM capture, scroll depth
4. Scaffold AnalyticsProvider.tsx with route-change tracking and consent gating
5. Scaffold ConsentBanner.tsx with both consent paths (full stream / anonymous)
6. Generate analytics-events.ts with confirmed taxonomy and funnel definitions
7. Add error page analytics hook (URL, referrer, session ID, user action — ties to dec-02)
8. Run checkpoint — all 7 checks must pass

**Findings:** Write to `.ai/projects/[name]/dev/findings.md` every 2 actions. Errors go to state.yml. Follow [references/process.md](references/process.md).
