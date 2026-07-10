import 'dart:ui';
import 'dart:async';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/config/assets.dart';
import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/widgets/app_bottom_nav_bar.dart';
import 'package:cricstatz/widgets/app_header.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/models/match_stats.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  List<Match> _liveMatches = const [];
  final Map<String, ScoreSummary?> _liveSummaries = {};
  bool _isLoadingLive = true;
  StreamSubscription<List<Match>>? _liveMatchesSub;

  @override
  void initState() {
    super.initState();
    _fetchLiveMatches();
    _subscribeToLiveSessions();
  }

  Future<ScoreSummary?> _fetchSummaryForMatch(String matchId) async {
    try {
      final stats = await MatchService.getLiveScore(matchId);
      return stats['summary'] as ScoreSummary?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchLiveMatches() async {
    try {
      final matches = await MatchService.getLiveMatches();
      final entries = await Future.wait(
        matches.map((match) async {
          final summary = await _fetchSummaryForMatch(match.id);
          return MapEntry(match.id, summary);
        }),
      );

      if (!mounted) return;
      setState(() {
        _liveMatches = matches;
        _liveSummaries
          ..clear()
          ..addEntries(entries);
        _isLoadingLive = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingLive = false);
    }
  }

  void _subscribeToLiveSessions() {
    _liveMatchesSub?.cancel();
    _liveMatchesSub = MatchService.streamLiveMatches().listen((matches) async {
      if (!mounted) return;

      final entries = await Future.wait(
        matches.map((match) async {
          final summary = await _fetchSummaryForMatch(match.id);
          return MapEntry(match.id, summary);
        }),
      );
      if (!mounted) return;
      setState(() {
        _liveMatches = matches;
        _liveSummaries
          ..clear()
          ..addEntries(entries);
        _isLoadingLive = false;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _isLoadingLive = false);
    });
  }

  @override
  void dispose() {
    _liveMatchesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppPalette.accent,
        foregroundColor: AppPalette.bgSecondary,
        child: Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: false,
                automaticallyImplyLeading: false,
                toolbarHeight:
                    111, // AppHeader (55) + QuickTabs (51) + buffer to avoid overflow
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppPalette.bgPrimary,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppHeader(
                            trailing: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppPalette.bgSecondary
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.notifications_none,
                                      color: AppPalette.textPrimary),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppPalette.live,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppPalette.bgPrimary,
                                          width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _QuickTabs(
                            selectedIndex: _selectedTab,
                            onTap: (int index) {
                              setState(() => _selectedTab = index);
                              if (index == 1) {
                                Navigator.push(
                                    context, AppRoutes.buildUpcomingRoute());
                              } else if (index == 2) {
                                Navigator.push(
                                    context, AppRoutes.buildResultsRoute());
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_isLoadingLive)
                      const HomeLiveMatchLoader()
                    else if (_liveMatches.isNotEmpty)
                      _LiveMatchesSection(
                        matches: _liveMatches,
                        summaries: _liveSummaries,
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 18),
                    const _UpcomingMatchesSection(),
                    const SizedBox(height: 18),
                    const _RecentResultsSection(),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showCreateSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppPalette.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Create',
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppPalette.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CreateOptionTile(
                icon: Icons.sports_cricket,
                label: 'Create a Match',
                description: 'Start a quick local or club match',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.createMatch);
                },
              ),
              _CreateOptionTile(
                icon: Icons.emoji_events_outlined,
                label: 'Start Tournament',
                description: 'Organize leagues with multiple teams',
              ),
              _CreateOptionTile(
                icon: Icons.group_add_outlined,
                label: 'Create New Team',
                description: 'Manage players and team statistics',
              ),
              _CreateOptionTile(
                icon: Icons.post_add_outlined,
                label: 'Share a Post',
                description: 'Update your feed with photos or news',
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CreateOptionTile extends StatelessWidget {
  const _CreateOptionTile({
    required this.icon,
    required this.label,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label coming soon')),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPalette.cardOverlay,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppPalette.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppPalette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppPalette.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTabs extends StatelessWidget {
  const _QuickTabs({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _TabItem(
              label: 'Live',
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _TabItem(
              label: 'Upcoming',
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            _TabItem(
              label: 'Results',
              isSelected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
            _TabItem(
              label: 'My Matches',
              isSelected: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding:
            EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppPalette.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppPalette.accent : AppPalette.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
      ),
    );
  }
}

class _LiveMatchesSection extends StatelessWidget {
  const _LiveMatchesSection({
    required this.matches,
    required this.summaries,
  });

  final List<Match> matches;
  final Map<String, ScoreSummary?> summaries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Live Matches',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Spacer(),
            Icon(Icons.circle, color: AppPalette.live, size: 8),
            SizedBox(width: 6),
            Text(
              'LIVE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppPalette.live,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 295,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final match = matches[index];
              return SizedBox(
                width: 330,
                child: _LiveMatchCard(
                  match: match,
                  summary: summaries[match.id],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  const _LiveMatchCard({required this.match, this.summary});

  final Match match;
  final ScoreSummary? summary;

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        border: Border.all(color: AppPalette.cardStroke, width: 1.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPalette.cardStroke.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppPalette.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  match.matchFormat?.toUpperCase() ?? 'MATCH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Final • Narendra Modi Stadium',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppPalette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TeamBadge(flag: match.teamAId, assetPath: AppAssets.flagInd),
              _ScoreCenter(summary: summary),
              _TeamBadge(
                flag: match.teamBId,
                assetPath: AppAssets.flagAus,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (summary != null) ...[
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppPalette.textMuted,
                            ),
                        children: [
                          const TextSpan(text: 'India needs '),
                          TextSpan(
                            text: '42 runs ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppPalette.accent,
                            ),
                          ),
                          const TextSpan(text: 'in '),
                          TextSpan(
                            text: '60 balls',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RRR: 4.20',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppPalette.textMuted,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.7,
                    minHeight: 6,
                    backgroundColor: AppPalette.cardStroke.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppPalette.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.live,
                  arguments: match.id),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'View Full Scorecard',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.flag, required this.assetPath});

  final String flag;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppPalette.cardPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.cardStroke, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppPalette.cardStroke.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              assetPath,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error,
                  StackTrace? stackTrace) {
                return Center(
                  child: Text(
                    flag
                        .substring(0, flag.length > 2 ? 2 : flag.length)
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          flag,
          style: TextStyle(
            color: AppPalette.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _ScoreCenter extends StatelessWidget {
  final ScoreSummary? summary;
  const _ScoreCenter({this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (summary != null) ...[
          Text(
            '${summary!.runs}/${summary!.wickets}',
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '(${summary!.overs})',
            style: TextStyle(
              color: AppPalette.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'vs',
            style: TextStyle(
              color: AppPalette.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else ...[
          Text(
            '342/5',
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '(40.0)',
            style: TextStyle(
              color: AppPalette.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'vs',
            style: TextStyle(
              color: AppPalette.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _UpcomingMatchesSection extends StatelessWidget {
  const _UpcomingMatchesSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Match>>(
      future: MatchService.getUpcomingMatches(),
      builder: (context, snapshot) {
        final matches = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 130,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Upcoming Matches',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.push(context, AppRoutes.buildUpcomingRoute()),
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: matches.length > 3 ? 3 : matches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final dateStr = match.matchDate != null
                      ? _formatMatchDate(match.matchDate!)
                      : 'TBD';
                  final subtitle =
                      '${match.matchFormat ?? 'Match'}${match.venue != null ? ' - ${match.venue}' : ''}';
                  return _UpcomingCard(
                    time: dateStr,
                    teamA: match.teamAId,
                    teamB: match.teamBId,
                    subtitle: subtitle,
                    onTap: () =>
                        Navigator.push(context, AppRoutes.buildUpcomingRoute()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final matchDay = DateTime(date.year, date.month, date.day);

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (matchDay == DateTime(now.year, now.month, now.day)) {
      return 'TODAY, $hour:$minute';
    } else if (matchDay == tomorrow) {
      return 'TOMORROW, $hour:$minute';
    } else {
      final months = [
        '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      return '${date.day} ${months[date.month]}, $hour:$minute';
    }
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.time,
    required this.teamA,
    required this.teamB,
    required this.subtitle,
    this.onTap,
  });

  final String time;
  final String teamA;
  final String teamB;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.cardPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardStroke, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppPalette.cardStroke.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppPalette.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppPalette.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TeamInitialCircle(name: teamA),
                    const SizedBox(width: 8),
                    Text(
                      teamA,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                Text('vs',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppPalette.textMuted)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamB,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    _TeamInitialCircle(name: teamB),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: AppPalette.textSubtle,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamInitialCircle extends StatelessWidget {
  const _TeamInitialCircle({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppPalette.progress,
        border: Border.all(color: AppPalette.cardStroke),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}



class _RecentResultsSection extends StatelessWidget {
  const _RecentResultsSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_RecentResult>>(
      future: _loadRecentResults(),
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (results.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.push(context, AppRoutes.buildResultsRoute()),
                  child: const Text('View All'),
                ),
              ],
            ),
            ...results.take(3).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ResultCard(
                lineOne: r.lineOne,
                lineTwo: r.lineTwo,
                when: r.when,
                outcome: r.outcome,
              ),
            )),
          ],
        );
      },
    );
  }

  static Future<List<_RecentResult>> _loadRecentResults() async {
    final matches = await MatchService.getCompletedMatches();
    final recent = matches.take(3).toList();
    final results = <_RecentResult>[];
    for (final match in recent) {
      try {
        final liveScore = await MatchService.getLiveScore(match.id);
        final summary = liveScore['summary'] as ScoreSummary?;
        if (summary == null) continue;

        final firstInnings = summary.firstInnings;
        final firstTeam = firstInnings?['batting_team'] as String? ?? match.teamAId;
        final firstRuns = firstInnings?['runs']?.toString() ?? '?';
        final firstWickets = firstInnings?['wickets']?.toString() ?? '?';
        final firstOvers = firstInnings?['overs']?.toString() ?? '?';

        final secondTeam = summary.battingTeam ?? match.teamBId;
        final secondRuns = summary.runs;
        final secondWickets = summary.wickets;
        final secondOvers = summary.overs;

        final target = int.tryParse(summary.target ?? '');
        final runs2 = int.tryParse(secondRuns) ?? 0;
        String outcome;
        if (target != null && target > 0 && runs2 >= target) {
          final squadSize = summary.squadSize != null ? summary.squadSize! - 1 : 10;
          final remaining = squadSize - (int.tryParse(secondWickets) ?? 0);
          outcome = '$secondTeam won by $remaining wkts';
        } else if (target != null && target > 0) {
          final margin = target - runs2 - 1;
          outcome = '$firstTeam won by $margin runs';
        } else {
          outcome = 'Match completed';
        }

        final whenStr = match.matchDate != null
            ? _formatWhen(match.matchDate!)
            : '';

        results.add(_RecentResult(
          lineOne: '$firstTeam $firstRuns/$firstWickets ($firstOvers)',
          lineTwo: '$secondTeam $secondRuns/$secondWickets ($secondOvers)',
          when: whenStr,
          outcome: outcome,
        ));
      } catch (_) {
        // Skip matches without live score data
      }
    }
    return results;
  }

  static String _formatWhen(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]}';
  }
}

class _RecentResult {
  final String lineOne;
  final String lineTwo;
  final String when;
  final String outcome;
  const _RecentResult({
    required this.lineOne,
    required this.lineTwo,
    required this.when,
    required this.outcome,
  });
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(
      {required this.lineOne,
      required this.lineTwo,
      required this.when,
      required this.outcome});

  final String lineOne;
  final String lineTwo;
  final String when;
  final String outcome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.cardOverlay.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.cardStroke),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(lineOne,
                  style: TextStyle(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w700)),
              Spacer(),
              Text(when,
                  style: TextStyle(
                      color: AppPalette.textSubtle, fontSize: 10)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(lineTwo,
                  style: TextStyle(
                      color: AppPalette.success, fontWeight: FontWeight.w700)),
              Spacer(),
              Text(outcome,
                  style: TextStyle(
                      color: AppPalette.textSubtle, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
