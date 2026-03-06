import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/config/theme.dart';
import 'package:cricstatz/providers/auth_provider.dart';
import 'package:cricstatz/providers/match_provider.dart';
import 'package:cricstatz/providers/scoring_provider.dart';
import 'package:cricstatz/providers/team_provider.dart';
import 'package:cricstatz/screens/auth/login_screen.dart';
import 'package:cricstatz/screens/auth/profile_setup_screen.dart';
import 'package:cricstatz/screens/home/home_screen.dart';
import 'package:cricstatz/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      ],
      child: MaterialApp(
        title: 'CricStatz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const _AuthGate(),
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
        // Compute a key representing the current auth "phase".
        final currentState = auth.isLoading
            ? 'loading'
            : !auth.isSignedIn
                ? 'signedOut'
                : !auth.isProfileComplete
                    ? 'noProfile'
                    : 'ready';

        AppLogger.debug('state=$currentState (was=$_lastState)', tag: 'AuthGate');

        // When the auth phase changes, pop any pushed routes so the new
        // screen is actually visible instead of hidden underneath.
        if (currentState != _lastState && _lastState.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
        _lastState = currentState;

        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
