import 'dart:ui';

import 'package:cricstatz/config/assets.dart';
import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/app_bottom_nav_bar.dart';
import 'package:cricstatz/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingFixturesScreen extends StatefulWidget {
  const UpcomingFixturesScreen({super.key});

  @override
  State<UpcomingFixturesScreen> createState() => _UpcomingFixturesScreenState();
}

class _UpcomingFixturesScreenState extends State<UpcomingFixturesScreen> {
  late Future<_FixturesData> _fixturesFuture;

  @override
  void initState() {
    super.initState();
    _fixturesFuture = _loadFixtures();
  }

  Future<_FixturesData> _loadFixtures() async {
    final results = await Future.wait([
      MatchService.getLiveMatches(),
      MatchService.getUpcomingMatches(),
    ]);

    return _FixturesData(
      live: results[0],
      upcoming: results[1],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: FutureBuilder<_FixturesData>(
                  future: _fixturesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child:
                            CircularProgressIndicator(color: AppPalette.accent),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load fixtures: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    final data = snapshot.data ??
                        const _FixturesData(
                            live: <Match>[], upcoming: <Match>[]);
                    if (data.live.isEmpty && data.upcoming.isEmpty) {
                      return Center(
                        child: Text(
                          'No fixtures found.',
                          style: TextStyle(color: AppPalette.textMuted),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      children: [
                        if (data.live.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Live Now',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppPalette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.live.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return _LiveFixtureCard(
                                    match: data.live[index]);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fixtures',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppPalette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...data.upcoming.map((match) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _FixtureCard(match: match),
                            )),
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

  Widget _buildHeader(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.bgPrimary,
            border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
          ),
          child: Column(
            children: [
              AppHeader(
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppPalette.bgSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Image.asset(AppAssets.iconCal,
                            width: 20,
                            height: 20,
                            color: AppPalette.textPrimary),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppPalette.bgSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Image.asset(AppAssets.iconFil,
                            width: 20,
                            height: 20,
                            color: AppPalette.textPrimary),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _QuickTabs(),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TabItem(
              label: 'Live',
              isSelected: false,
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (r) => false)),
          _TabItem(label: 'Upcoming', isSelected: true, onTap: () {}),
          _TabItem(
              label: 'Results',
              isSelected: false,
              onTap: () =>
                  Navigator.push(context, AppRoutes.buildResultsRoute())),
          _TabItem(label: "My Matche's", isSelected: false, onTap: () {}),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem(
      {required this.label, required this.isSelected, required this.onTap});

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

class _FixtureCard extends StatelessWidget {
  const _FixtureCard({required this.match});

  final Match match;

  static Color _getFormatColor(String? format) {
    switch (format?.toUpperCase()) {
      case 'T20':
        return AppPalette.accent;
      case 'ODI':
        return AppPalette.cardStroke;
      case 'TEST':
        return AppPalette.live;
      default:
        return AppPalette.cardPrimary;
    }
  }

  static String _getFlagForTeam(String? teamName) {
    if (teamName == null) return AppAssets.flagInd;
    final name = teamName.toUpperCase();
    if (name.contains('INDIA')) return AppAssets.flagInd;
    if (name.contains('AUSTRALIA')) return AppAssets.flagAus;
    if (name.contains('ENGLAND')) return AppAssets.flagEng;
    if (name.contains('SOUTH AFRICA')) return AppAssets.flagRsa;
    if (name.contains('NEW ZEALAND')) return AppAssets.flagNzl;
    if (name.contains('PAKISTAN')) return AppAssets.flagPak;
    return AppAssets.flagInd; // Default
  }

  @override
  Widget build(BuildContext context) {
    final matchTime = match.matchDate != null
        ? DateFormat('EEE, d MMM • HH:mm').format(match.matchDate!)
        : 'Date TBD';
    final formatColor = _getFormatColor(match.matchFormat);
    final teamAFlag = _getFlagForTeam(match.teamAId);
    final teamBFlag = _getFlagForTeam(match.teamBId);
    final isToday = match.matchDate != null &&
        DateTime.now().difference(match.matchDate!).inHours.abs() < 24;
    final isLive = match.status == 'live';

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.cardStroke),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 17),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(AppAssets.iconCal,
                        width: 14, height: 14, color: AppPalette.textMuted),
                    SizedBox(width: 8),
                    Text(
                      matchTime.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppPalette.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: formatColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          match.matchFormat ?? 'T20',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                        ),
                      ),
                      // Menu button
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (value) async {
                          if (value == 'view') {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.info,
                              arguments: match.id,
                            );
                          } else if (value == 'delete') {
                            showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Match?'),
                                content: Text(
                                  'Delete match: ${match.teamAId} vs ${match.teamBId}? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      try {
                                        await MatchService.deleteMatch(match.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Match deleted successfully'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error deleting match: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View Details'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppPalette.cardStroke),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TeamBadge(assetPath: teamAFlag),
                      SizedBox(height: 6),
                      Text(
                        match.teamAId.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Opacity(
                  opacity: 0.5,
                  child: Text(
                    'VS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppPalette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TeamBadge(assetPath: teamBFlag),
                      SizedBox(height: 6),
                      Text(
                        match.teamBId.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: AppPalette.textMuted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.venue ?? 'Venue TBD',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppPalette.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isLive
                            ? () {
                                // Any scorer can join an already-live match
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.liveUpdate,
                                  arguments: {
                                    'match': match,
                                    'tossWinner': match.tossWinner,
                                    'decision': match.tossDecision,
                                  },
                                );
                              }
                            : isToday
                                ? () => _showStartConfirmation(context, match)
                                : () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Reminder set!'),
                                      ),
                                    ),
                        icon: Icon(
                          isLive
                              ? Icons.sports_cricket_outlined
                              : (isToday
                                  ? Icons.play_arrow
                                  : Icons.notifications_outlined),
                          size: 16,
                          color: isLive || isToday
                              ? AppPalette.bgSecondary
                              : AppPalette.accent,
                        ),
                        label: Text(
                          isLive
                              ? 'Update Score'
                              : (isToday ? 'Start Match' : 'Set Reminder'),
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: isLive || isToday
                              ? AppPalette.accent
                              : AppPalette.accent.withValues(alpha: 0.2),
                          foregroundColor: isLive || isToday
                              ? AppPalette.bgSecondary
                              : AppPalette.accent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.info,
                        arguments: match,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.textPrimary,
                        side: BorderSide(color: AppPalette.cardStroke),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStartConfirmation(BuildContext context, Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Start Match?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to start ${match.teamAId} vs ${match.teamBId} at ${match.venue}?',
          style: TextStyle(color: AppPalette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
                style: TextStyle(color: AppPalette.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.toss,
                arguments: match,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppPalette.accent),
            child: Text('START',
                style: TextStyle(
                    color: AppPalette.bgSecondary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _LiveFixtureCard extends StatelessWidget {
  const _LiveFixtureCard({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        border: Border.all(color: AppPalette.cardStroke),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.live.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppPalette.live,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              Spacer(),
              Text(
                match.matchFormat?.toUpperCase() ?? 'MATCH',
                style: TextStyle(
                  color: AppPalette.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '${match.teamAId} vs ${match.teamBId}',
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            match.venue ?? 'Venue TBD',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppPalette.textMuted,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.liveUpdate,
                  arguments: {
                    'match': match,
                    'tossWinner': match.tossWinner,
                    'decision': match.tossDecision,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Update Score',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixturesData {
  const _FixturesData({
    required this.live,
    required this.upcoming,
  });

  final List<Match> live;
  final List<Match> upcoming;
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(Icons.flag, color: AppPalette.textMuted, size: 28),
        ),
      ),
    );
  }
}
