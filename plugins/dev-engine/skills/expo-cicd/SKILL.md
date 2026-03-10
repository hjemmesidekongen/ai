---
name: expo-cicd
description: >
  CI/CD with EAS, GitHub Actions, app distribution, and automated build/deploy
  pipelines for Expo.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo cicd"
  - "expo github actions"
  - "eas ci"
  - "expo automation"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "expo_token_in_secrets"
      verify: "EXPO_TOKEN stored in GitHub Actions secrets, not hardcoded in workflow YAML"
      fail_action: "Move EXPO_TOKEN to repo secrets and reference via ${{ secrets.EXPO_TOKEN }}"
    - name: "preview_build_on_pr"
      verify: "PR workflow triggers a preview build and posts a QR code or build URL as a comment"
      fail_action: "Add PR workflow with eas build --profile preview and a comment step for the build URL"
    - name: "cache_configured"
      verify: "GitHub Actions workflow caches node_modules and Expo/EAS build cache layers"
      fail_action: "Add actions/cache step keyed on package-lock.json hash — uncached builds waste 3-5 min"
    - name: "channel_matches_branch"
      verify: "Production EAS Update channel only receives pushes from the production/main branch"
      fail_action: "Gate eas update --channel production behind a branch condition in the workflow"
  on_fail: "CI/CD pipeline has gaps that risk bad builds reaching users — fix before enabling automation"
  on_pass: "Expo CI/CD pipeline is correctly configured"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original skill, no port"
---

# expo-cicd

EAS + GitHub Actions is the standard Expo CI/CD stack. The split is clear: GitHub Actions handles the workflow orchestration; EAS handles the actual build and update infrastructure.

## Workflow Topology

Three workflows cover the full lifecycle:

**PR workflow** — triggers on `pull_request`. Runs lint, type-check, and tests. Triggers a preview EAS Build (internal distribution). Posts build URL or QR as a PR comment via `expo-github-action`.

**Main branch workflow** — triggers on push to `main`. Runs tests, then publishes an OTA update to the `staging` channel via `eas update`. Optionally triggers a production build if native changes are detected.

**Release workflow** — triggers on version tag or manual dispatch. Runs a production EAS Build and submits to stores via `eas submit`.

## Key Rules

- `EXPO_TOKEN` goes in GitHub Secrets — never in YAML. The token is account-scoped and rotatable.
- Cache `node_modules` keyed on `package-lock.json` hash. EAS also has its own remote build cache — enable it in `eas.json` with `"cache": { "disabled": false }`.
- For monorepos, set `"buildArtifactPaths"` and point `workingDirectory` in `eas.json` profiles to the app package.
- Detect native changes between commits using `git diff --name-only HEAD~1 HEAD` piped through a path filter — only trigger full native builds when `ios/`, `android/`, `package.json`, or `app.json` change.
- OTA updates (`eas update`) are fast (under 2 min). Native builds take 10-20 min. Avoid triggering native builds unnecessarily.

## Testing in CI

Run unit tests before any build step. For E2E: Maestro runs on real devices via EAS; Detox runs on simulators and is harder to configure in CI. Prefer Maestro for Expo E2E in CI.

## App Distribution

- **Internal testers**: use `--profile preview` with `"distribution": "internal"` — no store review.
- **TestFlight**: EAS Submit with `--platform ios` after a production iOS build.
- **Play Console internal track**: EAS Submit with `--platform android` submits an AAB.

## Versioning Automation

Expo can auto-increment `buildNumber` (iOS) and `versionCode` (Android) in EAS by setting `"autoIncrement": true` in the `eas.json` build profile. Keep `version` in `app.json` as the human-readable semver; let EAS manage the store integers.

See `references/process.md` for full workflow YAML examples, EAS config snippets, monorepo CI setup, secrets management, Detox/Maestro CI setup, and anti-patterns.
