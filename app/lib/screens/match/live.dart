import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/assets.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/models/match_stats.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' show ImageFilter;

// ─── Color Constants ───────────────────────────────────────────────────────────
class AppColors {
  static const primary = AppPalette.bgPrimary;
  static const accent = Color(0xFF00C2FF);
  static const cardDark = Color(0xFF111827);
  static const textMain = Color(0xFFEAF2FF);
  static const white10 = Color(0x1AFFFFFF);
  static const white5 = Color(0x0DFFFFFF);
  static const white60 = Color(0x99FFFFFF);
  static const white80 = Color(0xCCFFFFFF);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
}

// ─── Main Screen ───────────────────────────────────────────────────────────────
class LiveMatchScreen extends StatefulWidget {
  final String? matchId;
  const LiveMatchScreen({super.key, this.matchId});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  Match? _match;
  Map<String, dynamic>? _liveData;
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>?>? _liveScoreSubscription;

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
    Match? match;
    Map<String, dynamic>? stats;

    try {
      match = await MatchService.getMatchDetails(widget.matchId!);
    } catch (_) {}

    try {
      stats = await MatchService.getLiveScore(widget.matchId!);
    } catch (_) {
      stats = null;
    }

    if (mounted) {
      setState(() {
        _match = match;
        _liveData = stats;
        _isLoading = false;
      });
    }

