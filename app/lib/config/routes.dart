import 'package:cricstatz/screens/home/home_screen.dart';
import 'package:cricstatz/screens/match/creatematch.dart';
import 'package:cricstatz/screens/match/info.dart';
import 'package:cricstatz/screens/match/live.dart';
import 'package:cricstatz/screens/match/players.dart';
import 'package:cricstatz/screens/match/scoreboard.dart';
import 'package:cricstatz/screens/profile/profile.dart';
import 'package:cricstatz/screens/match/toss_screen.dart';
import 'package:cricstatz/screens/match/upcoming_fixtures_screen.dart';
import 'package:cricstatz/screens/match/scoreliveupdate.dart';
import 'package:cricstatz/screens/stats/results_screen.dart';
import 'package:cricstatz/screens/stats/player_stats_screen.dart';
import 'package:cricstatz/models/match.dart' as models;
import 'package:flutter/material.dart';

class AppRoutes {
  // Use a non-root path so we can still use `home:` in MaterialApp
  // without conflicting with the default "/" route.
  static const String home = '/home';
  static const String toss = '/matches/toss';
  static const String createMatch = '/matches/create';
  static const String upcoming = '/matches/upcoming';
  static const String info = '/matches/info';
  static const String live = '/matches/live';
  static const String scoreboard = '/matches/scoreboard';
  static const String players = '/matches/players';
  static const String liveUpdate = '/matches/live-update';
  static const String results = '/results';
  static const String playerStats = '/stats/player';
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    String? matchId;
    models.Match? match;

    if (settings.arguments is String) {
      matchId = settings.arguments as String;
    } else if (settings.arguments is models.Match) {
      match = settings.arguments as models.Match;
      matchId = match.id;
    }

    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case toss:
        return MaterialPageRoute(
          builder: (_) => const TossScreen(),
          settings: settings, // Pass the Match object through
        );
      case createMatch:
        return MaterialPageRoute(builder: (_) => const CreateMatchScreen());
      case upcoming:
        return MaterialPageRoute(builder: (_) => const UpcomingFixturesScreen());
      case info:
        return MaterialPageRoute(builder: (_) => MatchInfoScreen(matchId: matchId));
      case live:
        return MaterialPageRoute(builder: (_) => LiveMatchScreen(matchId: matchId));
      case scoreboard:
        return MaterialPageRoute(builder: (_) => MatchScoreboardScreen(matchId: matchId));
      case players:
        return MaterialPageRoute(builder: (_) => MatchPlayersScreen(matchId: matchId));
      case liveUpdate:
        return MaterialPageRoute(
          builder: (_) => const ScoreLiveUpdateScreen(),
          settings: settings, // Pass the map through
        );
      case results:
        return buildResultsRoute();
      case playerStats:
        return buildPlayerStatsRoute();
      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }

  static Map<String, WidgetBuilder> get routeTable => {};

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

  /// Smooth transition to PlayerStatsScreen (fade + slight slide).
  static Route<void> buildPlayerStatsRoute() {
    return PageRouteBuilder<void>(
      settings: const RouteSettings(name: playerStats),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PlayerStatsScreen(),
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
