import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/providers/auth_provider.dart';
import 'package:cricstatz/providers/match_provider.dart';
import 'package:cricstatz/providers/scoring_provider.dart';
import 'package:cricstatz/providers/team_provider.dart';
import 'package:cricstatz/screens/auth/login_screen.dart';
import 'package:cricstatz/screens/auth/profile_setup_screen.dart';
import 'package:cricstatz/screens/home/home_screen.dart';
import 'package:cricstatz/screens/onboarding/onboarding_screen.dart';
import 'package:cricstatz/services/local_storage_service.dart';
import 'package:cricstatz/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:cricstatz/providers/theme_provider.dart';

class CricStatzApp extends StatelessWidget {
  const CricStatzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => ScoringProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Lock orientation to portrait for a consistent experience
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          return MaterialApp(
            title: 'CricStatz',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentThemeData,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: const _OnboardingGate(),
          );
        },
      ),
    );
  }
}

/// Checks if this is the first launch. If so, shows onboarding.
/// After onboarding is done, delegates to _AuthGate.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final done = await LocalStorageService.getBool('onboarding_done') ?? false;
    if (mounted) setState(() => _onboardingDone = done);
  }

  void _markDone() {
    if (mounted) setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const _SplashScreen();
    }
    if (_onboardingDone == false) {
      return OnboardingScreen(onCompleted: _markDone);
    }
    return const _AuthGate();
  }
}

/// Branded splash screen shown while checking onboarding / loading auth.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111721),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C2FF), Color(0xFF0066FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.sports_cricket_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CricStatz',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Live Cricket. Real Stats.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF00C2FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String _lastState = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final currentState = auth.isLoading
            ? 'loading'
            : !auth.isSignedIn
                ? 'signedOut'
                : !auth.isProfileComplete
                    ? 'noProfile'
                    : 'ready';

        AppLogger.debug('state=$currentState (was=$_lastState)', tag: 'AuthGate');

        if (currentState != _lastState && _lastState.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
        _lastState = currentState;

        if (auth.isLoading) {
          return const _SplashScreen();
        }
        if (!auth.isSignedIn) {
          return const LoginScreen();
        }
        if (!auth.isProfileComplete) {
          return const ProfileSetupScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
