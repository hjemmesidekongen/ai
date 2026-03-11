# Expo Deployment — Process Reference

## eas.json Profiles

`eas.json` lives at the project root and defines build profiles. Each profile configures distribution type, environment, and build behavior.

```json
{
  "cli": { "version": ">= 10.0.0" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": { "simulator": true }
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview"
    },
    "production": {
      "distribution": "store",
      "channel": "production"
    }
  },
  "submit": {
    "production": {
      "ios": { "ascAppId": "123456789" },
      "android": { "serviceAccountKeyPath": "./service-account.json" }
    }
  }
}
```

**Build types:**
- `developmentClient: true` — builds a dev client (replaces Expo Go)
- `distribution: "internal"` — ad hoc (iOS) or APK (Android) for testers
- `distribution: "store"` — IPA/AAB for App Store / Google Play

**Custom native configs:** Use `prebuildCommand` to run custom steps before the native build. For fully custom native code, set `"buildType": "generic"` instead of managed.

## EAS Update (OTA)

OTA updates push JS bundles and assets to running apps without a new store release. The app checks for updates on launch and downloads them in the background (default) or foreground (configurable).

**Channel and branch mapping:**

```
Production app  →  "production" channel  →  main branch
Preview build   →  "preview" channel     →  staging branch
```

Publish an update:

```bash
eas update --branch main --message "Fix checkout crash"
# or target a channel directly
eas update --channel production --message "Fix checkout crash"
```

**Rollback:** EAS Update stores a history of updates per branch. Roll back by republishing a previous bundle or by pointing the channel to an older branch state. There is no single `eas rollback` command — re-publish the last known-good update.

**Update compatibility:** The app only applies an update if the `runtimeVersion` matches the build's runtime version. An update built against SDK 51 will not apply to an app built against SDK 50.

**Checking update status:**

```bash
eas update:list --branch main
eas update:view <update-id>
```

## EAS Submit

EAS Submit uploads a completed build artifact to the App Store or Google Play.

**iOS (App Store Connect):**
1. Create an App Store Connect API key (Admin role).
2. Add it to EAS: `eas credentials` → select iOS → API Key.
3. Submit: `eas submit --platform ios --latest` or `--id <build-id>`.

**Android (Google Play):**
1. Create a Google Play service account with Release Manager role.
2. Download the JSON key.
3. Store path in `eas.json` under `submit.production.android.serviceAccountKeyPath` (never commit this file).
4. Submit: `eas submit --platform android --latest`.

**Submitting a specific build:**

```bash
eas submit --platform ios --id <eas-build-id>
```

Useful when you want to submit a build that was created earlier without triggering a new build.

## app.json / app.config.js Configuration

`app.json` is static. `app.config.js` is dynamic — use it when you need environment-based values.

```js
// app.config.js
export default ({ config }) => ({
  ...config,
  name: process.env.APP_VARIANT === "production" ? "MyApp" : "MyApp (Dev)",
  ios: {
    bundleIdentifier:
      process.env.APP_VARIANT === "production"
        ? "com.example.myapp"
        : "com.example.myapp.dev",
  },
  android: {
    package:
      process.env.APP_VARIANT === "production"
        ? "com.example.myapp"
        : "com.example.myapp.dev",
  },
});
```

Separate bundle identifiers for dev/prod allow both to install on the same device simultaneously.

## Versioning Strategy

**`runtimeVersion`** controls OTA update compatibility. Two policies:

- `"fingerprint"` (recommended for SDK-managed projects): EAS automatically computes a hash of native dependencies. Updates are only applied to builds with a matching fingerprint.
- `"appVersion"` or manual string: you control the value. Riskier — easy to forget to bump.

```json
// app.json
{
  "expo": {
    "runtimeVersion": {
      "policy": "fingerprint"
    }
  }
}
```

**`buildNumber` (iOS) / `versionCode` (Android):** Must increment with every store submission. EAS can auto-increment:

