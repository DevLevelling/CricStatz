import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

Color get _playersBg => AppPalette.bgPrimary;
Color get _playersStroke => AppPalette.cardStroke;

class MatchPlayersScreen extends StatefulWidget {
  final String? matchId;
  const MatchPlayersScreen({super.key, this.matchId});

  @override
  State<MatchPlayersScreen> createState() => _MatchPlayersScreenState();
}

class _MatchPlayersScreenState extends State<MatchPlayersScreen> {
  bool _isIndiaSelected = true;
  Map<String, dynamic>? _playersData;
  bool _isLoading = true;
  Match? _match;

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
        MatchService.getMatchPlayers(widget.matchId!),
      ]);
      if (!mounted) return;
      setState(() {
        _match = results[0] as Match;
        _playersData = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  static Color get _bg => AppPalette.bgPrimary;
  static Color get _segBg => AppPalette.cardPrimary;
  static Color get _segSelected => AppPalette.accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopBar(context),
              _buildTabs(context, widget.matchId),
              const SizedBox(height: 16),
              _buildTeamSelector(context),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: PlayersListLoader(),
                )
              else ...[
                _buildPlayingXIHeader(context),
                _buildPlayersList(context),
                const SizedBox(height: 24),
                _buildBenchSection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final teamA = _match?.teamAId ?? 'Team A';
    final teamB = _match?.teamBId ?? 'Team B';
    final subtitle = _match?.matchFormat ?? 'Match Squads';
    // Match the same navbar style as `scoreboard.dart`.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 72,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppPalette.bgPrimary,
            border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                ),
                icon: Icon(Icons.arrow_back_ios_new,
                    color: AppPalette.textPrimary, size: 20),
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
                            color: AppPalette.textSubtle,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.share_outlined,
                    color: AppPalette.textPrimary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, String? matchId) {
    const tabs = ['INFO', 'LIVE', 'SCORECARD', 'PLAYERS'];
    const selectedIndex = 3;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 51,
          decoration: BoxDecoration(
            color: AppPalette.bgPrimary,
            border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
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
                      Navigator.pushNamed(context, AppRoutes.scoreboard, arguments: matchId);
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
                    padding: EdgeInsets.symmetric(vertical: 15),
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

  Widget _buildTeamSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _segBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _segButton(
                context,
                label: _match?.teamAId ?? 'INDIA',
                selected: _isIndiaSelected,
                onTap: () => setState(() => _isIndiaSelected = true),
              ),
            ),
            Expanded(
              child: _segButton(
                context,
                label: _match?.teamBId ?? 'AUSTRALIA',
                selected: !_isIndiaSelected,
                onTap: () => setState(() => _isIndiaSelected = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _segSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : AppPalette.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
      ),
    );
  }

  Widget _buildPlayingXIHeader(BuildContext context) {
    final teamKey = _isIndiaSelected ? 'teamA' : 'teamB';
    final count = (_playersData?[teamKey]?['playingXI'] as List<dynamic>?)?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Playing XI',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _segBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count PLAYERS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppPalette.textSubtle,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(BuildContext context) {
    final teamKey = _isIndiaSelected ? 'teamA' : 'teamB';
    final teamData = _playersData?[teamKey];
    final players = (teamData?['playingXI'] as List<dynamic>?)?.map((p) => _PlayerRowData(
      name: p['name'],
      role: p['role'],
      stat: p['stat'] ?? '',
      subStat: p['subStat'] ?? '',
      badge: p['badge'],
      imageUrl: p['imageUrl'] ?? '',
    )).toList() ?? [];

    if (players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Text(
            'No playing XI players selected for this team.',
            style: TextStyle(color: AppPalette.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: List.generate(players.length, (i) {
          return Column(
            children: [
              _PlayerRow(data: players[i]),
              if (i != players.length - 1)
                Divider(height: 1, color: AppPalette.cardStroke),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBenchSection(BuildContext context) {
    final teamKey = _isIndiaSelected ? 'teamA' : 'teamB';
    final teamData = _playersData?[teamKey];
    final bench = (teamData?['bench'] as List<dynamic>?)?.map((p) => _BenchRowData(
      name: p['name'],
      role: p['role'],
      imageUrl: p['imageUrl'] ?? '',
    )).toList() ?? [];

    if (bench.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bench Players',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 12),
          ...bench.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BenchRow(data: b),
              )),
        ],
      ),
    );
  }
}

class _PlayerRowData {
  final String name;
  final String role;
  final String stat;
  final String subStat;
  final String? badge;
  final Color badgeBg = const Color(0x00000000);
  final Color badgeFg = Colors.white;
  final String imageUrl;

  const _PlayerRowData({
    required this.name,
    required this.role,
    required this.stat,
    required this.subStat,
    required this.badge,
    required this.imageUrl,
  });
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.data});

  final _PlayerRowData data;

  static Color get _avatarBorder => AppPalette.cardStroke;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _avatarBorder, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        data.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _playersStroke,
                          alignment: Alignment.center,
                          child: Icon(Icons.person,
                              color: AppPalette.textMuted),
                        ),
                      ),
                    ),
                  ),
                  if (data.badge != null)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: data.badgeBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _playersBg, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          data.badge!,
                          style: TextStyle(
                            color: data.badgeFg,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.1,
                        ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    data.role,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.stat,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
              ),
              SizedBox(height: 2),
              Text(
                data.subStat,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenchRowData {
  final String name;
  final String role;
  final String imageUrl;

  const _BenchRowData({
    required this.name,
    required this.role,
    required this.imageUrl,
  });
}

class _BenchRow extends StatelessWidget {
  const _BenchRow({required this.data});

  final _BenchRowData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.cardStroke),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppPalette.cardStroke),
            ),
            child: ClipOval(
              child: Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _playersStroke,
                  alignment: Alignment.center,
                  child: Icon(Icons.person, color: AppPalette.textMuted),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
              ),
              SizedBox(height: 2),
              Text(
                data.role,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.textMuted,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
