import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/models/match_stats.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class MatchScoreboardScreen extends StatefulWidget {
  final String? matchId;
  const MatchScoreboardScreen({super.key, this.matchId});

  @override
  State<MatchScoreboardScreen> createState() => _MatchScoreboardScreenState();

  static const Color _card = Color(0xFF0F172A);
  static const Color _stroke = Color(0xFF1E293B);
  static const Color _headerOverlay = Color(0x660A1F43);
  static const Color _rowOverlay = Color(0x330D1729);
  static const Color _accentBlue = Color(0xFF60A5FA);
}

class _MatchScoreboardScreenState extends State<MatchScoreboardScreen> {
  bool _isLoading = true;
  Match? _match;
  ScoreSummary? _summary;
  List<BatsmanScore> _batsmen = [];
  BowlerScore? _bowler;
  Partnership? _partnership;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.matchId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        MatchService.getMatchDetails(widget.matchId!),
        MatchService.getLiveScore(widget.matchId!),
      ]);
      if (!mounted) return;
      final liveScore = results[1] as Map<String, dynamic>;
      setState(() {
        _match = results[0] as Match;
        _summary = liveScore['summary'] as ScoreSummary?;
        _batsmen = (liveScore['batsmen'] as List<dynamic>? ?? <dynamic>[])
            .whereType<BatsmanScore>()
            .toList();
        _bowler = liveScore['bowler'] as BowlerScore?;
        _partnership = liveScore['partnership'] as Partnership?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
                children: [
                 _TopBar(match: _match),
                 _Tabs(selectedIndex: 2, matchId: widget.matchId),
                 const SizedBox(height: 16),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   child: _isLoading
                      ? const Column(
                          children: [
                            SkeletonLoader(width: double.infinity, height: 60),
                            SizedBox(height: 16),
                            SkeletonLoader(width: double.infinity, height: 300),
                          ],
                        )
                      : _summary == null
                          ? _buildNoData()
                          : _buildScorecard(),
                 ),
               ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: MatchScoreboardScreen._card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MatchScoreboardScreen._stroke),
      ),
      child: const Center(
        child: Text(
          'No scorecard data available yet.\nStart scoring to see the scorecard.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppPalette.textMuted, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildScorecard() {
    final summary = _summary!;
    final battingTeam = summary.battingTeam ?? 'Batting Team';
    final inningsName = summary.inningsName;
    final runs = summary.runs;
    final wickets = summary.wickets;
    final overs = summary.overs;
    final totalStr = '$runs/$wickets ($overs ov)';

    final firstInnings = summary.firstInnings;

    return Column(
      children: [
        // ── 1st Innings (from snapshot, if available) ──
        if (firstInnings != null) ...[
          _buildFirstInningsSection(firstInnings),
          const SizedBox(height: 18),
        ],

        // ── Current Innings ──
        _InningsSummaryBar(
          title: '$battingTeam - $inningsName',
          total: totalStr,
        ),
        const SizedBox(height: 10),
        if (_batsmen.isNotEmpty) ...[
          _BattingTable(batsmen: _batsmen),
          _ExtrasTotal(
            totalRuns: runs,
            totalWickets: wickets,
            totalOvers: overs,
          ),
          const SizedBox(height: 12),
        ],
        if (_buildCurrentInningsBowlers().isNotEmpty) ...[
          _BowlingTable(bowlers: _buildCurrentInningsBowlers()),
          const SizedBox(height: 12),
        ],
        if (_partnership != null)
          _PartnershipCard(partnership: _partnership!),
        if (summary.target != null && summary.target!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TargetCard(summary: summary),
        ],
      ],
    );
  }

  List<BowlerScore> _buildCurrentInningsBowlers() {
    // Use allBowlers from summary if available
    if (_summary?.allBowlers != null && _summary!.allBowlers!.isNotEmpty) {
      return _summary!.allBowlers!
          .map((e) => BowlerScore.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Fall back to single current bowler
    if (_bowler != null) return [_bowler!];
    return [];
  }

  Widget _buildFirstInningsSection(Map<String, dynamic> data) {
    final team = data['batting_team'] as String? ?? '1st Innings';
    final runs = data['runs']?.toString() ?? '0';
    final wickets = data['wickets']?.toString() ?? '0';
    final overs = data['overs']?.toString() ?? '0.0';
    final totalStr = '$runs/$wickets ($overs ov)';

    // Parse batsmen
    final batsmenJson = data['batsmen'] as List<dynamic>? ?? [];
    final batsmen = batsmenJson
        .map((e) => BatsmanScore.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse bowlers
    final bowlerJson = data['bowler'] as List<dynamic>? ?? [];
    final bowlers = bowlerJson
        .map((e) => BowlerScore.fromJson(e as Map<String, dynamic>))
        .toList();

    return Column(
      children: [
        _InningsSummaryBar(
          title: '$team - 1st Innings',
          total: totalStr,
        ),
        const SizedBox(height: 10),
        if (batsmen.isNotEmpty) ...[
          _BattingTable(batsmen: batsmen),
          _ExtrasTotal(
            totalRuns: runs,
            totalWickets: wickets,
            totalOvers: overs,
          ),
          const SizedBox(height: 12),
        ],
        if (bowlers.isNotEmpty) ...[
          _BowlingTable(bowlers: bowlers),
        ],
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final Match? match;
  const _TopBar({this.match});

  @override
  Widget build(BuildContext context) {
    final teamA = match?.teamAId ?? 'Team A';
    final teamB = match?.teamBId ?? 'Team B';
    final subtitle = match?.matchFormat ?? 'Match Scorecard';
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 72,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: const BoxDecoration(
            color: Color(0xF20A1F43),
            border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppPalette.textPrimary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$teamA vs $teamB',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.share_outlined,
                  color: AppPalette.textPrimary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selectedIndex, this.matchId});

  final int selectedIndex;
  final String? matchId;

  @override
  Widget build(BuildContext context) {
    const tabs = ['INFO', 'LIVE', 'SCORECARD', 'PLAYERS'];
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 51,
          decoration: const BoxDecoration(
            color: Color(0xF20A1F43),
            border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (i == selectedIndex) return;
                    if (i == 0) {
                      Navigator.pushNamed(context, AppRoutes.info, arguments: matchId);
                    } else if (i == 1) {
                      Navigator.pushNamed(context, AppRoutes.live, arguments: matchId);
                    } else if (i == 2) {
                      // Already on scorecard
                    } else if (i == 3) {
                      Navigator.pushNamed(context, AppRoutes.players, arguments: matchId);
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppPalette.accent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      tabs[i],
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? AppPalette.accent
                                : AppPalette.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _InningsSummaryBar extends StatelessWidget {
  final String title;
  final String total;
  const _InningsSummaryBar({required this.title, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MatchScoreboardScreen._card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MatchScoreboardScreen._stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppPalette.progress,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            alignment: Alignment.center,
            child: Text(
              title.substring(0, title.length > 3 ? 3 : title.length).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            total,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _BattingTable extends StatelessWidget {
  final List<BatsmanScore> batsmen;
  const _BattingTable({required this.batsmen});

  @override
  Widget build(BuildContext context) {
    Widget headerCell(String label, {TextAlign align = TextAlign.center}) {
      return Text(
        label,
        textAlign: align,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              fontSize: 10,
            ),
      );
    }

    Widget row({
      required String name,
      required String status,
      required String r,
      required String b,
      required String f4,
      required String f6,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x801E293B))),
          color: MatchScoreboardScreen._rowOverlay,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1E293B),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppPalette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppPalette.textMuted,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _num(context, r, bold: true)),
            Expanded(child: _num(context, b, muted: true)),
            Expanded(child: _num(context, f4, muted: true)),
            Expanded(child: _num(context, f6, muted: true)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: MatchScoreboardScreen._card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MatchScoreboardScreen._stroke),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 9),
            decoration: const BoxDecoration(
              color: MatchScoreboardScreen._headerOverlay,
              border: Border(
                  bottom: BorderSide(color: MatchScoreboardScreen._stroke)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 5,
                    child: headerCell('BATTER', align: TextAlign.left)),
                Expanded(child: headerCell('R')),
                Expanded(child: headerCell('B')),
                Expanded(child: headerCell('4S')),
                Expanded(child: headerCell('6S')),
              ],
            ),
          ),
          ...batsmen.map((b) => row(
            name: b.name,
            status: b.dismissal ?? (b.isActive == true ? 'batting *' : 'not out'),
            r: b.runs,
            b: b.balls,
            f4: b.fours.toString(),
            f6: b.sixes.toString(),
          )),
        ],
      ),
    );
  }

  Widget _num(BuildContext context, String v,
      {bool bold = false, bool muted = false}) {
    return Text(
      v,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: muted ? AppPalette.textMuted : AppPalette.textPrimary,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: 14,
          ),
    );
  }
}

class _ExtrasTotal extends StatelessWidget {
  final String totalRuns;
  final String totalWickets;
  final String totalOvers;
  const _ExtrasTotal({
    required this.totalRuns,
    required this.totalWickets,
    required this.totalOvers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0x330A1F43),
        border: Border(
          left: BorderSide(color: MatchScoreboardScreen._stroke),
          right: BorderSide(color: MatchScoreboardScreen._stroke),
          bottom: BorderSide(color: MatchScoreboardScreen._stroke),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MatchScoreboardScreen._accentBlue,
                    fontWeight: FontWeight.w800,
                  ),
              children: [
                TextSpan(text: '$totalRuns '),
                TextSpan(
                  text: '($totalWickets wkts, $totalOvers ov)',
                  style: const TextStyle(
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BowlingTable extends StatelessWidget {
  final List<BowlerScore> bowlers;
  const _BowlingTable({required this.bowlers});

  @override
  Widget build(BuildContext context) {
    Widget headerCell(String t) => Text(
          t,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 10,
              ),
        );

    Widget row(
        String name, String o, String m, String r, String w, String eco) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x801E293B))),
          color: Color(0x330D1729),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(child: _num(context, o)),
            Expanded(child: _num(context, m, muted: true)),
            Expanded(child: _num(context, r)),
            Expanded(child: _num(context, w, blue: true)),
            Expanded(child: _num(context, eco, muted: true)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: MatchScoreboardScreen._card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MatchScoreboardScreen._stroke),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
            decoration: const BoxDecoration(
              color: MatchScoreboardScreen._headerOverlay,
              border: Border(
                  bottom: BorderSide(color: MatchScoreboardScreen._stroke)),
            ),
            child: Row(
              children: [
                Expanded(flex: 5, child: headerCell('BOWLER')),
                Expanded(child: headerCell('O')),
                Expanded(child: headerCell('M')),
                Expanded(child: headerCell('R')),
                Expanded(child: headerCell('W')),
                Expanded(child: headerCell('ECO')),
              ],
            ),
          ),
          ...bowlers.map((b) => row(b.name, b.overs, b.maidens, b.runs, b.wickets, b.econ)),
        ],
      ),
    );
  }

  Widget _num(BuildContext context, String v,
      {bool muted = false, bool blue = false}) {
    return Text(
      v,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: blue
                ? MatchScoreboardScreen._accentBlue
                : (muted ? AppPalette.textMuted : AppPalette.textPrimary),
            fontWeight: blue ? FontWeight.w800 : FontWeight.w500,
            fontSize: 14,
          ),
    );
  }
}

class _PartnershipCard extends StatelessWidget {
  final Partnership partnership;
  const _PartnershipCard({required this.partnership});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MatchScoreboardScreen._card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MatchScoreboardScreen._stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.handshake_outlined, color: AppPalette.textMuted, size: 18),
          const SizedBox(width: 10),
          Text(
            'Partnership',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Text(
            '${partnership.runs} runs (${partnership.balls} balls)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MatchScoreboardScreen._accentBlue,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final ScoreSummary summary;
  const _TargetCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MatchScoreboardScreen._card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MatchScoreboardScreen._stroke),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: ${summary.target}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (summary.reqRate != null)
                Text(
                  'RRR: ${summary.reqRate}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MatchScoreboardScreen._accentBlue,
                        fontWeight: FontWeight.w700,
                      ),
                ),
            ],
          ),
          if (summary.summaryText != null && summary.summaryText!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                summary.summaryText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.textMuted,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
