import 'dart:async';
import 'package:cricstatz/models/profile.dart';
import 'package:cricstatz/services/profile_service.dart';
import 'package:cricstatz/services/supabase_service.dart';
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

  void _init() {
    WidgetsBinding.instance.addObserver(this);

    final authStream = SupabaseService.onAuthStateChange;
    if (authStream != null) {
      _authSub = authStream.listen((authState) async {
        final event = authState.event;
        // Use the user from the event itself, NOT SupabaseService.currentUser.
        // After an OAuth redirect the client's internal state may still
        // reference the previous user for a brief moment.
        final user = authState.session?.user;

        debugPrint('[AuthProvider] event=$event  user=${user?.id}');

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.initialSession) {
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
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-check auth when the app returns from the background (safety net).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final user = SupabaseService.currentUser;
      if (user != null && _profile == null && !_isLoading) {
        debugPrint('[AuthProvider] resumed – rechecking profile for ${user.id}');
        _loadProfile(user.id);
      }
    }
  }

  Future<void> _loadProfile(String userId) async {
    debugPrint('[AuthProvider] _loadProfile START for $userId');
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await ProfileService.getProfile(userId)
          .timeout(const Duration(seconds: 5));
      debugPrint('[AuthProvider] _loadProfile result: ${_profile?.toJson()}');
    } on TimeoutException {
      debugPrint('[AuthProvider] _loadProfile TIMED OUT – treating as no profile');
      _profile = null;
    } catch (e) {
      debugPrint('[AuthProvider] _loadProfile error: $e');
      _profile = null;
    }

    _isLoading = false;
    debugPrint('[AuthProvider] _loadProfile DONE – profile=${_profile != null}');
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await SupabaseService.signInWithGoogle();
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
