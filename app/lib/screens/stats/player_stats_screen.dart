import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({super.key});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadPlayerStats();
  }

  Future<Map<String, dynamic>> _loadPlayerStats() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final sourceRows = await Supabase.instance.client
          .from('player_stats')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      final hasSourceStats = (sourceRows as List).isNotEmpty;
      if (!hasSourceStats) {
        // Self-heal stale cache rows after match deletions.
        await Supabase.instance.client
            .from('player_career_stats')
            .delete()
            .eq('user_id', userId);
        return _emptyStats();
      }

      final career = await Supabase.instance.client
          .from('player_career_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (career != null) {
        return {
          'batting': {
            'runs': career['runs_scored'] ?? 0,
            'balls': career['balls_faced'] ?? 0,
            'avg': (career['batting_avg'] ?? 0).toString(),
            'sr': (career['strike_rate'] ?? 0).toString(),
            'fours': career['fours'] ?? 0,
            'sixes': career['sixes'] ?? 0,
          },
          'bowling': {
            'runs': career['runs_conceded'] ?? 0,
            'balls': career['balls_bowled'] ?? 0,
            'economy': (career['economy'] ?? 0).toString(),
            'wickets': career['wickets'] ?? 0,
          }
        };
      }

      // Fallback for users whose career cache has not been built yet.
      final stats = await Supabase.instance.client
          .from('player_stats')
          .select()
          .eq('user_id', userId);
      return _aggregateFromMatchRows(stats as List<dynamic>);
    } catch (e) {
      debugPrint('Error loading player stats: $e');
      return _emptyStats();
    }
  }

  Map<String, dynamic> _aggregateFromMatchRows(List<dynamic> stats) {
    if (stats.isEmpty) return _emptyStats();

    int totalRunsScored = 0;
    int totalBallsFaced = 0;
    int totalFours = 0;
    int totalSixes = 0;
    int totalRunsConceded = 0;
    int totalBallsBowled = 0;
    int totalWickets = 0;

    for (final raw in stats) {
      final stat = raw as Map<String, dynamic>;
      totalRunsScored += (stat['runs_scored'] ?? 0) as int;
      totalBallsFaced += (stat['balls_faced'] ?? 0) as int;
      totalFours += (stat['fours'] ?? 0) as int;
      totalSixes += (stat['sixes'] ?? 0) as int;
      totalRunsConceded += (stat['runs_conceded'] ?? 0) as int;
      totalBallsBowled += (stat['balls_bowled'] ?? 0) as int;
      totalWickets += (stat['wickets'] ?? 0) as int;
    }

    final battingAvg = totalBallsFaced > 0
        ? (totalRunsScored / (totalBallsFaced / 6.0)).toStringAsFixed(2)
        : '0.0';
    final strikeRate = totalBallsFaced > 0
        ? ((totalRunsScored / totalBallsFaced) * 100).toStringAsFixed(2)
        : '0.0';
    final economy = totalBallsBowled > 0
        ? (totalRunsConceded / (totalBallsBowled / 6.0)).toStringAsFixed(2)
        : '0.0';

    return {
      'batting': {
        'runs': totalRunsScored,
        'balls': totalBallsFaced,
        'avg': battingAvg,
        'sr': strikeRate,
        'fours': totalFours,
        'sixes': totalSixes,
      },
      'bowling': {
        'runs': totalRunsConceded,
        'balls': totalBallsBowled,
        'economy': economy,
        'wickets': totalWickets,
      }
    };
  }

  Map<String, dynamic> _emptyStats() {
    return {
      'batting': {
        'runs': 0,
        'balls': 0,
        'avg': '0.0',
        'sr': '0.0',
        'fours': 0,
        'sixes': 0,
      },
      'bowling': {
        'runs': 0,
        'balls': 0,
        'economy': '0.0',
        'wickets': 0,
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBottomNavBar(currentIndex: 1),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: AppPalette.live),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading stats',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppPalette.textMuted),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          'No stats available',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppPalette.textMuted),
                        ),
                      );
                    }

                    final stats = snapshot.data!;
                    final batting = stats['batting'] as Map<String, dynamic>;
                    final bowling = stats['bowling'] as Map<String, dynamic>;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Batting Stats
                          _buildStatSection(
                            context,
                            title: 'BATTING',
                            icon: Icons.sports_cricket_rounded,
                            stats: [
                              _StatItem(
                                label: 'Runs',
                                value: batting['runs'].toString(),
                              ),
                              _StatItem(
                                label: 'Balls',
                                value: batting['balls'].toString(),
                              ),
                              _StatItem(
                                label: 'Average',
                                value: batting['avg'].toString(),
                              ),
                              _StatItem(
                                label: 'Strike Rate',
                                value: batting['sr'].toString(),
                              ),
                              _StatItem(
                                label: 'Fours',
                                value: batting['fours'].toString(),
                              ),
                              _StatItem(
                                label: 'Sixes',
                                value: batting['sixes'].toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Bowling Stats
                          _buildStatSection(
                            context,
                            title: 'BOWLING',
                            icon: Icons.sports_baseball_rounded,
                            stats: [
                              _StatItem(
                                label: 'Runs Conceded',
                                value: bowling['runs'].toString(),
                              ),
                              _StatItem(
                                label: 'Balls Bowled',
                                value: bowling['balls'].toString(),
                              ),
                              _StatItem(
                                label: 'Economy',
                                value: bowling['economy'].toString(),
                              ),
                              _StatItem(
                                label: 'Wickets',
                                value: bowling['wickets'].toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppPalette.bgPrimary,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppPalette.live.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, color: AppPalette.live),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'My Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_StatItem> stats,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppPalette.live, size: 24),
              SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppPalette.live,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: stats
                .map((stat) => _buildStatCard(context, stat.label, stat.value))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.live,
                ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppPalette.textMuted,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem({required this.label, required this.value});
}
