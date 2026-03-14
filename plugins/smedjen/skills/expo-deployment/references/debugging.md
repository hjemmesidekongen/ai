# expo-deployment — Debugging Reference

## Common Debugging Scenarios

### EAS Build fails

**Symptom:** `eas build` exits with a non-zero code; build dashboard shows red status.
**Root cause:** Misconfigured `eas.json` profile — wrong build type, missing environment variables, or incompatible SDK version.
**Diagnosis:**
- Run `eas build --platform <ios|android> --profile <name> --local` to reproduce locally with full logs
- Check `eas.json` for the active profile: verify `distribution`, `channel`, `buildType`, and `env` fields
- Review the full build log on `expo.dev` — search for the first `error:` or `FAILURE:` line
- For Android: check `build.gradle` `compileSdkVersion` and `targetSdkVersion` match EAS expectations
- For iOS: verify `bundleIdentifier` in `app.json` matches the provisioning profile
**Fix pattern:** Correct the `eas.json` profile config. If SDK mismatch, run `npx expo install --fix` to align dependencies. Re-run the build.

### OTA update not applying

**Symptom:** `eas update` succeeds but the app still shows the old version after restart.
**Root cause:** Runtime version mismatch between the published update and the installed binary, or the update channel doesn't match the build's channel.
**Diagnosis:**
- Run `eas update:list` and verify the `runtimeVersion` of the latest update
- Compare against `runtimeVersion` in `app.json` or `app.config.js` for the running binary
- Check `updates.url` and `updates.requestHeaders` in app config
- On-device: enable `expo-updates` debug logging with `EXPO_DEBUG=1` and check console output
- Verify the build was created with the same `channel` that the update targets: `eas build:list --channel <name>`
**Fix pattern:** Align `runtimeVersion` across build and update. If native code changed, a new binary build is required — OTA cannot bridge native changes.

### App store rejection

**Symptom:** Apple or Google review rejects the submitted binary.
**Root cause:** Missing permission descriptions, privacy manifest gaps, or metadata policy violations.
**Diagnosis:**
- For iOS: read the rejection reason in App Store Connect under Resolution Center
- Check `Info.plist` for all `NS*UsageDescription` keys matching permissions your app uses
- Verify `PrivacyInfo.xcprivacy` exists and declares all required API reasons (required since Spring 2024)
- Run `npx expo config --type introspect` to see the final merged native config
- For Android: check `AndroidManifest.xml` for declared permissions; remove unused ones
- Review Google Play Console policy violation details for specific policy references
**Fix pattern:** Add missing permission strings to `app.json` `ios.infoPlist` or `android.permissions`. Generate privacy manifest entries. Rebuild and resubmit.

### Build credentials mismatch

**Symptom:** iOS build fails with signing errors; Android build fails with keystore issues.
**Root cause:** Local credentials don't match what EAS has stored, or provisioning profile expired.
**Diagnosis:**
- Run `eas credentials` and select the platform to inspect current state
- For iOS: run `eas credentials:check` — it validates certificate, provisioning profile, and bundle ID alignment
- Check if the Apple Developer certificate has expired at `developer.apple.com/account/resources/certificates`
- For Android: verify the keystore exists at the path specified and the alias matches: `keytool -list -keystore <path>`
- Compare `eas.json` `credentialsSource` setting — `remote` uses EAS-managed, `local` uses your files
**Fix pattern:** For expired iOS certs, revoke and regenerate via `eas credentials --platform ios`. For Android keystore issues, re-upload with `eas credentials --platform android`. Never lose the production upload keystore — it's irrecoverable.

### Binary incompatible with OTA

**Symptom:** OTA update published, but app crashes or shows a white screen after applying it.
**Root cause:** Native dependency changed since the last binary build — the JS bundle references a native module that doesn't exist in the installed binary.
**Diagnosis:**
- Compare `package.json` at the time of the last binary build vs. the current update
- Look for added/upgraded packages that include native code: `npx expo install --check`
- Check if `runtimeVersion` policy is set to `"appVersion"` (dangerous — doesn't track native changes) vs. `"fingerprint"` (recommended)
- Review `expo-updates` error logs on-device for `NativeModulesProxy` or `requireNativeComponent` errors
- Run `npx expo-doctor` to detect native/JS mismatches
**Fix pattern:** Switch `runtimeVersion` policy to `"fingerprint"` so native changes automatically trigger a new runtime version. Rebuild the binary whenever native deps change, then publish OTA updates against the new runtime version.

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| EAS CLI diagnostics | Check project config health | `eas diagnostics` |
| Expo Doctor | Detect dependency mismatches | `npx expo-doctor` |
| Config introspection | See final merged native config | `npx expo config --type introspect` |
| Local build | Reproduce build failures locally | `eas build --local --platform <ios\|android>` |
| Credentials check | Validate signing setup | `eas credentials` |
| Update inspector | List published updates with metadata | `eas update:list --branch <name>` |
| Fingerprint | Compare native fingerprints | `npx @expo/fingerprint` |
| Build logs | Full build output | View on `expo.dev/accounts/<account>/builds/<id>` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
