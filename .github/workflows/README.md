# CI/CD Workflows

This directory contains the complete CI/CD pipeline for the **Prayer Times** Android app — from code validation to Google Play Store production deployment.

## Pipeline Overview

```
 Code Push/PR          deployment branch             Manual Triggers
      |                       |                            |
      v                       v                            v
 CI Validation ──success──> Release Pipeline       Promotion Workflows
 (lint/test)               (build/deploy)          (track-to-track)
```

### Deployment Flow (Normal Path)

```
  ┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌────────────────┐
  │ CI Validation │────>│  Release Pipeline │────>│ Promote to Alpha │────>│ Promote to     │
  │  (automatic)  │     │   (automatic)     │     │   (manual)       │     │ Production     │
  └──────────────┘     └──────────────────┘     └──────────────────┘     │  (manual)      │
                        │                                                 └────────────────┘
                        │ Outputs:
                        ├─ Play Store (Internal track, draft)
                        ├─ GitHub Release (APK + AAB)
                        └─ Slack Notification
```

### Emergency Path (Skip Testing)

```
  Release Pipeline ──> Internal Track ──> Production (max 20% rollout)
                         (bypasses Alpha/Beta testing)
```

---

## Workflow Files

### 1. `ci_validation.yml` — CI Validation

| Property    | Value                              |
| ----------- | ---------------------------------- |
| **Trigger** | PR to `main`, Push to `deployment` |
| **Runner**  | `ubuntu-latest`                    |
| **Timeout** | 30 minutes                         |
| **Jobs**    | 1 (`validate`)                     |

**What it does:**

| Step                   | Action                                              | Fail Behavior       |
| ---------------------- | --------------------------------------------------- | ------------------- |
| Setup Java 17          | `actions/setup-java@v4` (Temurin, Gradle cache)     | Blocks pipeline     |
| Setup Flutter 3.38.7   | `subosito/flutter-action@v2` (cached)               | Blocks pipeline     |
| Cache dependencies     | pub-cache, gradle caches/wrapper, android/.gradle   | Non-blocking        |
| Install dependencies   | `flutter pub get`                                   | Blocks pipeline     |
| Generate localizations | `flutter gen-l10n`                                  | `continue-on-error` |
| Check formatting       | `dart format --output=none --set-exit-if-changed .` | `continue-on-error` |
| Analyze code           | `flutter analyze`                                   | Blocks pipeline     |
| Run tests              | `flutter test`                                      | `continue-on-error` |
| Slack notification     | Only on `push` events (not PRs)                     | Always runs         |

**Key Detail:** `flutter analyze` is the only strict quality gate. Formatting and tests are soft-fail (`continue-on-error: true`).

---

### 2. `release.yml` — Release Pipeline

| Property        | Value                                                                    |
| --------------- | ------------------------------------------------------------------------ |
| **Trigger**     | Auto: CI Validation success on `deployment`. Manual: `workflow_dispatch` |
| **Runner**      | `ubuntu-latest` (per job)                                                |
| **Permissions** | `contents: write`, `actions: read`, `checks: write`                      |
| **Jobs**        | 4 (build → deploy-internal + github-release → notify)                    |

**Job Dependency Graph:**

```
        build
       /     \
      v       v
deploy-internal  github-release
       \     /
        v   v
        notify
```

#### Job 1: `build`

The core build job. Produces all artifacts and metadata used downstream.

**Steps breakdown:**

1. **Environment Setup** — Java 17, Flutter 3.38.7, Node.js 20
2. **Caching** — pub-cache, gradle, npm, android/.gradle
3. **Android Signing** — Decodes base64 keystore from `secrets.KEYSTORE_FILE`, creates `key.properties` with credentials
4. **Code Generation** — `flutter pub get` → `flutter gen-l10n` → `dart run build_runner build --delete-conflicting-outputs`
5. **Tests** — Runs `flutter test` if `test/` directory exists
6. **Version Code Resolution** — Smart auto-increment logic:
   - If `version_override` input provided: use that directly
   - Otherwise: query Google Play Store API across **all 4 tracks** (internal, alpha, beta, production)
   - Compares with pubspec.yaml build number and git commit count
   - Takes the maximum of all sources and adds 1
7. **Build APK** — `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=...`
8. **Build AAB** — `flutter build appbundle --release --obfuscate --split-debug-info=...`
9. **Upload Artifacts** — APKs (30 days), AAB (30 days), Debug symbols (90 days)

**Outputs passed to downstream jobs:**

| Output           | Description                    |
| ---------------- | ------------------------------ |
| `version`        | App version from pubspec.yaml  |
| `build_number`   | Auto-incremented version code  |
| `changelog`      | Git log since last tag         |
| `aab_size`       | AAB file size                  |
| `total_apk_size` | Combined APK size              |
| `apk_count`      | Number of APK splits           |
| `symbols_size`   | Debug symbols size             |
| `build_date`     | Formatted date (Asia/Dhaka TZ) |
| `build_duration` | Total build time               |

#### Job 2: `deploy-internal`

- Downloads the AAB artifact
- Uploads to Google Play **Internal Testing** track as **draft**
- Uses `r0adkll/upload-google-play@v1`

#### Job 3: `github-release`

- Downloads both APK and AAB artifacts
- Creates a GitHub Release tagged `v{version}`
- Includes installation instructions for each APK architecture:
  - `arm64-v8a` — Modern phones (2017+)
  - `armeabi-v7a` — Older phones
  - `x86_64` — Emulators & tablets

