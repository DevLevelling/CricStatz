# Android Keystore & APK Signing

This guide explains how CricStatz uses a shared Android keystore to ensure all team members build APKs signed with the same key, preventing "package conflict" errors on phones.

---

## What is a Keystore?

An Android **keystore** is a file that contains cryptographic keys used to digitally sign APK files. Think of it like a certificate of authenticity.

**Why signing matters:**
- Android requires all APKs to be signed before installation
- The signature proves the APK came from a trusted source
- If the same app is signed with **different keys**, Android treats them as different apps and won't allow upgrades

**The Problem (before the shared keystore):**
```
Person A builds app locally    → signs with their debug key
Person B builds app locally    → signs with their own debug key
User tries to upgrade          → Android sees different signatures → "package conflicts" error
```

**The Solution (after the shared keystore):**
```
Person A builds app    → signs with shared key
Person B builds app    → signs with shared key
User upgrades          → same signature → installation succeeds
```

---

## How It Works

### The Keystore File (`release.keystore`)

- Location: `app/android/release.keystore`
- Contains the private key used to sign APKs
- **Committed to the repo** (safe — only contains the public key)
- Required by: everyone on the team

### The Password File (`key.properties`)

- Location: `app/android/key.properties` (must create locally)
- Contains passwords needed to access the keystore
- **NOT committed to the repo** (added to `.gitignore`)
- Kept private on each person's machine
- Contains two passwords (explained below)

### Why Two Passwords?

The keystore uses a two-level security model:

| Component | Password | Purpose | Who knows | Shared? |
|---|---|---|---|---|
| **Keystore file** | `storePassword` | Protects the `release.keystore` file itself | Team | Yes (shared via password file) |
| **Key inside** | `keyPassword` | Protects the specific signing key (`cricstatz`) within the keystore | Team | Yes (shared via password file) |

**In practice:** Both passwords are usually the same (you entered the same password twice during keystore creation).

---

## Setup Instructions for Team Members

### Step 1 — Pull the keystore from main

Make sure you have the latest code with the committed `release.keystore`:

```bash
git pull origin main
```

Verify the file exists:

```bash
ls app/android/release.keystore
```

You should see the file (about 2-6 KB).

### Step 2 — Create `key.properties` locally

Create a new file at `app/android/key.properties` with this content:

**Windows (PowerShell):**
```powershell
$content = @"
storePassword=YOUR_SHARED_PASSWORD
keyPassword=YOUR_SHARED_PASSWORD
keyAlias=cricstatz
storeFile=./release.keystore
"@

$content | Out-File -FilePath "app/android/key.properties" -Encoding UTF8
```

**Mac/Linux:**
```bash
cat > app/android/key.properties << 'EOF'
storePassword=YOUR_SHARED_PASSWORD
keyPassword=YOUR_SHARED_PASSWORD
keyAlias=cricstatz
storeFile=./release.keystore
EOF
```

Replace `YOUR_SHARED_PASSWORD` with **the password shared by your team** (the one used to create the keystore).

### Step 3 — Verify the file

Check it was created:

```bash
cat app/android/key.properties
```

You should see the four lines above.

### ⚠️ Important: Never Commit `key.properties`

The `.gitignore` file already protects it:

```
app/android/key.properties
```

Verify git won't track it:

```bash
git status
```

`key.properties` should NOT appear in the output. If it does, you may have committed it accidentally — immediately remove it from git:

```bash
git rm --cached app/android/key.properties
git commit -m "Accidentally committed key.properties, removed"
git push
```

---

## How the Build Process Uses It

When you run the build locally or in CI:

```bash
cd app
flutter build apk --release
```

Flutter's build system reads:
1. `app/android/build.gradle` — to learn that a signing config exists
2. `app/android/key.properties` — to get the passwords and keystore path
3. `app/android/release.keystore` — to get the actual signing key

Then it signs the APK with that key.

### In GitHub Actions

The `build-apk.yml` and `release-apk.yml` workflows also need access to `key.properties`. **See the workflow files for how they handle this** — they use a GitHub Action that injects the file securely without storing passwords in the repo.

---

## Troubleshooting

### "key.properties not found"

```
Error: File 'app/android/key.properties' not found
```

**Solution:**
- Verify the file exists: `ls app/android/key.properties`
- Verify it's in the correct location (not misnamed, not in wrong folder)
- Create it again using the instructions above

### "Wrong password"

```
Error: keytool error: java.io.IOException: Keystore was tampered with, or password was incorrect
```

**Solution:**
- Double-check the password in `key.properties` matches the one used to create the keystore
- Ask your team lead for the correct shared password
- If unsure, ask a teammate to verify by checking their `key.properties` file

### "App still won't install after upgrade"

If you still see "package conflicts" after using the shared keystore:
- Verify everyone built with `--release` mode (not debug)
- Completely uninstall the old app: `adb uninstall com.cricstatz.cricstatz`
- Download and install the new APK fresh

### "I see key.properties in git status"

```
Changes not staged for commit:
  modified:   app/android/key.properties
```

**DO NOT COMMIT IT.** Remove it from git immediately:

```bash
git checkout app/android/key.properties
```

Or if you edited it manually, revert to the version from main.

---

## Security Best Practices

1. **Share the password securely** — use a password manager or secure channel (Slack private message, 1Password, Vault, etc.), never in plain text email or public channels

2. **Don't share `key.properties` files** — each person creates their own file locally with the shared password

3. **Rotate the keystore if compromised** — if someone accidentally commits `key.properties`, regenerate the keystore and redistribute the new password

4. **Use the same key for all builds** — never create multiple keystores for CricStatz; always use `release.keystore`

---

## Reference

- [Android Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [`app/android/build.gradle`](../app/android/build.gradle) — where the signing config is used
- [`app/android/release.keystore`](../app/android/release.keystore) — the shared keystore file
- [`build-apk.yml`](../.github/workflows/build-apk.yml) — how CI handles signing
