# UX Writing — Detailed Process

## Overview

UX writing covers every word the interface speaks to the user. This skill
operates at the intersection of brand voice and component behaviour: it reads
the machine-readable component specs (slots, states, interactive triggers)
and converts them into structured copy organized by functional category.

The outputs are 6 YAML files consumed downstream by scaffold (injects copy
into generated components), storybook-generator (populates story fixtures),
and the brand manual (documents the voice system).

---

## Step 1 — Extract Slots and States from Component Specs

For each file in `design/components/*.yml`:

1. Read the `slots` array — every slot is a content target
2. Read the `states` array — interactive states that need copy:
   - `error`, `loading`, `empty`, `disabled`, `success`, `warning`
3. Read the `category` field — informs copy tone
   (`form`, `feedback`, `navigation`, `interactive`, `display`, `layout`)
4. Build a coverage map: `component → [slots] + [states]`

Do not proceed if `design/components/` has fewer than 3 spec files — the
component-specs phase has not run. Report blocked.

---

## Step 2 — Load Brand Voice Tokens

From `brand/brand-summary.yml`, read:

```yaml
voice:
  personality: []        # e.g. ["direct", "warm", "confident"]
  tone_spectrum:
    formal_casual: 3     # 1 (formal) → 5 (casual)
    playful_serious: 2   # 1 (playful) → 5 (serious)
  vocabulary:
    preferred: []        # words to use
    avoid: []            # words to avoid
  sentence_style:
    max_words: 12        # microcopy sentence cap
    active_voice: true
    contractions: true
```

Apply these rules to every piece of copy generated. Voice tokens are
non-negotiable constraints — not stylistic suggestions.

---

## Step 3 — Generate Copy by Category

Work through each category in order. Present each batch to the user for
review before moving to the next category.

### Category 1: Error Messages → `content/ux/error-messages.yml`

#### Error Message Taxonomy

```yaml
severity_levels:
  info:     "Informational — no action required"
  warning:  "Potential issue — action recommended"
  error:    "Problem — action required"
  critical: "System failure — immediate attention"

error_categories:
  validation:     "User input doesn't meet requirements"
  authentication: "Access denied or session expired"
  network:        "Connection or API failure"
  not_found:      "Resource doesn't exist"
  permission:     "Insufficient permissions"
  conflict:       "Action conflicts with current state"
  rate_limit:     "Too many requests"
  server:         "Internal system error"
```

#### Error Message YAML Format

```yaml
# content/ux/error-messages.yml
errors:
  - code: "AUTH_SESSION_EXPIRED"
    severity: "error"
    category: "authentication"
    title: "Session expired"
    description: "You've been signed out after a period of inactivity."
    action: "Sign in again to continue"
    tone: "neutral"           # neutral | apologetic | directive
    retry_eligible: true
  - code: "NET_CONNECTION_LOST"
    severity: "warning"
    category: "network"
    title: "No connection"
    description: "Check your internet connection and try again."
    action: "Retry"
    tone: "neutral"
    retry_eligible: true
  - code: "SRV_INTERNAL_ERROR"
    severity: "critical"
    category: "server"
    title: "Something went wrong"
    description: "We hit an unexpected error. Our team has been notified."
    action: "Try again in a moment"
    tone: "apologetic"
    retry_eligible: true
```

**Generation rules:**
- Title: max 4 words, sentence case, no punctuation
- Description: max 12 words, active voice, explains what happened
- Action: imperative verb phrase, max 6 words
- Never blame the user ("you entered an invalid..." → "That format isn't valid...")
- Never expose technical details (no stack traces, error codes in UI)
- Always offer a next step — dead ends are forbidden

---

### Category 2: Validation Messages → `content/ux/validation-messages.yml`

```yaml
# content/ux/validation-messages.yml
validation:
  field_level:
    - field_type: "email"
      rule: "format"
      message: "Enter a valid email address"
      hint: "Example: name@domain.com"
    - field_type: "password"
      rule: "min_length"
      message: "Password must be at least 8 characters"
      hint: "Use a mix of letters, numbers, and symbols"
    - field_type: "text"
      rule: "required"
      message: "This field is required"
      hint: null
    - field_type: "url"
      rule: "format"
      message: "Enter a valid URL"
      hint: "Example: https://example.com"

  form_level:
    - rule: "incomplete"
      message: "Complete all required fields to continue"
    - rule: "conflict"
      message: "Some fields have conflicting values"
```

**Generation rules:**
- Field-level: fires inline, adjacent to the field, on blur or submit
- Form-level: fires at submit, above the submit button
- Message: plain language, specific about the rule, ≤10 words
- Hint: optional clarification or example, shown below the message
- Never use "invalid" alone — say what was invalid and why