#### Job 4: `notify`

- Runs **always** (even on failure)
- Sends a rich Slack message with build status, version, sizes, duration
- Includes action buttons for Play Store and GitHub Releases

---

### 3. `promote-to-alpha.yml` — Promote Internal to Alpha

| Property            | Value                                 |
| ------------------- | ------------------------------------- |
| **Trigger**         | Manual only (`workflow_dispatch`)     |
| **Track Movement**  | `internal` → `alpha` (Closed Testing) |
| **Default Rollout** | `1.0` (100%)                          |
| **Update Priority** | `2` (low-medium)                      |

**Inputs:**

| Input                | Type   | Default | Description                |
| -------------------- | ------ | ------- | -------------------------- |
| `rollout_percentage` | string | `1.0`   | 0.1 to 1.0                 |
| `update_priority`    | choice | `2`     | 0-5 in-app update priority |

**Safety Checks:**

- Validates rollout percentage format (regex: `^0\.[0-9]+$|^1(\.0+)?$`)

**Action Used:** `kevin-david/promote-play-release@v1.1.0`

---

### 4. `promote-alpha-to-production.yml` — Promote Alpha to Production

| Property            | Value                             |
| ------------------- | --------------------------------- |
| **Trigger**         | Manual only (`workflow_dispatch`) |
| **Track Movement**  | `alpha` → `production`            |
| **Default Rollout** | `0.1` (10%)                       |
| **Update Priority** | `3` (medium)                      |

**Inputs:**

| Input                | Type   | Default | Description                       |
| -------------------- | ------ | ------- | --------------------------------- |
| `rollout_percentage` | string | `0.1`   | 0.01 to 1.0                       |
| `update_priority`    | choice | `3`     | 0-5 in-app update priority        |
| `confirmation`       | string | —       | Must type `PRODUCTION` to proceed |

**Safety Checks:**

- **Confirmation gate:** Must type exactly `PRODUCTION`
- Validates rollout percentage format
- Warns if rollout >= 50%

---

### 5. `promote-internal-to-production.yml` — Emergency Direct-to-Production

| Property            | Value                                         |
| ------------------- | --------------------------------------------- |
| **Trigger**         | Manual only (`workflow_dispatch`)             |
| **Track Movement**  | `internal` → `production` (skips Alpha/Beta!) |
| **Default Rollout** | `0.05` (5%)                                   |
| **Max Rollout**     | `0.2` (20%) — hard limit enforced             |
| **Update Priority** | `4` (high)                                    |

**Inputs:**

| Input                | Type   | Default | Description                              |
| -------------------- | ------ | ------- | ---------------------------------------- |
| `rollout_percentage` | string | `0.05`  | 0.01 to 0.2 (capped at 20%)              |
| `update_priority`    | choice | `4`     | 0-5 in-app update priority               |
| `confirmation`       | string | —       | Must type `SKIP-TESTING-PRODUCTION`      |
| `reason`             | string | —       | Emergency reason (required, audit trail) |

**Safety Checks:**

- **Confirmation gate:** Must type exactly `SKIP-TESTING-PRODUCTION`
- **Mandatory reason** for audit trail
- **Hard rollout cap at 20%** — untested builds cannot reach more than 20% of users
- Validates rollout percentage format

---

## Required Secrets

| Secret                | Used In                            | Description                            |
| --------------------- | ---------------------------------- | -------------------------------------- |
| `KEYSTORE_FILE`       | release.yml                        | Base64-encoded Android keystore (.jks) |
| `KEYSTORE_PASSWORD`   | release.yml                        | Keystore password                      |
| `KEY_PASSWORD`        | release.yml                        | Key password                           |
| `KEY_ALIAS`           | release.yml                        | Key alias                              |
| `PLAY_STORE_JSON_KEY` | release.yml, all promote workflows | Google Play API service account JSON   |
| `SLACK_WEBHOOK_URL`   | All workflows                      | Slack incoming webhook URL             |

## Required Repository Variables

| Variable       | Used In       | Description                                   |
| -------------- | ------------- | --------------------------------------------- |
| `PACKAGE_NAME` | All workflows | Android package name (e.g. `com.example.app`) |

## Pinned Versions

| Tool    | Version | Configured In          |
| ------- | ------- | ---------------------- |
| Java    | 17      | ci_validation, release |
| Flutter | 3.38.7  | ci_validation, release |
| Node.js | 20      | release                |

## Third-Party Actions Used

| Action                             | Version | Purpose                    |
| ---------------------------------- | ------- | -------------------------- |
| `actions/checkout`                 | v4      | Repository checkout        |
| `actions/setup-java`               | v4      | Java/Gradle setup          |
| `actions/setup-node`               | v4      | Node.js setup              |
| `subosito/flutter-action`          | v2      | Flutter SDK setup          |
| `actions/cache`                    | v4      | Dependency caching         |
| `actions/upload-artifact`          | v4      | Artifact upload            |
| `actions/download-artifact`        | v4      | Artifact download          |
| `r0adkll/upload-google-play`       | v1      | Play Store AAB upload      |
| `kevin-david/promote-play-release` | v1.1.0  | Play Store track promotion |
| `ncipollo/release-action`          | v1      | GitHub Release creation    |
| `slackapi/slack-github-action`     | v2.0.0  | Slack notifications        |
