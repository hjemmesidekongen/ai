---
name: expo-deployment
description: >
  EAS Build, OTA updates, app store submission, and Expo deployment workflows.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo deployment"
  - "eas build"
  - "ota updates"
  - "app store submission"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "runtime_version_policy"
      verify: "runtimeVersion policy matches update strategy — fingerprint for SDK-managed, manual for strict control"
      fail_action: "Align runtimeVersion policy with OTA update expectations before shipping"
    - name: "eas_json_profiles_complete"
      verify: "eas.json defines development, preview, and production profiles with correct distribution types"
      fail_action: "Add missing profiles — missing production profile blocks store submission"
    - name: "secrets_not_in_app_config"
      verify: "Sensitive values are in EAS secrets or .env files, not hardcoded in app.json or app.config.js"
      fail_action: "Move secrets to EAS environment variables or local .env — never commit credentials"
  on_fail: "EAS configuration has issues that will cause build or submission failures — fix before triggering builds"
  on_pass: "EAS deployment configuration is valid"
_source:
  origin: "smedjen"
  inspired_by: "expo-skills-main"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for smedjen"
---

# Expo Deployment

EAS (Expo Application Services) handles the full Expo deployment lifecycle: native builds in the cloud, OTA JavaScript updates, and app store submission.

## EAS Build Overview

EAS Build runs cloud builds for iOS and Android without requiring local Xcode or Android Studio. Configuration lives in `eas.json` — one file, multiple profiles (development, preview, production). Each profile maps to a build type and distribution target.

Development builds replace Expo Go. They include your custom native code and connect to a local dev server. Preview builds go to internal testers (ad hoc / internal distribution). Production builds go to the stores.

## OTA vs Native Update Decision

**OTA update (EAS Update)**: JavaScript and assets only. No native code changes, no new SDK version, no new native dependencies. Fastest path — no review required, deploys in minutes.

**Native build required**: any change to `app.json` native fields (`bundleIdentifier`, `package`, `permissions`, splash screen), new native dependencies, SDK upgrade, or changes to `app.config.js` that affect native output.

Rule: if `expo prebuild` would produce a different output, you need a native build.

## Submission Workflow

EAS Submit handles store upload after a successful EAS Build. It reads credentials from EAS and submits the artifact. Apple requires an App Store Connect API key; Google requires a service account JSON.

Submission is decoupled from builds — submit any build by ID: `eas submit --platform ios --id <build-id>`.

## Key Rules

- Never use `expo publish` (legacy) — use `eas update` for all OTA updates.
- `runtimeVersion` must match between the build and the update. Mismatches cause silent update ignoring.
- Environment variables for builds go through EAS secrets, not `.env` files committed to git.
- Channels map to branches — keep `production` channel pointing only at production-ready branches.
- Always test OTA updates on a preview build before pushing to production channel.

See `references/process.md` for eas.json profile details, EAS Update channels, versioning strategy, CI/CD integration, internal distribution, and anti-patterns.
