import 'dart:ui';

import 'package:cricstatz/config/assets.dart';
import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/models/match_stats.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/app_bottom_nav_bar.dart';
import 'package:cricstatz/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Future<List<_ResultSection>> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _loadSections();
  }

  Future<List<_ResultSection>> _loadSections() async {
    final matches = await MatchService.getCompletedMatches();
    final resultEntries = await Future.wait(
      matches.map((match) async {
        try {
          final stats = await MatchService.getLiveScore(match.id);
          final summary = stats['summary'] as ScoreSummary?;
          return _ResultEntry(
            match: match,
            summary: summary,
          );
        } catch (_) {
          return _ResultEntry(
            match: match,
            summary: null,
          );
        }
      }),
    );

    final grouped = <String, List<_ResultData>>{};
    for (final entry in resultEntries) {
      final date = entry.match.matchDate ?? DateTime.now();
      final key = DateFormat('MMMM d, y').format(date);
      grouped.putIfAbsent(key, () => <_ResultData>[]).add(
            _ResultData.fromEntry(entry),
          );
    }

    final sections = grouped.entries
        .map((entry) => _ResultSection(date: entry.key, matches: entry.value))
        .toList();

    sections.sort((a, b) {
      final aDate = DateFormat('MMMM d, y').parse(a.date);
      final bDate = DateFormat('MMMM d, y').parse(b.date);
      return bDate.compareTo(aDate);
    });

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: FutureBuilder<List<_ResultSection>>(
                  future: _sectionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppPalette.accent,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load results: ${snapshot.error}',
                          style: const TextStyle(color: AppPalette.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final sections = snapshot.data ?? const <_ResultSection>[];
                    if (sections.isEmpty) {
                      return const Center(
                        child: Text(
                          'No completed matches found.',
                          style: TextStyle(color: AppPalette.textMuted),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      children: [
                        for (final section in sections) ...[
                          Text(
                            section.date.toUpperCase(),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppPalette.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      letterSpacing: 0.7,
                                    ),
                          ),
                          const SizedBox(height: 16),
                          ...section.matches.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ResultCard(data: m),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
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
          decoration: const BoxDecoration(
            color: Color(0xCC111721),
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
                        icon: Image.asset(
                          AppAssets.iconCal,
                          width: 20,
                          height: 20,
                          color: AppPalette.textPrimary,
                        ),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppPalette.bgSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Image.asset(
                          AppAssets.iconFil,
                          width: 20,
                          height: 20,
                          color: AppPalette.textPrimary,
                        ),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _ResultsQuickTabs(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsQuickTabs extends StatelessWidget {
  const _ResultsQuickTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TabItem(
            label: 'Live',
            isSelected: false,
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (r) => false,
            ),
          ),
          _TabItem(
            label: 'Upcoming',
            isSelected: false,
            onTap: () => Navigator.push(
              context,
              AppRoutes.buildUpcomingRoute(),
            ),
          ),
          _TabItem(label: 'Results', isSelected: true, onTap: () {}),
          _TabItem(label: "My Matche's", isSelected: false, onTap: () {}),
        ],
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
            const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 14),
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

class _ResultSection {
  const _ResultSection({required this.date, required this.matches});

  final String date;
  final List<_ResultData> matches;
}

class _ResultEntry {
  const _ResultEntry({
    required this.match,
    required this.summary,
  });

  final Match match;
  final ScoreSummary? summary;
}

class _ResultData {
  const _ResultData({
    required this.matchId,
    required this.format,
    required this.status,
    required this.teamA,
    required this.teamB,
    required this.teamAFlag,
    required this.teamBFlag,
    required this.scoreA,
    required this.scoreB,
    required this.outcome,
  });

  factory _ResultData.fromEntry(_ResultEntry entry) {
    final match = entry.match;
    final summary = entry.summary;
    final teamA = match.teamAId;
    final teamB = match.teamBId;

    final firstBattingTeam = _resolveFirstBattingTeam(match);
    final secondBattingTeam = firstBattingTeam == teamA ? teamB : teamA;

    String scoreA = '-';
    String scoreB = '-';
    String outcome = 'Match completed';

    if (summary != null) {
      final secondInningsRuns = int.tryParse(summary.runs) ?? 0;
      final secondInningsWickets = int.tryParse(summary.wickets) ?? 0;
      final target = int.tryParse(summary.target ?? '');
      final firstInningsRuns = target != null && target > 0 ? target - 1 : null;
      final secondInningsScore = '$secondInningsRuns/$secondInningsWickets';

      if (firstBattingTeam == teamA) {
        scoreA = firstInningsRuns?.toString() ?? '-';
        scoreB = secondInningsScore;
      } else {
        scoreA = secondInningsScore;
        scoreB = firstInningsRuns?.toString() ?? '-';
      }

      if (target != null && target > 0) {
        if (secondInningsRuns >= target) {
          final totalWickets = summary.squadSize != null ? summary.squadSize! - 1 : 10;
          final wicketsRemaining = totalWickets - secondInningsWickets;
          outcome = '$secondBattingTeam won by $wicketsRemaining wickets';
        } else {
          final margin = target - secondInningsRuns - 1;
          outcome = '$firstBattingTeam won by $margin runs';
        }
      } else {
        outcome = summary.summaryText ?? 'Match completed';
      }
    }

    return _ResultData(
      matchId: match.id,
      format: match.matchFormat ?? 'Match',
      status: 'Final Result',
      teamA: teamA,
      teamB: teamB,
      teamAFlag: _flagForTeam(teamA),
      teamBFlag: _flagForTeam(teamB),
      scoreA: scoreA,
      scoreB: scoreB,
      outcome: outcome,
    );
  }

  final String matchId;
  final String format;
  final String status;
  final String teamA;
  final String teamB;
  final String teamAFlag;
  final String teamBFlag;
  final String scoreA;
  final String scoreB;
  final String outcome;

  static String _resolveFirstBattingTeam(Match match) {
    final teamA = match.teamAId;
    final teamB = match.teamBId;
    final tossWinner = match.tossWinner;
    final decision = match.tossDecision?.toUpperCase();

    if (tossWinner == null || decision == null) {
      return teamA;
    }

    if (decision == 'BAT') {
      return tossWinner;
    }

    return tossWinner == teamA ? teamB : teamA;
  }

  static String _flagForTeam(String? teamName) {
    if (teamName == null) return AppAssets.flagInd;
    final name = teamName.toUpperCase();
    if (name.contains('INDIA') || name == 'IND') return AppAssets.flagInd;
    if (name.contains('AUSTRALIA') || name == 'AUS') return AppAssets.flagAus;
    if (name.contains('ENGLAND') || name == 'ENG') return AppAssets.flagEng;
    if (name.contains('SOUTH AFRICA') || name == 'RSA') {
      return AppAssets.flagRsa;
    }
    if (name.contains('NEW ZEALAND') || name == 'NZL') return AppAssets.flagNzl;
    if (name.contains('PAKISTAN') || name == 'PAK') return AppAssets.flagPak;
    return AppAssets.flagInd;
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.data});

  final _ResultData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x800F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.cardStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.bgSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data.format.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppPalette.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                  ),
                ),
                Text(
                  data.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.textMuted,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _ResultTeamBadge(assetPath: data.teamAFlag),
                      const SizedBox(height: 8),
                      Text(
                        data.teamA,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppPalette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.scoreA,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppPalette.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'VS',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _ResultTeamBadge(assetPath: data.teamBFlag),
                      const SizedBox(height: 8),
                      Text(
                        data.teamB,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppPalette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.scoreB,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppPalette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppPalette.cardStroke),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data.outcome,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.success,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.scoreboard,
                    arguments: data.matchId,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.bgSecondary,
                    foregroundColor: AppPalette.textPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View Scorecard',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTeamBadge extends StatelessWidget {
  const _ResultTeamBadge({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.flag, color: AppPalette.textMuted, size: 24),
        ),
      ),
    );
  }
}
