# Releasing & Versioning

CricStatz uses [Semantic Versioning](https://semver.org/) (semver) and GitHub Releases for APK distribution.

## How Versioning Works

A version number has three parts: **`MAJOR.MINOR.PATCH`** (e.g. `v0.2.1`).

| Change type | Which part to bump | Example |
|---|---|---|
| Bug fix or small patch | **PATCH** (z) | `v0.1.0` → `v0.1.1` |
| New feature (backwards-compatible) | **MINOR** (y) | `v0.1.1` → `v0.2.0` |
| Breaking change or production-ready milestone | **MAJOR** (x) | `v0.y.z` → `v1.0.0` |

When you bump a part, everything to the right resets to zero:
- Bump minor: `v0.1.3` → `v0.2.0` (patch resets)
- Bump major: `v0.5.2` → `v1.0.0` (minor and patch reset)

### Pre-1.0 (current phase)

While the major version is **0** (`v0.y.z`), the app is in initial development. The API and features can change freely. This is where CricStatz is right now.

- `v0.1.0` — first tagged release
- `v0.2.0` — new feature added
- `v0.2.1` — bug fix on that feature
- ...
- `v1.0.0` — app is stable, production-ready

### Post-1.0

Once you release `v1.0.0`, the version number becomes a promise to users:
- **MAJOR** bump = breaking changes (users need to adapt)
- **MINOR** bump = new features (fully backwards-compatible)
- **PATCH** bump = bug fixes only

## Release Workflows

CricStatz has two GitHub Actions workflows for releases:

### 1. Rolling "latest" release (`build-apk.yml`)

**Trigger:** Every push to `main` (including merged PRs).

**What it does:**
1. Builds the release APK
2. Uploads it to a GitHub Release tagged `latest`
3. Overwrites the previous "latest" release

**Download URL (always points to the newest build):**
```
https://github.com/DevLevelling/CricStatz/releases/latest/download/app-release.apk
```

The website's download button uses this URL. No manual steps needed — every push to main automatically updates the APK that users download.

### 2. Versioned release (`release-apk.yml`)

**Trigger:** Pushing a git tag matching `v*.*.*`.

**What it does:**
1. Builds the release APK
2. Creates a GitHub Release with that version tag
3. Auto-generates release notes from commits since the last tag

## How to Create a Versioned Release

### Step 1 — Choose the version number

Look at your [latest release](https://github.com/DevLevelling/CricStatz/releases) and decide what changed:

```
Current version: v0.1.0

Added a new feature?        → v0.2.0
Fixed a bug?                → v0.1.1
Major overhaul / stable?    → v1.0.0
```

### Step 2 — Tag and push

```bash
git tag v0.2.0
git push origin v0.2.0
```

That's it. The `release-apk.yml` workflow runs automatically and creates the release.

### Step 3 — Verify

Go to [github.com/DevLevelling/CricStatz/releases](https://github.com/DevLevelling/CricStatz/releases) and confirm:
- The release appears with the correct tag
- The APK is attached as a downloadable asset
- The auto-generated release notes list the right commits

## Tagging Tips

**Tag the current commit (most common):**
```bash
git tag v0.2.0
git push origin v0.2.0
```

**Tag a specific past commit:**
```bash
git tag v0.1.1 abc1234
git push origin v0.1.1
```

**List all existing tags:**
```bash
git tag -l
```

**Delete a tag (if you made a mistake):**
```bash
git tag -d v0.2.0                 # delete locally
git push origin --delete v0.2.0   # delete from remote
```

## Example Version History

Here's what a typical version progression looks like:

```
v0.1.0  — Initial tagged release
v0.1.1  — Fix: scoring bug on wide balls
v0.2.0  — Feature: team chat
v0.2.1  — Fix: chat message ordering
v0.3.0  — Feature: player statistics dashboard
v0.4.0  — Feature: match sharing via link
v1.0.0  — Production-ready stable release
v1.0.1  — Fix: crash on Android 14
v1.1.0  — Feature: tournament bracket mode
```

## Reference

- [Semantic Versioning specification (semver.org)](https://semver.org/)
- [`build-apk.yml`](../.github/workflows/build-apk.yml) — rolling latest release workflow
- [`release-apk.yml`](../.github/workflows/release-apk.yml) — versioned release workflow
