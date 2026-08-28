import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/app_bottom_nav_bar.dart';
import 'package:cricstatz/widgets/app_header.dart';
import 'package:flutter/material.dart';

class ScoringChatsScreen extends StatefulWidget {
  const ScoringChatsScreen({super.key});

  @override
  State<ScoringChatsScreen> createState() => _ScoringChatsScreenState();
}

class _ScoringChatsScreenState extends State<ScoringChatsScreen> {
  late Future<List<Match>> _liveMatchesFuture;

  @override
  void initState() {
    super.initState();
    _refreshChats();
  }

  void _refreshChats() {
    setState(() {
      _liveMatchesFuture = MatchService.getLiveMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                trailing: IconButton(
                  icon: Icon(Icons.refresh, color: AppPalette.textPrimary),
                  onPressed: _refreshChats,
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Match>>(
                  future: _liveMatchesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading active chats: ${snapshot.error}',
                          style: TextStyle(color: AppPalette.live),
                        ),
                      );
                    }

                    final matches = snapshot.data ?? [];
                    if (matches.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppPalette.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                'No active scoring chats',
                                style: TextStyle(
                                  color: AppPalette.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scoring chats open automatically during active live matches. Start scoring a match to see it here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppPalette.textMuted),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.createMatch).then((_) => _refreshChats()),
                                icon: const Icon(Icons.add),
                                label: const Text('Start a Match'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.accent,
                                  foregroundColor: AppPalette.bgSecondary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'LIVE CHAT CHANNELS',
                            style: TextStyle(
                              color: AppPalette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final match = matches[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: AppPalette.cardPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: AppPalette.cardStroke),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    backgroundColor: AppPalette.live.withValues(alpha: 0.1),
                                    child: Icon(Icons.forum_outlined, color: AppPalette.live),
                                  ),
                                  title: Text(
                                    '${match.teamAId} vs ${match.teamBId}',
                                    style: TextStyle(
                                      color: AppPalette.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppPalette.live,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Live Scoring Chat',
                                        style: TextStyle(color: AppPalette.textMuted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(Icons.chevron_right, color: AppPalette.textMuted),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Joining chat for ${match.teamAId} vs ${match.teamBId}...'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
}