    _subscribeToLiveScore();
  }

  void _subscribeToLiveScore() {
    final matchId = widget.matchId;
    if (matchId == null) return;

    _liveScoreSubscription?.cancel();
    _liveScoreSubscription = MatchService.streamLiveScore(matchId).listen(
      (stats) {
        if (!mounted) return;
        setState(() {
          _liveData = stats;
        });
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _liveScoreSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildTabs(context, widget.matchId),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (_isLoading)
                          const ScoreBannerLoader()
                        else if (_liveData != null) ...[
                          _ScoreBanner(
                            match: _match,
                            summary: _liveData!['summary'] as ScoreSummary,
                          ),
                          _LiveContent(data: _liveData!),
                        ] else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.white5),
                            ),
                            child: const Text(
                              'Waiting for live score updates...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppPalette.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Match top bar identical to `info.dart` navbar style.
  Widget _buildHeader(BuildContext context) {
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
                      '${_match?.teamAId ?? "Lading..."} vs ${_match?.teamBId ?? ""}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _match?.matchFormat ?? 'Match Details',
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

  /// Tabs row identical to `info.dart` but with LIVE selected.
  Widget _buildTabs(BuildContext context, String? matchId) {
    const tabs = ['INFO', 'LIVE', 'SCORECARD', 'PLAYERS'];
    const selectedIndex = 1;

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
                    } else if (i == 2) {
                      Navigator.pushNamed(context, AppRoutes.scoreboard, arguments: matchId);
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

// ─── Score Banner ──────────────────────────────────────────────────────────────
class _ScoreBanner extends StatelessWidget {
  final Match? match;
  final ScoreSummary summary;

  const _ScoreBanner({required this.match, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1F44), Color(0xFF111827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.white5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            children: [
              // Overlay target graphic (iconb.png) similar to design.
              Positioned(
                top: 50,
                right: 20,
                child: Opacity(
                  opacity: 0.50,
                  child: Image.asset(
                    AppAssets.iconTarget,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 24),
                child: Column(
                  children: [
                    // Top section: score + live badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: India score
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                summary.inningsName,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${summary.runs}/${summary.wickets}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      color: AppColors.white80, fontSize: 13),
                                  children: [
                                    TextSpan(text: 'Overs: ${summary.overs}'),
                                    const TextSpan(
                                        text: '  •  ',
                                        style: TextStyle(
                                            color: AppColors.white60)),
                                    TextSpan(text: 'CRR: ${summary.crr}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right: live badge + target
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // LIVE badge with pulse dot
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PulseDot(),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Target: 320',
                                style: TextStyle(
                                    color: AppColors.white60, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              if (summary.summaryText != null)
                                Text(
                                  summary.summaryText!,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Divider
                    const Divider(color: AppColors.white10, height: 1),
                    const SizedBox(height: 16),
                    // Bottom: Australia score + required rate
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${match?.teamAId ?? "TEAM"} (1ST INNINGS)',
                                style: const TextStyle(
                                  color: AppColors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '---', // Could be fetched
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                            width: 1, height: 32, color: AppColors.white10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'REQUIRED RATE',
                                style: TextStyle(
                                  color: AppColors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary.reqRate ?? '0.0',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

// ─── Pulse Dot (animated) ──────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}

// ─── Live Content ──────────────────────────────────────────────────────────────
class _LiveContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LiveContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final partnership = data['partnership'] as Partnership;
    final batsmen = data['batsmen'] as List<BatsmanScore>;
    final bowler = data['bowler'] as BowlerScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PartnershipCard(partnership: partnership),
          const SizedBox(height: 16),
          _MiniScorecards(batsmen: batsmen),
          const SizedBox(height: 16),
          _BowlerCard(bowler: bowler),
          const SizedBox(height: 16),
          const _RecentBalls(),
        ],
      ),
    );
  }
}

// ─── Partnership Card ──────────────────────────────────────────────────────────
class _PartnershipCard extends StatelessWidget {
  final Partnership partnership;
  const _PartnershipCard({required this.partnership});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white5),
      ),
      child: Column(
        children: [
          const Text(
            'CURRENT PARTNERSHIP',
            style: TextStyle(
              color: AppColors.slate400,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${partnership.runs} ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '(${partnership.balls} balls)',
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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

// ─── Mini Scorecards ───────────────────────────────────────────────────────────
class _MiniScorecards extends StatelessWidget {
  final List<BatsmanScore> batsmen;
  const _MiniScorecards({required this.batsmen});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (batsmen.isNotEmpty)
          Expanded(
            child: _BatsmanCard(score: batsmen[0]),
          ),
        const SizedBox(width: 16),
        if (batsmen.length > 1)
          Expanded(
            child: _BatsmanCard(score: batsmen[1]),
          ),
      ],
    );
  }
}

class _BatsmanCard extends StatelessWidget {
  final BatsmanScore score;
  const _BatsmanCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final active = score.isActive ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: active
            ? const Border(
                left: BorderSide(color: AppColors.accent, width: 4),
                top: BorderSide(color: AppColors.white5),
                right: BorderSide(color: AppColors.white5),
                bottom: BorderSide(color: AppColors.white5),
              )
            : Border.all(color: AppColors.white5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                score.name,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (active)
                const Icon(Icons.stars_rounded,
                    color: AppColors.accent, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                score.runs,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${score.balls})',
                style: const TextStyle(color: AppColors.slate400, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '4s: ${score.fours}   6s: ${score.sixes}   SR: ${score.sr}',
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bowler Card ───────────────────────────────────────────────────────────────
class _BowlerCard extends StatelessWidget {
  final BowlerScore bowler;
  const _BowlerCard({required this.bowler});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Avatar placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.slate700,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white10),
                ),
                child: const Icon(Icons.person_outline,
                    color: AppColors.white60, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bowler.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bowler.overs} - ${bowler.maidens} - ${bowler.runs} - ${bowler.wickets}',
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'THIS OVER',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: (bowler.currentOverBalls ?? [])
                    .map((ball) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _BallChip(label: ball, isHighlight: false),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BallChip extends StatelessWidget {
  final String label;
  final bool isHighlight;
  const _BallChip({required this.label, required this.isHighlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.accent : AppColors.slate800,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isHighlight ? AppColors.primary : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Recent Balls ──────────────────────────────────────────────────────────────
class _RecentBalls extends StatelessWidget {
  const _RecentBalls();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'RECENT BALLS',
            style: TextStyle(
              color: AppColors.slate400,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _OverRow(
                overLabel: 'Ov 42',
                balls: const [
                  _BallData('1', BallType.normal),
                  _BallData('2', BallType.normal),
                  _BallData('4', BallType.boundary),
                  _BallData('W', BallType.wicket),
                  _BallData('0', BallType.normal),
                  _BallData('1', BallType.normal),
                ],
                faded: false,
              ),
              const SizedBox(width: 8),
              _OverRow(
                overLabel: 'Ov 41',
                balls: const [
                  _BallData('0', BallType.normal),
                  _BallData('1lb', BallType.normal),
                  _BallData('6', BallType.boundary),
                  _BallData('1', BallType.normal),
                  _BallData('1', BallType.normal),
                  _BallData('2', BallType.normal),
                ],
                faded: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum BallType { normal, boundary, wicket }

class _BallData {
  final String label;
  final BallType type;
  const _BallData(this.label, this.type);
}

class _OverRow extends StatelessWidget {
  final String overLabel;
  final List<_BallData> balls;
  final bool faded;

  const _OverRow({
    required this.overLabel,
    required this.balls,
    required this.faded,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Rotated over label
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                overLabel,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: balls.map((ball) {
                Color bgColor;
                Color textColor;

                switch (ball.type) {
                  case BallType.boundary:
                    bgColor = AppColors.accent;
                    textColor = AppColors.primary;
                    break;
                  case BallType.wicket:
                    bgColor = Colors.red.shade500;
                    textColor = Colors.white;
                    break;
                  case BallType.normal:
                    bgColor = AppColors.slate800;
                    textColor = Colors.white;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: ball.type == BallType.normal
                          ? Border.all(color: AppColors.white10)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        ball.label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: ball.label.length > 1 ? 8 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
