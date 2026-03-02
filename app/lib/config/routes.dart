import 'package:cricstatz/screens/home/home_screen.dart';
import 'package:cricstatz/screens/match/info.dart';
import 'package:cricstatz/screens/match/live.dart';
import 'package:cricstatz/screens/match/players.dart';
import 'package:cricstatz/screens/match/scoreboard.dart';
import 'package:cricstatz/screens/match/toss_screen.dart';
import 'package:cricstatz/screens/match/upcoming_fixtures_screen.dart';
import 'package:cricstatz/screens/stats/results_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/';
  static const String toss = '/matches/toss';
  static const String upcoming = '/matches/upcoming';
  static const String info = '/matches/info';
  static const String live = '/matches/live';
  static const String scoreboard = '/matches/scoreboard';
  static const String players = '/matches/players';
  static const String results = '/results';

  static Map<String, WidgetBuilder> get routeTable => {
        home: (_) => const HomeScreen(),
        toss: (_) => const TossScreen(),
        upcoming: (_) => const UpcomingFixturesScreen(),
        info: (_) => const MatchInfoScreen(),
        live: (_) => const MatchLiveScreen(),
        scoreboard: (_) => const MatchScoreboardScreen(),
        players: (_) => const MatchPlayersScreen(),
        results: (_) => const ResultsScreen(),
      };

  /// Smooth transition to ResultsScreen (fade + slight slide).
  static Route<void> buildResultsRoute() {
    return PageRouteBuilder<void>(
      settings: const RouteSettings(name: results),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const ResultsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        final curved = CurvedAnimation(parent: animation, curve: curve);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  /// Smooth transition to UpcomingFixturesScreen (fade + slight slide).
  static Route<void> buildUpcomingRoute() {
    return PageRouteBuilder<void>(
      settings: const RouteSettings(name: upcoming),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const UpcomingFixturesScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        final curved = CurvedAnimation(parent: animation, curve: curve);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  const AppRoutes._();
}
