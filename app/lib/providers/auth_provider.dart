import 'dart:async';
import 'package:cricstatz/models/profile.dart';
import 'package:cricstatz/services/profile_service.dart';
import 'package:cricstatz/services/supabase_service.dart';
import 'package:cricstatz/utils/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  Profile? _profile;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSub;

  AuthProvider() {
    _init();
  }

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSignedIn => SupabaseService.currentUser != null;
  bool get isProfileComplete => _profile != null;

  bool _profileLoadInProgress = false;

  Future<void> _init() async {
    final stopwatch = Stopwatch()..start();
    WidgetsBinding.instance.addObserver(this);

    // ── PRIMARY PATH: Check current session immediately ──
    // After Supabase.initialize(), the persisted session is already loaded.
    // currentUser is available synchronously — no race condition possible.
    final currentUser = SupabaseService.currentUser;
    AppLogger.info(
      '_init START – currentUser=${currentUser?.id} (${stopwatch.elapsedMilliseconds}ms)',
      tag: 'Auth',
    );

    if (currentUser != null) {
      await _loadProfile(currentUser.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    AppLogger.info(
      '_init primary check done (${stopwatch.elapsedMilliseconds}ms)',
      tag: 'Auth',
    );

    // ── SECONDARY: Listen for FUTURE auth changes only ──
    // signedIn     → deep link returns after OAuth
    // signedOut    → user logs out
    // tokenRefreshed → auto-refresh
    // initialSession → SKIP (we already handled it above)
    final authStream = SupabaseService.onAuthStateChange;
    if (authStream != null) {
      _authSub = authStream.listen((authState) async {
        final event = authState.event;
        final user = authState.session?.user;

        AppLogger.info(
          'stream event=$event  user=${user?.id} (${stopwatch.elapsedMilliseconds}ms)',
          tag: 'Auth',
        );

        // We already handled the initial session synchronously above.
        if (event == AuthChangeEvent.initialSession) return;

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          if (user != null) {
            await _loadProfile(user.id);
          } else {
            _profile = null;
            _isLoading = false;
            notifyListeners();
          }
        } else if (event == AuthChangeEvent.signedOut) {
          _profile = null;
          _isLoading = false;
          notifyListeners();
        }
      });
    }

    AppLogger.info('_init COMPLETE (${stopwatch.elapsedMilliseconds}ms)', tag: 'Auth');
  }

  /// Re-check auth when the app returns from the background (safety net).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final user = SupabaseService.currentUser;
      if (user != null && _profile == null && !_isLoading) {
        AppLogger.debug('resumed – rechecking profile for ${user.id}', tag: 'Auth');
        _loadProfile(user.id);
      }
    }
  }

  Future<void> _loadProfile(String userId) async {
    if (_profileLoadInProgress) {
      AppLogger.debug('_loadProfile SKIPPED (already in progress)', tag: 'Auth');
      return;
    }
    _profileLoadInProgress = true;

    AppLogger.debug('_loadProfile START for $userId', tag: 'Auth');
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await ProfileService.getProfile(userId)
          .timeout(const Duration(seconds: 5));
      AppLogger.info(
        '_loadProfile result: ${_profile != null ? "found" : "null"}',
        tag: 'Auth',
      );
    } on TimeoutException {
      AppLogger.warning('_loadProfile TIMED OUT – treating as no profile', tag: 'Auth');
      _profile = null;
    } catch (e) {
      AppLogger.error('_loadProfile failed', tag: 'Auth', error: e);
      _profile = null;
    }

    _profileLoadInProgress = false;
    _isLoading = false;
    AppLogger.info('_loadProfile DONE – profile=${_profile != null}', tag: 'Auth');
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await SupabaseService.signInWithGoogle();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await SupabaseService.signInWithEmail(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await SupabaseService.signUpWithEmail(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<void> createProfile({
    required String username,
    required String displayName,
    String? avatarUrl,
    required String role,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    _profile = await ProfileService.createProfile(
      userId: user.id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role,
    );
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      await _loadProfile(user.id);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }
}