```json
// eas.json
{
  "build": {
    "production": {
      "autoIncrement": true
    }
  }
}
```

**`version` (semver):** User-visible version. Increment manually on meaningful releases.

## Environment Variables in EAS

EAS secrets are stored server-side and injected at build time. They are never exposed in the build artifact.

```bash
# Set a secret
eas secret:create --scope project --name API_URL --value "https://api.example.com"

# List secrets
eas secret:list
```

Access in code via `process.env.API_URL`. For local development, use a `.env` file (never commit it — add to `.gitignore`).

**Variable visibility tiers:**
- EAS secrets: build-time only, server-side, most secure.
- `extra` field in `app.config.js`: bundled into the app, readable at runtime via `expo-constants`. Not secret.
- `EXPO_PUBLIC_*` env vars: bundled at build time, accessible via `process.env`. Not secret.

Never put API keys or credentials in `extra` or `EXPO_PUBLIC_*`.

## Internal Distribution

**Ad hoc (iOS):** Requires device UDIDs registered in Apple Developer portal. EAS can auto-register devices: `eas device:create`. Build with `distribution: "internal"` and share the install URL from the EAS dashboard.

**Enterprise (iOS):** Requires Apple Developer Enterprise Program. Distribution profile set to `enterprise` in `eas.json`.

**Android internal:** EAS produces an APK for `distribution: "internal"`. Share the install link directly — no Play Store involved.

**Expo Orbit** (formerly Internal Distribution): Desktop app that simplifies installing development and preview builds on connected devices and simulators.

## CI/CD Integration

EAS builds trigger from CI the same way they do locally — using the EAS CLI authenticated with a token.

```bash
# GitHub Actions example
- name: Build and submit
  env:
    EXPO_TOKEN: ${{ secrets.EXPO_TOKEN }}
  run: |
    npx eas-cli build --platform all --non-interactive
    npx eas-cli submit --platform all --non-interactive --latest
```

Set `EXPO_TOKEN` as a CI secret (generate at expo.dev → Account Settings → Access Tokens). Never commit tokens.

**Useful flags for CI:**
- `--non-interactive`: disables prompts, required in CI.
- `--no-wait`: triggers the build and exits — poll status separately with `eas build:list`.
- `--local`: runs the build locally instead of in the cloud (useful for debugging native build issues).

## Preview Builds

Preview builds are internal-distribution builds connected to a non-production update channel. Testers install once; subsequent JS changes push as OTA updates to the preview channel.

Workflow:
1. Build once: `eas build --profile preview --platform all`
2. Share the install URL with QA.
3. For each JS change: `eas update --channel preview --message "Fix X"` — testers get the update on next launch.

This eliminates the need to redistribute a new binary for every iteration during QA.

## Anti-Patterns

**Publishing to the wrong channel.** Pushing a broken update to `production` affects all production users immediately. Always test on `preview` first. Use `--channel` explicitly to avoid accidental production pushes.

**Mismatched runtimeVersion.** An update built against a different native configuration than the installed app will be silently ignored. Use `fingerprint` policy to automate this, or manually track runtime versions.

**Hardcoding secrets in app.config.js.** Values in `extra` or returned from `app.config.js` are bundled into the app binary and readable by anyone who extracts the bundle. Use EAS secrets for anything sensitive.

**Committing `credentials.json`.** EAS manages credentials server-side. The local `credentials.json` (if generated) should be in `.gitignore` — it contains signing keys.

**Using `expo publish` with SDK 49+.** `expo publish` is deprecated. It does not support channels, fingerprinting, or the EAS Update rollout model. Always use `eas update`.

**Skipping `autoIncrement` and forgetting to bump `versionCode`.** Google Play rejects uploads where `versionCode` is not strictly greater than the current live version. Let EAS handle this automatically.

**Building production without testing a preview build.** The production profile should never be the first build you test. Always validate on a development or preview build before cutting a production artifact.
