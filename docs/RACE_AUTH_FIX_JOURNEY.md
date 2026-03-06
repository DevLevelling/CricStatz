# The Auth Flow Bug: A Debugging Journey

## The Problem

After implementing Google OAuth sign-in with Supabase in CricStatz, the app had a critical bug: **after signing in via Google, the app would skip the `ProfileSetupScreen` and jump straight to `HomeScreen`** — even for brand-new users who had no profile in the database.

This worked *sometimes* in debug mode, but **never** in release mode.

---

## The Architecture

The app uses a simple auth-gated routing pattern:

```
AuthProvider (ChangeNotifier)
  ├── isLoading      → show spinner
  ├── isSignedIn     → false → LoginScreen
  ├── isProfileComplete → false → ProfileSetupScreen
  └── isProfileComplete → true  → HomeScreen
```

The `AuthProvider` listens to Supabase's `onAuthStateChange` stream for auth events (`signedIn`, `signedOut`, `initialSession`, etc.), loads the user's profile from the database, and notifies the UI.

---

## Iteration 1: Added `initialSession` handling

### Assumption
> "We're not handling the `initialSession` event. Maybe the stream fires that on app startup and we're ignoring it."

### Change
Added a case for `AuthChangeEvent.initialSession` in the stream listener to trigger profile loading.

### Result
**Partially worked in debug mode.** Still failed intermittently. The profile would sometimes load, sometimes not. Release mode still broken.

### Why it failed
The real issue wasn't *which* events we handled — it was *when* the listener was attached relative to when the event fired.

---

## Iteration 2: Used `authState.session?.user` instead of `SupabaseService.currentUser`

### Assumption
> "Maybe `SupabaseService.currentUser` returns stale data. The stream event carries the session — we should use that user object directly."

### Change
Switched from reading the static `SupabaseService.currentUser` getter to using the `user` object from the stream's `AuthState`.

### Result
**Improved reliability in debug mode.** The user was now correctly identified from the stream event. But the core timing issue remained in release mode.

### Why it helped (partially)
The stream event carries the *current* session state at the moment it fires, while `SupabaseService.currentUser` could be stale if read at the wrong time during initialization. This fixed a secondary issue but not the root cause.

---

## Iteration 3: Moved `Consumer<AuthProvider>` inside `_AuthGate`

### Assumption
> "The `Consumer` wrapping `MaterialApp` means the entire app tree rebuilds on auth changes, but `MaterialApp.home` doesn't re-navigate — it only sets the *initial* route."

### Change
Moved the `Consumer<AuthProvider>` from wrapping `MaterialApp` to inside a dedicated `_AuthGate` widget used as the `home:` parameter. This way, auth state changes rebuild *only* the home widget, correctly swapping between `LoginScreen`, `ProfileSetupScreen`, and `HomeScreen`.

### Result
**Fixed the "stuck on HomeScreen" issue in debug mode.** The screen now changes correctly when auth state transitions. But in release mode, the screen swap was still not happening because the auth state itself was wrong.

### Key Insight
Wrapping `MaterialApp` with `Consumer` is an anti-pattern for auth gating. The `home` widget is only used for the initial build — subsequent changes to `home` don't push new routes. The fix was architecturally correct but didn't solve the timing bug.

---

## Iteration 4: Made `_AuthGate` a `StatefulWidget` with `popUntil`

### Assumption
> "Even though `_AuthGate` rebuilds correctly, any routes *pushed on top* of it (e.g., navigating into match details) hide the auth gate. When auth state changes, the user never sees the new screen because the old pushed routes are still on the stack."

### Change
Made `_AuthGate` a `StatefulWidget` that tracks the current auth "phase" (`loading`, `signedOut`, `noProfile`, `ready`). When the phase changes, it calls:

```dart
Navigator.of(context).popUntil((route) => route.isFirst);
```

This clears all pushed routes so the auth gate's new screen is actually visible.

### Result
**Fully correct navigation behavior.** Signing out from a deeply nested screen now properly returns to `LoginScreen`. But release mode *still* had the race condition in `AuthProvider._init()`.

---

## Iteration 5: Added delayed fallback for AOT mode

### Assumption
> "In release mode (AOT compilation), `Supabase.initialize()` fires `initialSession` synchronously during init — *before* our stream listener is attached. The event is lost. We need a fallback that checks after a delay."

### Change
Added a `Future.delayed(Duration(milliseconds: 500))` fallback that re-checks `currentUser` if the stream listener hasn't fired yet.

### Result
**Unreliable.** The delay was arbitrary — too short and it runs before the session is ready, too long and the user sees a prolonged loading spinner. This was a band-aid, not a fix.

### Why it was wrong
Adding arbitrary delays to fix race conditions is a code smell. The real fix needed to eliminate the race entirely, not paper over it.

---

## Iteration 6: The Definitive Fix — Synchronous-First Approach

### The Root Cause (finally understood)

The race condition was:

```
DEBUG MODE (JIT — slower):
  1. Supabase.initialize() completes
  2. AuthProvider() constructor runs
  3. Stream listener attached ← FIRST
  4. initialSession event fires ← SECOND (listener catches it ✓)

RELEASE MODE (AOT — faster):
  1. Supabase.initialize() completes
  2. initialSession event fires ← FIRST (no listener yet!)
  3. AuthProvider() constructor runs
  4. Stream listener attached ← SECOND (event already lost ✗)
```

In AOT-compiled release builds, code executes faster. The `initialSession` event fires during `Supabase.initialize()` itself, *before* the `AuthProvider` constructor even runs. By the time the stream listener is attached, the event has already been emitted and lost.

### The Solution

**Don't rely on the stream for initial state at all.** After `Supabase.initialize()` completes, the persisted session is already loaded and `SupabaseService.currentUser` is available **synchronously** — no stream needed.

```dart
Future<void> _init() async {
  // ── PRIMARY PATH: Check current session immediately ──
  // After Supabase.initialize(), the persisted session is already loaded.
  // currentUser is available synchronously — no race condition possible.
  final currentUser = SupabaseService.currentUser;

  if (currentUser != null) {
    await _loadProfile(currentUser.id);
  } else {
    _isLoading = false;
    notifyListeners();
  }

  // ── SECONDARY: Listen for FUTURE auth changes only ──
  // signedIn     → deep link returns after OAuth
  // signedOut    → user logs out
  // tokenRefreshed → auto-refresh
  // initialSession → SKIP (we already handled it above)
  _authSub = authStream.listen((authState) async {
    if (event == AuthChangeEvent.initialSession) return; // Skip!
    // ... handle signedIn, signedOut, tokenRefreshed
  });
}
```

### Result
**Works perfectly in both debug and release mode.** No race condition possible because the initial state check is synchronous and happens before any stream subscription.

---

## Bonus Bug: Release APK Can't Access the Network

### Symptom
After fixing the auth race condition, the release APK crashed with:

```
ClientException with SocketException: Failed host lookup:
'phxazbsbnglpjnauhxah.supabase.co'
(OS Error: No address associated with hostname, errno = 7)
```

### Assumption
> "The `INTERNET` permission is missing from the release manifest."

### Root Cause
Flutter's **debug builds** automatically inject `<uses-permission android:name="android.permission.INTERNET" />` via the debug `AndroidManifest.xml`. Release builds only use permissions declared in `android/app/src/main/AndroidManifest.xml` — and we never added it there.

### Fix
Added one line to the main manifest:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application ...>
```

---

## Bonus Bug: Logger Silent in Release Mode

### Symptom
After setting `level: Level.trace` to see all logs in release mode, no output appeared in `flutter run --release`.

### Root Cause
Flutter **strips `print()` calls** in release mode as an optimization. The `logger` package's default `ConsoleOutput` uses `print()` internally, so all output was silently discarded.

### Fix
Created a custom `LogOutput` that writes directly to `stdout`:

```dart
class _StdoutOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      stdout.writeln(line);
    }
  }
}
```

`stdout.writeln()` is a `dart:io` call that bypasses Flutter's print stripping.

---

## Summary of All Issues

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 1 | ProfileSetupScreen skipped after sign-in | `initialSession` stream event lost in AOT mode | Check `currentUser` synchronously first; skip `initialSession` in stream |
| 2 | Auth gate didn't swap screens | `Consumer` wrapping `MaterialApp` — `home` only sets initial route | Move `Consumer` inside `_AuthGate` widget |
| 3 | Pushed routes hid auth screen changes | Navigator stack not cleared on auth transitions | `popUntil(isFirst)` on phase change |
| 4 | Release APK: DNS lookup failed | Missing `INTERNET` permission in main manifest | Added `<uses-permission>` to `AndroidManifest.xml` |
| 5 | Release APK: no log output | Flutter strips `print()` in release | Custom `LogOutput` using `stdout.writeln()` |

## Key Takeaways

1. **Debug ≠ Release.** JIT (debug) and AOT (release) have fundamentally different execution timing. Always test in release mode.
2. **Don't rely on stream events for initial state.** If state is available synchronously, read it synchronously. Use streams only for *future* changes.
3. **Arbitrary delays are not fixes.** If you're adding `Future.delayed` to fix a race condition, you're masking the bug, not fixing it.
4. **Android debug builds are permissive.** The INTERNET permission, strict mode, and other debug-only affordances can hide issues that only surface in release.
5. **Flutter strips `print()` in release.** If you need logging in release builds, use `dart:io`'s `stdout.writeln()` directly.
6. **Structured logging pays for itself.** Adding the `AppLogger` utility with tagged, leveled output made it possible to trace the exact race condition timing and confirm the fix.

---

*Branch: `Bug/Profile_notSetupProperly-6`*
*Files modified: `auth_provider.dart`, `app.dart`, `app_logger.dart`, `AndroidManifest.xml`*
