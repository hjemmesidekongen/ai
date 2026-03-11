# expo-cicd — Process Reference

## GitHub Actions Workflow Files

### PR Workflow (`.github/workflows/pr.yml`)

```yaml
name: PR Check
on:
  pull_request:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run tsc -- --noEmit

      - name: Unit tests
        run: npm test -- --ci

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Build preview
        id: build
        run: eas build --platform all --profile preview --non-interactive --json > build-output.json

      - name: Comment build URL on PR
        uses: actions/github-script@v7
        with:
          script: |
            const output = require('./build-output.json');
            const url = output[0]?.buildDetailsPageUrl ?? 'Build submitted';
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `Preview build: ${url}`
            });
```

### Main Branch Workflow (`.github/workflows/main.yml`)

```yaml
name: Deploy to Staging
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2  # needed for native change detection

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - run: npm ci

      - run: npm test -- --ci

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Detect native changes
        id: native
        run: |
          CHANGED=$(git diff --name-only HEAD~1 HEAD | grep -E '(ios/|android/|package\.json|app\.json|app\.config\.js)' | wc -l)
          echo "changed=$CHANGED" >> $GITHUB_OUTPUT

      - name: Publish OTA update
        run: eas update --channel staging --message "main: ${{ github.sha }}" --non-interactive

      - name: Trigger native build (if needed)
        if: steps.native.outputs.changed > 0
        run: eas build --platform all --profile production --non-interactive
```

### Release Workflow (`.github/workflows/release.yml`)

```yaml
name: Release
on:
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - run: npm ci

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Build production
        id: build
        run: eas build --platform all --profile production --non-interactive

      - name: Submit to stores
        run: |
          eas submit --platform ios --latest --non-interactive
          eas submit --platform android --latest --non-interactive
```

---

## EAS Build in CI

### eas.json Profile Setup

```json
{
  "cli": { "version": ">= 7.0.0" },
  "build": {
    "development": {
      "distribution": "internal",
      "android": { "buildType": "apk" },
      "ios": { "simulator": true }
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview",
      "cache": { "disabled": false },
      "autoIncrement": false
    },
    "production": {
      "distribution": "store",
      "channel": "production",
      "cache": { "disabled": false },
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "team@example.com",
        "ascAppId": "1234567890"
      },
      "android": {
        "serviceAccountKeyPath": "./google-service-account.json",
        "track": "internal"
      }
    }
  }
}
```

---

## OTA Updates on Merge

```bash
# Publish to staging channel on main merge
eas update --channel staging --message "Deploy: $COMMIT_SHA"

# Promote staging update to production after QA sign-off
eas update --channel production --message "Release: v1.2.3"
```

Update channels map to `eas.json` build profiles. A build is subscribed to one channel. Multiple branches can push to staging; only the release process touches production.

---

## Build Caching

EAS remote cache stores build artifacts between runs. Enable per profile:

```json
"preview": {
  "cache": {
    "disabled": false,
    "cacheDefaultPaths": true,
    "customPaths": ["node_modules/.cache"]
  }
}
```

In GitHub Actions, also cache `node_modules` locally:

```yaml
- uses: actions/cache@v4
  with:
    path: node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
    restore-keys: ${{ runner.os }}-node-
```

---

## Secrets Management

Store `EXPO_TOKEN` in GitHub repo secrets (`Settings → Secrets → Actions`). Reference in YAML:

```yaml
token: ${{ secrets.EXPO_TOKEN }}
```

For runtime app secrets (API keys, etc.), use EAS environment variables:

```bash
# Set a secret in EAS (prompts for value)
eas secret:create --scope project --name API_KEY --type string

# List secrets
eas secret:list
```

Secrets set via EAS are injected at build time as environment variables. They are never stored in the repo.

For Apple credentials (certificates, provisioning profiles): let EAS manage them automatically with `"credentialsSource": "remote"` in `eas.json`. EAS stores them encrypted in its own vault.

---

## Monorepo CI Setup

For a Turborepo or npm workspaces monorepo with the Expo app in `apps/mobile/`:

```json
// eas.json at monorepo root
{
  "build": {
    "production": {
      "workingDirectory": "apps/mobile",
      "env": {
        "TURBO_TEAM": "your-team",
        "TURBO_TOKEN": "$TURBO_TOKEN"
      }
    }
  }
}
```

In GitHub Actions, install from the monorepo root (`npm ci`) before running EAS — EAS picks up `workingDirectory` from `eas.json`.

---

## Testing in CI

### Unit Tests

Run before any build:

```yaml
- run: npm test -- --ci --coverage --watchAll=false
```

### Maestro (E2E on real devices via EAS)

Maestro runs on EAS Device — no simulator setup required in CI:

```yaml
- name: Run E2E tests
  run: eas build --profile preview --platform android --non-interactive && eas device:test
```

Maestro flows live in `.maestro/` and are referenced in `eas.json` under `"test"`.

### Detox (E2E on simulators)

Detox requires a macOS runner with Xcode:

```yaml
runs-on: macos-latest
steps:
  - run: brew tap wix/brew && brew install applesimutils
  - run: npx detox build --configuration ios.sim.release
  - run: npx detox test --configuration ios.sim.release --headless
```

Detox CI is expensive (macOS runners cost 10x Linux). Only use it if Maestro doesn't cover your test scenarios.

---

## App Distribution

### Internal Distribution (no store review)

```bash
# Build for internal distribution
eas build --profile preview --platform all

# Share via EAS dashboard link or QR code
# Testers install directly — no TestFlight or Play Console needed
```

### TestFlight

```bash
# Build production iOS
eas build --profile production --platform ios

# Submit to TestFlight
eas submit --platform ios --latest
# Or by build ID: eas submit --platform ios --id <build-id>
```

Apple requires an App Store Connect API key in EAS credentials.

### Play Console Internal Track

```bash
# Build production Android (AAB)
eas build --profile production --platform android

# Submit to internal track
eas submit --platform android --latest
```

Google requires a service account JSON with release manager permissions.

---

## Versioning Automation

```json
// eas.json — auto-increment store version integers
{
  "build": {
    "production": {
      "autoIncrement": true
    }
  }
}
```

With `autoIncrement: true`, EAS increments `buildNumber` (iOS) and `versionCode` (Android) automatically. Keep `version` in `app.json` as semver managed by your release process.

To bump `version` programmatically in CI:

```bash
# Using npm version before triggering a build
npm version patch --no-git-tag-version
```

---

## Release Channels

```
Branch         → EAS Update Channel   → Audience
──────────────────────────────────────────────────
feature/*      → (no auto-update)     → dev builds only
main           → staging              → internal QA
release tag    → production           → all users
```

Never push to the production channel from a branch other than the release branch. Enforce this with a branch condition in the GitHub Actions workflow:

```yaml
- name: Publish to production
  if: startsWith(github.ref, 'refs/tags/v')
  run: eas update --channel production --non-interactive
```

---

## Anti-Patterns

**Hardcoding EXPO_TOKEN in YAML** — token is account-scoped and gives full EAS access. One leak exposes all projects. Always use secrets.

**Triggering native builds on every push** — native builds take 10–20 min and consume EAS build credits. Gate them behind native change detection.

**Pushing to production channel from main** — staging and production channels must be separated. Merging to main should go to staging; production only on explicit release.

**Skipping OTA update testing** — always QA an OTA update on a preview build before pushing to the production channel. A bad JS bundle shipped via OTA requires a new native build to roll back if `runtimeVersion` doesn't match.

**Storing Google service account JSON in the repo** — use EAS secrets or GitHub Secrets and mount at build time. Never commit `google-service-account.json`.

**Running E2E tests on every PR** — E2E on EAS Device is slow and expensive. Run unit tests on every PR; reserve full E2E for merge to main or release gates.

**Using `expo publish` (legacy)** — `expo publish` is deprecated. All OTA updates go through `eas update`. The legacy `expo-updates` publish flow is incompatible with EAS channels.
