---
name: expo-upgrading
description: >
  Expo SDK version migration — upgrade workflow, breaking changes, native
  module compatibility, and rollback strategy.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo upgrade"
  - "expo sdk"
  - "expo migration"
  - "expo version"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "pre_upgrade_branch"
      verify: "Upgrade is performed on a dedicated branch with a clean working tree before starting"
      fail_action: "Create upgrade branch — never upgrade on main with uncommitted changes"
    - name: "native_modules_audited"
      verify: "All native modules in package.json checked against SDK compatibility matrix before upgrade"
      fail_action: "Check expo.fyi/changelog and each module's releases for the target SDK version"
    - name: "config_plugins_verified"
      verify: "Config plugins run cleanly after upgrade (npx expo prebuild --clean passes)"
      fail_action: "Investigate prebuild errors — a broken config plugin blocks all native builds"
    - name: "rollback_documented"
      verify: "Rollback steps are noted before starting — git ref or branch to revert to"
      fail_action: "Document rollback path before proceeding — mid-upgrade failures are disruptive"
  on_fail: "Upgrade has unresolved risks — do not merge until all checks pass"
  on_pass: "Upgrade path is clean"
_source:
  origin: "dev-engine"
  inspired_by: "expo-skills-main"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Adapted from expo skill catalog for dev-engine knowledge base"
---

# expo-upgrading

Expo SDK upgrades are predictable but require discipline. Primary failure modes: native module incompatibility, broken config plugins, untested platform behavior. All three are avoidable with a structured pre-upgrade audit.

## Upgrade Workflow

`npx expo install expo@<version> --fix` — updates the SDK and aligns all bundled package versions. Never manually bump `expo-*` packages individually; version mismatches cause subtle runtime failures. Then run `npx expo-doctor` to surface remaining issues. For bare workflow, regenerate native directories: `npx expo prebuild --clean`.

## Pre-Upgrade Checklist

1. Clean working tree; create branch `upgrade/sdk-<version>`
2. Note current SHA for rollback
3. Read the SDK changelog at expo.fyi/changelog
4. Audit every native module against SDK compatibility matrix
5. Confirm Expo Go supports target SDK if used in dev

## Breaking Changes

Each SDK ships with a new React Native version — check both changelogs. Common categories: permission API surface changes (`expo-camera`, `expo-location`), Metro config shape changes, `babel-preset-expo` updates, `expo-router` API changes. Migration guide at `docs.expo.dev/workflow/upgrading-expo-sdk-walkthrough/`.

## Native Module Compatibility

`expo-*` modules are guaranteed compatible — install via `npx expo install`, never `npm install expo-*@latest`. For third-party modules: check the module's GitHub releases against the target RN version. If incompatible: wait for a release, pin the old SDK, or find an alternative.

## Config Plugins Verification

Run `npx expo prebuild --clean` and confirm it completes without errors. `--clean` fully regenerates `ios/` and `android/` — stale native files from a partial upgrade are a common hidden failure source. Common issues: deprecated plugin options, plugin ordering conflicts, `expo-modules-core` API changes in custom plugins.

## Testing Post-Upgrade

Physical device required — simulator misses camera, some location APIs, and push notifications. Test: permission flows, deep links, keyboard avoidance, OTA bundle receipt on old native binary (if using EAS Update).

## Rollback

Pre-upgrade: note the current git SHA. Mid-upgrade: `git checkout main && git branch -D upgrade/sdk-<version>`. Post-merge: `git revert -m 1 <merge-sha>`. EAS: republish last-good bundle to the production channel with `eas update`.

## Prebuild and Native Directory Management

Managed workflow: never edit `ios/` or `android/` directly. All customization via config plugins — this keeps the project prebuild-safe across upgrades. Write custom config plugins rather than dropping to bare workflow. See `references/process.md` for the full upgrade command sequence, version-specific notes, common pitfalls, and anti-patterns.