# APK Installation & Compatibility Troubleshooting

This guide covers common issues when installing or updating CricStatz APK on Android devices.

---

## Overview

CricStatz is distributed as an APK file (Android application package). Most installations work seamlessly, but certain scenarios can cause issues. This guide explains why they happen and how to fix them.

---

## "App not installed" / "Package conflicts" Error

### What's happening?

Android has installed **two different versions of the same app** that were signed with different cryptographic keys. This is a security feature — Android won't let you upgrade an app if the signature doesn't match.

**Common causes:**
1. You previously installed an older build signed with a different key
2. Different team members built the app locally and shared different APKs
3. Your phone somehow cached the old app's signature in the system package manager

### Why this happens

Apps must be "signed" with a cryptographic key before installation. Think of it like a certificate of authenticity:
- Old APK: signed with Key A
- New APK: signed with Key B
- Android: "These look like different apps. Blocked."

**This is by design** — Android prevents signature mismatches to protect your phone from malicious versions of legitimate apps.

### How to fix it

#### Solution 1: Simple uninstall (works on most phones)

1. Go to **Settings → Apps**
2. Find and tap **CricStatz**
3. Tap **Uninstall**
4. **Restart your phone** (important!)
5. Download and install the new APK fresh

This clears the app and its cache, allowing the new signature to be recognized.

#### Solution 2: Clear package manager cache (if Solution 1 fails)

If you still get "package conflicts" after uninstalling, the system package manager may be caching the old signature:

1. Go to **Settings → Apps**
2. Toggle **Show system apps** (usually a menu option)
3. Find and tap **Package Manager** (or **Package Installer**)
4. Tap **Storage** → **Clear cache**
5. Go back and uninstall CricStatz again
6. Install the new APK

#### Solution 3: ADB (for developers familiar with command line)

```bash
# Completely remove the app and its data
adb uninstall com.cricstatz.cricstatz

# Then install the new APK
adb install path/to/CricStatz.apk
```

#### Solution 4: Recovery mode wipe (most aggressive, last resort)

If none of the above work, boot into Android Recovery and wipe the cache partition:

1. Power off your phone
2. Hold **Volume Down + Power** until recovery menu appears
3. Select **Wipe cache partition**
4. Reboot and reinstall the APK

⚠️ This wipes the system cache and may affect other apps temporarily, but should resolve signature caching issues.

---

## Why This Is a One-Time Issue

CricStatz now uses a **shared Android keystore**, meaning:
- All team members build APKs with the **same signing key**
- Every new version is signed consistently
- Your phone will recognize all future updates as coming from the same source

**After you install the latest version**, you'll never see this error again. All updates will upgrade smoothly.

---

## Device-Specific Issues

### Motorola (Moto) Devices

Moto devices have a known quirk where the system package manager cache is particularly stubborn.

**If you have a Moto phone:**
1. Try Solution 1 (uninstall + restart)
2. If that fails, try Solution 2 (clear Package Manager cache)
3. If still failing, try Solution 3 (ADB) or Solution 4 (Recovery wipe)

Moto devices should work perfectly once the initial installation is done.

### Samsung Devices

Samsung's One UI typically handles app cache well. Solution 1 almost always works.

### Pixel / Stock Android

Works smoothly. Solution 1 should resolve any issues instantly.

---

## How to Prevent This (for developers)

If you're building CricStatz locally:

1. **Always use the shared keystore** (`app/android/release.keystore`)
2. **Never change signing keys** between builds
3. Create `app/android/key.properties` with the shared password
4. Build with: `flutter build apk --release`

See [`docs/SIGNING.md`](SIGNING.md) for detailed setup instructions.

If you accidentally built with a different key:
- Create a new APK with the shared keystore
- Tell users they need to uninstall and reinstall once
- All future updates will work smoothly

---

## Still Having Issues?

If none of the above solutions worked:

1. **Check the APK source** — make sure you downloaded from GitHub Releases (`github.com/DevLevelling/CricStatz/releases`)
2. **Check your Android version** — CricStatz requires Android 5.0 (API 21) or higher
3. **Check available storage** — you need at least 100 MB free
4. **Try a different device** — test on another phone to narrow down device-specific issues
5. **Report the issue** — if it's reproducible, open a GitHub issue with:
   - Your phone model
   - Android version
   - Exact error message
   - What solutions you already tried

---

## Reference

- [Android app signing documentation](https://developer.android.com/studio/publish/app-signing)
- [`docs/SIGNING.md`](SIGNING.md) — How the shared keystore works
- [`docs/RELEASING.md`](RELEASING.md) — How APKs are built and distributed
