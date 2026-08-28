import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/app_bottom_nav_bar.dart';
import 'package:cricstatz/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  late Future<List<Match>> _myMatchesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMatches();
  }

  void _refreshMatches() {
    setState(() {
      _myMatchesFuture = MatchService.getMyMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createMatch).then((_) => _refreshMatches()),
        backgroundColor: AppPalette.accent,
        foregroundColor: AppPalette.bgSecondary,
        child: const Icon(Icons.add),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                trailing: IconButton(
                  icon: Icon(Icons.refresh, color: AppPalette.textPrimary),
                  onPressed: _refreshMatches,
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Match>>(
                  future: _myMatchesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading matches: ${snapshot.error}',
                          style: TextStyle(color: AppPalette.live),
                        ),
                      );
                    }

                    final matches = snapshot.data ?? [];
                    if (matches.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_cricket_outlined, size: 64, color: AppPalette.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'No matches created yet',
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "+" to configure and start your first match.',
                              style: TextStyle(color: AppPalette.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        final formattedDate = match.matchDate != null
                            ? DateFormat('EEE, d MMM • h:mm a').format(match.matchDate!)
                            : 'Date not set';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppPalette.cardPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppPalette.cardStroke),
                          ),
                          child: InkWell(
                            onTap: () => _handleMatchTap(context, match),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusBgColor(match.status),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          match.status.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        match.matchFormat?.toUpperCase() ?? 'OTHER',
                                        style: TextStyle(
                                          color: AppPalette.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${match.teamAId} vs ${match.teamBId}',
                                    style: TextStyle(
                                      color: AppPalette.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 14, color: AppPalette.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(color: AppPalette.textMuted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  if (match.venue != null && match.venue!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: AppPalette.textMuted),
                                        const SizedBox(width: 6),
                                        Text(
                                          match.venue!,
                                          style: TextStyle(color: AppPalette.textMuted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return AppPalette.live;
      case 'completed':
        return AppPalette.success;
      default:
        return AppPalette.progress;
    }
  }

  void _handleMatchTap(BuildContext context, Match match) {
    if (match.status.toLowerCase() == 'live') {
      // Prompt user to view or resume scoring
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppPalette.bgPrimary,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.play_circle_outline, color: AppPalette.accent),
                title: Text('Resume Scoring', style: TextStyle(color: AppPalette.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.liveUpdate, arguments: {
                    'matchId': match.id,
                    'teamAId': match.teamAId,
                    'teamBId': match.teamBId,
                    'oversLimit': match.oversLimit,
                    'matchFormat': match.matchFormat,
                  }).then((_) => _refreshMatches());
                },
              ),
              ListTile(
                leading: Icon(Icons.remove_red_eye_outlined, color: AppPalette.textPrimary),
                title: Text('View Match Info', style: TextStyle(color: AppPalette.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.live, arguments: match.id);
                },
              ),
            ],
          ),
        ),
      );
    } else if (match.status.toLowerCase() == 'upcoming') {
      Navigator.pushNamed(context, AppRoutes.toss, arguments: match).then((_) => _refreshMatches());
    } else {
      Navigator.pushNamed(context, AppRoutes.scoreboard, arguments: match.id);
    }
  }
}
