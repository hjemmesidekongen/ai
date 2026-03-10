# expo-upgrading — Process Reference

## Full Upgrade Command Sequence

```bash
# 1. Create upgrade branch
git checkout -b upgrade/sdk-<version>

# 2. Run the Expo upgrade command (aligns all expo/* package versions)
npx expo install expo@<version> --fix

# 3. Audit for version mismatches and known issues
npx expo-doctor

# 4. Fix all reported issues, then install any updated deps
npm install  # or yarn / pnpm install

# 5. Regenerate native directories (bare workflow or after running prebuild)
npx expo prebuild --clean

# 6. Verify native build
npx expo run:ios
npx expo run:android

# 7. Start Metro and test on device
npx expo start --clear
```

---

## Pre-Upgrade Checklist

Before touching any files:

- [ ] Clean working tree: `git status` shows no uncommitted changes
- [ ] Upgrade branch created: `upgrade/sdk-<version>`
- [ ] Current SHA noted for rollback: `git rev-parse HEAD`
- [ ] SDK changelog read: expo.fyi/changelog for target version
- [ ] React Native version delta identified (check what RN version the target SDK ships with)
- [ ] All native modules in `package.json` audited against SDK compatibility
- [ ] Expo Go support confirmed for target SDK (if using Expo Go in dev)
- [ ] EAS build profiles reviewed if using EAS

---

## Breaking Changes Assessment

### What to Check Per SDK Release

Each SDK upgrade bundles a new React Native version. Both changelogs matter:

| Source | URL |
|--------|-----|
| Expo SDK changelog | expo.fyi/changelog |
| React Native changelog | github.com/facebook/react-native/blob/main/CHANGELOG.md |
| Expo SDK migration guide | docs.expo.dev/workflow/upgrading-expo-sdk-walkthrough/ |

### Common Breaking Change Categories

**Permission APIs** — `expo-location`, `expo-camera`, `expo-contacts` rework permission APIs roughly every 2–3 SDKs. Check the module's own CHANGELOG.

**Metro config** — `metro.config.js` shape changes between major versions. Expo provides a migration guide entry when this happens.

**Babel preset** — `babel-preset-expo` sometimes requires updated config. Run `npx expo-doctor` to detect this.

**expo-router** — File-based routing APIs evolve between minor versions of expo-router which ships with the SDK. Check expo-router changelog separately.

**expo-modules-core** — The native module API changes occasionally. Affects custom native modules.

---

## Native Module Compatibility

### Audit Process

For each native module in `package.json`:

1. Open the module's GitHub repository
2. Check releases or CHANGELOG for the target React Native version
3. If no explicit support listed, check open issues for the target RN version
4. For `@react-native-community/*` packages: check the community org on GitHub

### Resolution Options

| Situation | Action |
|-----------|--------|
| Module has a compatible release | `npm install module@<compatible-version>` |
| Module is incompatible, update pending | Pin old SDK, wait for module release |
| Module is abandoned | Find maintained alternative |
| Module needs a one-line fix | Fork + patch, open upstream PR |

### Expo-Maintained Modules

All `expo-*` packages are guaranteed compatible with the matching SDK version. Install via:

```bash
npx expo install expo-camera expo-location  # Expo install picks correct version automatically
```

Never `npm install expo-camera@latest` independently — it may pull a version incompatible with your SDK.

---

## Config Plugins Verification

Config plugins modify `ios/` and `android/` during prebuild. A broken config plugin is a build blocker.

### Run Prebuild

```bash
npx expo prebuild --clean
```

`--clean` fully regenerates native directories. Without it, stale native files can mask config plugin errors.

### Common Config Plugin Failures

**Deprecated plugin options** — Some plugins change their option schema between SDK versions. Error message usually names the offending property.

```json
// Before (SDK 50)
["expo-camera", { "cameraPermission": "..." }]

// After (SDK 51+) — check the plugin's own docs for current schema
["expo-camera", { "cameraPermission": "...", "microphonePermission": "..." }]
```

**Plugin ordering conflicts** — Some plugins must run before others. If prebuild succeeds but the app crashes on first launch, check plugin order in `app.json`.

**Custom config plugins** — If you wrote a custom plugin, check if `expo-modules-core` APIs it uses have changed.

---

## Testing Strategy Post-Upgrade

### Minimum Test Surface

Run all of these before merging:

- [ ] Build on physical iOS device (not just simulator)
- [ ] Build on physical Android device (not just emulator)
- [ ] All permission request flows (camera, location, notifications, etc.)
- [ ] Deep link entry points
- [ ] Push notification receipt (if in use)
- [ ] OTA update receipt — publish a test update and confirm it loads on the new native binary