---

### Category 3: Tooltips and Help Text → `content/ux/tooltips.yml`

Read component specs for `interactive_triggers: hover | focus` and `slots`
of type `help_text` or `label_secondary`.

```yaml
# content/ux/tooltips.yml
tooltips:
  - component: "PasswordInput"
    trigger: "info_icon"
    text: "Must be 8+ characters with at least one number"
    max_length: 60
    placement: "top"
  - component: "PricingToggle"
    trigger: "hover"
    text: "Switch between monthly and annual billing"
    max_length: 60
    placement: "bottom"

help_text:
  - component: "FileUpload"
    context: "below_input"
    text: "Accepted formats: JPG, PNG, PDF. Max 10 MB."
  - component: "ApiKeyInput"
    context: "below_input"
    text: "Find your API key in Settings → Integrations"
```

**Generation rules:**
- Tooltip text: ≤60 characters, sentence case, no period
- Help text: ≤80 characters, can include punctuation for multi-sentence
- Explain the why, not just the what — "Required for two-factor auth" beats "Your phone number"

---

### Category 4: Confirmations → `content/ux/confirmations.yml`

Extract from component specs any action with `destructive: true` or
`requires_confirmation: true` in the `states` or `props`.

```yaml
# content/ux/confirmations.yml
confirmations:
  destructive:
    - action: "delete_account"
      title: "Delete your account?"
      description: "This permanently removes your data and cannot be undone."
      confirm_label: "Delete account"
      cancel_label: "Keep account"
      severity: "critical"
    - action: "remove_member"
      title: "Remove team member?"
      description: "They'll lose access to all projects immediately."
      confirm_label: "Remove"
      cancel_label: "Cancel"
      severity: "warning"

  state_changes:
    - action: "publish_content"
      title: "Publish this post?"
      description: "It will be visible to all visitors right away."
      confirm_label: "Publish"
      cancel_label: "Not yet"
      severity: "info"

  success:
    - action: "invitation_sent"
      title: "Invitation sent"
      description: "They'll receive an email with instructions to join."
      confirm_label: null
      cancel_label: null
      severity: "info"
```

**Generation rules:**
- Title: question form for destructive/state-change, statement form for success
- Confirm label: echoes the destructive verb ("Delete account" not "Yes, delete")
- Cancel label: affirms the safe path ("Keep account" not "No" or "Cancel")
- Description: states the consequence, not a warning — users have already read warnings
- No "Are you sure?" — it adds friction without information

---

### Category 5: Loading and Empty States → `content/ux/states.yml`

From component specs, identify components with `states` containing
`loading`, `empty`, or `skeleton`.

```yaml
# content/ux/states.yml
loading:
  - context: "page_initial"
    loading_text: "Loading your dashboard…"
    skeleton: true
  - context: "data_refresh"
    loading_text: "Updating…"
    skeleton: false
  - context: "form_submit"
    loading_text: "Saving…"
    skeleton: false
  - context: "file_upload"
    loading_text: "Uploading {filename}…"
    skeleton: false

empty_states:
  - context: "first_time_use"
    empty_title: "Start your first project"
    empty_description: "Create a project to organize your work and invite your team."
    empty_action: "New project"
    empty_action_variant: "primary"
  - context: "no_results"
    empty_title: "No results for "{query}""
    empty_description: "Try different keywords or check the spelling."
    empty_action: "Clear search"
    empty_action_variant: "secondary"
  - context: "filtered_empty"
    empty_title: "Nothing matches these filters"
    empty_description: "Adjust your filters to see more results."
    empty_action: "Reset filters"
    empty_action_variant: "secondary"
```

**Generation rules:**
- Loading text: present continuous verb, ellipsis at end, ≤5 words
- Empty title: action-oriented for first-use, descriptive for no-results
- Empty description: one sentence explaining why and what to try
- Empty action: always present an escape hatch — never strand the user
- Use template variables (`{filename}`, `{query}`) where dynamic values apply

---

### Category 6: CTAs and Labels → `content/ux/labels.yml`

```yaml
# content/ux/labels.yml
buttons:
  primary_actions:
    - action_type: "create"
      labels: ["Create", "New {resource}", "Add {resource}"]
    - action_type: "save"
      labels: ["Save", "Save changes", "Save and continue"]
    - action_type: "submit"
      labels: ["Submit", "Send", "Complete"]
    - action_type: "publish"
      labels: ["Publish", "Go live", "Publish now"]
    - action_type: "delete"
      labels: ["Delete", "Remove", "Delete {resource}"]
    - action_type: "cancel_action"
      labels: ["Cancel", "Discard", "Discard changes"]

  secondary_actions:
    - action_type: "edit"
      labels: ["Edit", "Rename", "Update"]
    - action_type: "view"
      labels: ["View", "Open", "See details"]
    - action_type: "export"
      labels: ["Export", "Download", "Export as PDF"]

navigation:
  - location: "primary_nav"
    items: []   # populated per project during review
  - location: "breadcrumb_home"
    label: "Home"
  - location: "back_link"
    label: "Back"

form_labels:
  - field_type: "email"
    label: "Email address"
    placeholder: "name@domain.com"
  - field_type: "password"
    label: "Password"
    placeholder: null
  - field_type: "name"
    label: "Full name"
    placeholder: "Jane Smith"
  - field_type: "search"
    label: null
    placeholder: "Search…"
```

**Generation rules:**
- Button labels: imperative verb, ≤3 words, specific over generic
- "Submit" is a last resort — prefer the actual action ("Send message")
- Navigation labels: nouns or short noun phrases, title case
- Form placeholders: realistic examples, not instructions ("Jane Smith" not "Enter your name")

**2-Action Rule checkpoint:** After generating each category's YAML, save progress to `.ai/projects/[name]/content/findings.md` before moving to the next category.

---

## Step 4 — User Review Protocol

Present each category as a batch. For each batch:

1. Display the generated YAML (or a readable table for long lists)
2. Ask: "Does this match the brand voice and cover all the states you need?"
3. Accept edits inline — update the YAML before moving on
4. Confirm readiness: "Ready to move to [next category]?"

Do not move to the next category until the user confirms the current one.

**2-Action Rule checkpoint:** After each category review is confirmed, save the approved copy and any user feedback to `.ai/projects/[name]/content/findings.md`.

---

## Step 5 — Asset Registry Update

Append to `asset-registry.yml` under the `content` section:

```yaml
content:
  ux:
    - path: ".ai/projects/[name]/content/ux/error-messages.yml"
      type: "ux_copy"
      category: "errors"
      generated_at: "[timestamp]"
    - path: ".ai/projects/[name]/content/ux/validation-messages.yml"
      type: "ux_copy"
      category: "validation"
      generated_at: "[timestamp]"
    - path: ".ai/projects/[name]/content/ux/tooltips.yml"
      type: "ux_copy"
      category: "tooltips"
      generated_at: "[timestamp]"
    - path: ".ai/projects/[name]/content/ux/confirmations.yml"
      type: "ux_copy"
      category: "confirmations"
      generated_at: "[timestamp]"
    - path: ".ai/projects/[name]/content/ux/states.yml"
      type: "ux_copy"
      category: "states"
      generated_at: "[timestamp]"
    - path: ".ai/projects/[name]/content/ux/labels.yml"
      type: "ux_copy"
      category: "labels"
      generated_at: "[timestamp]"
```

---

## Step 6 — Checkpoint

Run all 5 checks in the SKILL.md checkpoint block. For `brand_voice_applied`,
spot-check 3 items per category against the vocabulary and tone rules loaded
in Step 2. For `component_coverage`, cross-reference the coverage map built
in Step 1 against all 6 output files.

Update `state.yml`:

```yaml
skills:
  ux-writing:
    status: "completed"
    completed_at: "[timestamp]"
    outputs:
      - "content/ux/error-messages.yml"
      - "content/ux/validation-messages.yml"
      - "content/ux/tooltips.yml"
      - "content/ux/confirmations.yml"
      - "content/ux/states.yml"
      - "content/ux/labels.yml"
```

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- `categories_complete` — all 6 UX copy YAML files exist and are non-empty
- `brand_voice_applied` — tone and personality tokens from brand-summary.yml are reflected in copy
- `component_coverage` — every component slot and interactive state from component specs is addressed
- `error_taxonomy_applied` — every error message has: code, severity, category, title, description, action
- `assets_registered` — all 6 UX copy files registered in asset-registry.yml under content.ux

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Error messages never blame the user ("That format isn't valid" not "You entered an invalid format")
- All empty states have escape hatches — no dead ends where the user is stranded
- Confirmations use consequence-based descriptions ("This permanently removes your data") not vague warnings
- Tooltips are ≤60 characters — trim any that exceed this limit
- Validation messages are specific about the rule violated, not generic ("invalid" alone is forbidden)

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Trace Protocol

If `state.yml` has `trace.enabled: true`, follow the
[trace protocol](../../../../resources/trace-protocol.md) to write a structured
trace file to `.ai/projects/[name]/traces/`.