### E2E Tests

If a Detox or Maestro suite exists, run it fully. Do not skip — behavioral regressions are common in native module updates.

### Smoke Test Checklist

- [ ] App launches without crash
- [ ] Navigation flows work (tab nav, stack nav, modals)
- [ ] All permission flows prompt correctly
- [ ] Images load (verify expo-image or Image component)
- [ ] Forms and keyboard avoidance work
- [ ] Haptics and native feedback respond correctly

---

## Rollback Plan

### Before Starting

```bash
# Save the rollback point
git rev-parse HEAD > /tmp/expo-upgrade-rollback-sha.txt
# Or just note the branch: main is at commit abc1234
```

### Mid-Upgrade Rollback

```bash
# Discard all upgrade changes
git checkout main
git branch -D upgrade/sdk-<version>
```

### Post-Merge Rollback

```bash
# Revert the merge commit
git revert -m 1 <merge-commit-sha>
git push origin main
```

### EAS Rollback

If using EAS Update for OTA, republish the last known-good bundle to the production channel:

```bash
eas update --channel production --branch last-good-branch
```

If native binary was already published, the old binary + old bundle combination must still be compatible. Test this in staging before production rollback.

---

## Multi-SDK Support Period

Expo maintains compatibility for two SDK versions in Expo Go at a time. For custom native builds (EAS), you're not constrained by Expo Go.

If you have multiple apps or a staged rollout:

- Use EAS build profiles to separate SDK versions
- Keep the upgrade branch alive until rollout is complete
- Do not delete old native binaries from app stores until confident in the upgrade

---

## Prebuild and Native Directory Management

### Managed Workflow (no ios/ or android/ in repo)

All native customization via config plugins. Regenerate anytime:

```bash
npx expo prebuild --clean
```

Add `ios/` and `android/` to `.gitignore`.

### Bare Workflow (ios/ and android/ committed)

Manual native changes persist but must survive prebuild. Options:

1. Keep all customization in config plugins — prebuild-safe, recommended
2. Apply manual patches after prebuild via a `postinstall` or CI script

If you have manual native changes that can't be migrated to config plugins, document them explicitly and check them after every prebuild.

---

## Version-Specific Migration Notes

### General Pattern

Each SDK version's migration guide lives at:
`docs.expo.dev/workflow/sdk-<version>-migration/`

Common patterns that repeat across SDK versions:

- Permission API surface gets more granular (iOS privacy manifests, Android permissions)
- Metro config adds new options (usually optional, but `expo-doctor` flags if needed)
- `app.json` / `app.config.js` schema gains new fields (non-breaking, but worth reviewing)

### Checking What Changed in a Module

```bash
# See which packages changed in the upgrade
git diff package.json
git diff package-lock.json | grep '"version"' | head -40
```

---

## Common Upgrade Pitfalls

### Running npm install before expo install

```bash
# Bad — pulls latest versions, breaks SDK version alignment
npm install

# Good — align Expo package versions first
npx expo install expo@<version> --fix
npm install  # only after expo install has set correct peer versions
```

### Not running --clean on prebuild

Without `--clean`, stale native files accumulate. This causes hard-to-debug runtime errors that disappear after a clean prebuild. Always use `--clean` on upgrade.

### Forgetting expo-doctor

`npx expo-doctor` catches ~80% of upgrade issues before they become runtime failures. Run it after `expo install` and fix everything it reports.

### Testing only on simulator

Simulators don't exercise camera, some location APIs, push notifications, or hardware-specific behavior. Always test on physical device before marking an upgrade complete.

### Skipping OTA compatibility testing

If using EAS Update, old native binaries in the field will receive the new JS bundle. Test that the new bundle loads correctly on the previous native binary version before rolling out.

---

## Anti-Patterns

### Manual version bumps of expo/* packages

```bash
# Bad
npm install expo-camera@latest

# Good — Expo install picks the compatible version
npx expo install expo-camera
```

### Upgrading without a dedicated branch

Always upgrade on a branch. Never directly on main — upgrade complications mid-way leave main in a broken state.

### Committing ios/ and android/ without rebuilding post-upgrade

If native directories are committed, regenerate them via prebuild after upgrading, then commit the regenerated output. Committing outdated native files from before the upgrade causes subtle build failures.

### Keeping manual native changes outside config plugins

Manual edits to `ios/` or `android/` are wiped by `--clean`. If you need native customization, write a config plugin. This is the only way to keep customizations upgrade-safe.
