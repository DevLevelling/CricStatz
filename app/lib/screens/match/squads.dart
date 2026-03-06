import 'package:cricstatz/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cricstatz/services/profile_service.dart';
import 'package:cricstatz/services/match_service.dart';
import 'scoringsetup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS (Copied from CreateMatch for consistency)
// ─────────────────────────────────────────────────────────────────────────────
class _Tokens {
  static const Color surface1 = Color(0xFF0B1829);
  static const Color surface2 = Color(0xFF0F2040);
  static const Color surface3 = Color(0xFF162A4D);
  static const Color border = Color(0xFF1E3055);
  static const Color teamA = Color(0xFF38BDF8);
  static const Color teamB = Color(0xFFF87171);

  static const Color muted = Color(0xFF64748B);

  static const TextStyle labelStyle = TextStyle(
    color: Color(0xFF94A3B8),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );


}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class PlayerInfo {
  final String id;
  final String name;
  final String role; // "Batsman", "Bowler", "All-Rounder", "Wicket Keeper"
  bool isSelected;
  bool isCaptain;
  bool isWicketKeeper;

  PlayerInfo({
    required this.id,
    required this.name,
    required this.role,
    this.isSelected = false,
    this.isCaptain = false,
    this.isWicketKeeper = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SquadsScreen extends StatefulWidget {
  final String teamAName;
  final String teamBName;
  final String? venue;
  final String format;
  final DateTime? date;
  final int overs;

  const SquadsScreen({
    super.key,
    required this.teamAName,
    required this.teamBName,
    this.venue,
    required this.format,
    this.date,
    required this.overs,
  });

  @override
  State<SquadsScreen> createState() => _SquadsScreenState();
}

class _SquadsScreenState extends State<SquadsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseAnim;
  late final TabController _tabController;

  // Database Data
  bool _isLoading = true;
  List<PlayerInfo> teamA = [];
  List<PlayerInfo> teamB = [];

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _tabController = TabController(length: 2, vsync: this);
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    try {
      final profiles = await ProfileService.getAllProfiles();
      
      if (!mounted) return;
      
      setState(() {
        // Create independent lists from the same DB users for Team A and Team B
        teamA = profiles.map((p) => PlayerInfo(
          id: p.id,
          name: p.displayName,
          role: p.role,
        )).toList();
        
        teamB = profiles.map((p) => PlayerInfo(
          id: p.id,
          name: p.displayName,
          role: p.role,
        )).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    HapticFeedback.mediumImpact();

    // Collect selected player IDs for both teams
    final selectedTeamAIds = teamA
        .where((p) => p.isSelected)
        .map((p) => p.id)
        .toList();
    final selectedTeamBIds = teamB
        .where((p) => p.isSelected)
        .map((p) => p.id)
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppPalette.accent),
      ),
    );

    try {
      final match = await MatchService.createMatch(
        teamAId: widget.teamAName,
        teamBId: widget.teamBName,
        venue: widget.venue,
        matchFormat: widget.format,
        matchDate: widget.date,
        oversLimit: widget.overs,
      );

      await MatchService.updateMatchSquads(
        matchId: match.id,
        teamASquad: selectedTeamAIds,
        teamBSquad: selectedTeamBIds,
      );
      debugPrint(
        '✅ Squads saved for match ${match.id}: '
        'teamA=${selectedTeamAIds.length}, teamB=${selectedTeamBIds.length}',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save squads: $e')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Squads saved: A=${selectedTeamAIds.length}, B=${selectedTeamBIds.length}',
        ),
      ),
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ScoringSetupScreen(
          matchAlreadyCreated: true,
          teamAName: widget.teamAName,
          teamBName: widget.teamBName,
          venue: widget.venue,
          format: widget.format,
          date: widget.date,
          overs: widget.overs,
          teamASquadIds: selectedTeamAIds,
          teamBSquadIds: selectedTeamBIds,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;
          final slide = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: curve));
          final fade = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(fade),
            child: SlideTransition(
              position: animation.drive(slide),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Tokens.surface1,
      body: SafeArea(
        child: Column(
          children: [
            RepaintBoundary(child: _Header(pulseAnim: _pulseAnim)),
            const _StepBar(),
            
            // Tab Bar
            _TeamTabs(
              controller: _tabController,
              teamA: widget.teamAName,
              teamB: widget.teamBName,
            ),
            
            // Tab Views
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppPalette.accent))
                : TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _PlayerList(
                        teamColor: _Tokens.teamA,
                        players: teamA,
                        onUpdate: () => setState(() {}),
                      ),
                      _PlayerList(
                        teamColor: _Tokens.teamB,
                        players: teamB,
                        onUpdate: () => setState(() {}),
                      ),
                    ],
                  ),
            ),
            
            // Sticky CTA
            _BottomCta(
              onTap: _onSave,
              teamA: teamA,
              teamB: teamB,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _Header({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          // Back button
          Material(
            color: _Tokens.surface2,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppPalette.textPrimary, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title & Anim
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Squad Selection',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (ctx, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.accent.withValues(alpha: 0.5 + (0.5 * pulseAnim.value)),
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.accent.withValues(alpha: 0.4 * pulseAnim.value),
                                blurRadius: 8 * pulseAnim.value,
                                spreadRadius: 2 * pulseAnim.value,
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Select playing 11, Captain, and WK',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppPalette.textMuted,
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

// ─────────────────────────────────────────────────────────────────────────────
// TEAM TABS
// ─────────────────────────────────────────────────────────────────────────────
class _TeamTabs extends StatelessWidget {
  final TabController controller;
  final String teamA;
  final String teamB;

  const _TeamTabs({
    required this.controller,
    required this.teamA,
    required this.teamB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _Tokens.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Tokens.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _Tokens.surface3,
          border: Border.all(color: _Tokens.border),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppPalette.textPrimary,
        unselectedLabelColor: _Tokens.muted,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(4),
        onTap: (_) => HapticFeedback.selectionClick(),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _Tokens.teamA,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(teamA.toUpperCase(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _Tokens.teamB,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(teamB.toUpperCase(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYER LIST
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerList extends StatelessWidget {
  final Color teamColor;
  final List<PlayerInfo> players;
  final VoidCallback onUpdate;

  const _PlayerList({
    required this.teamColor,
    required this.players,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCount = players.where((p) => p.isSelected).length;

    return Column(
      children: [
        // Meta header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Squad List',
                style: _Tokens.labelStyle.copyWith(color: AppPalette.textMuted),
              ),
              RichText(
                text: TextSpan(
                  style: _Tokens.labelStyle.copyWith(fontSize: 12),
                  children: [
                    TextSpan(
                      text: '$selectedCount',
                      style: TextStyle(
                        color: selectedCount == 11 ? AppPalette.success : teamColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: ' / 11 Selected'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: players.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _PlayerCard(
              player: players[i],
              teamColor: teamColor,
              onToggleSelect: () {
                HapticFeedback.lightImpact();
                players[i].isSelected = !players[i].isSelected;
                onUpdate();
              },
              onToggleCaptain: () {
                HapticFeedback.selectionClick();
                if (!players[i].isSelected) return;
                for (var p in players) {
                  p.isCaptain = false;
                }
                players[i].isCaptain = true;
                onUpdate();
              },
              onToggleWK: () {
                HapticFeedback.selectionClick();
                if (!players[i].isSelected) return;
                for (var p in players) {
                  p.isWicketKeeper = false;
                }
                players[i].isWicketKeeper = true;
                onUpdate();
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerCard extends StatelessWidget {
  final PlayerInfo player;
  final Color teamColor;
  final VoidCallback onToggleSelect;
  final VoidCallback onToggleCaptain;
  final VoidCallback onToggleWK;

  const _PlayerCard({
    required this.player,
    required this.teamColor,
    required this.onToggleSelect,
    required this.onToggleCaptain,
    required this.onToggleWK,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = player.isSelected;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isActive ? _Tokens.surface2 : _Tokens.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? teamColor.withValues(alpha: 0.3) : _Tokens.border,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: teamColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleSelect,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Selection Circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? teamColor : Colors.transparent,
                    border: Border.all(
                      color: isActive ? teamColor : _Tokens.muted,
                      width: isActive ? 0 : 2,
                    ),
                  ),
                  child: isActive
                      ? const Icon(Icons.check, size: 16, color: _Tokens.surface1)
                      : null,
                ),
                const SizedBox(width: 14),
                
                // Avatar Placeholder
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _Tokens.surface3,
                  child: Text(
                    player.name.substring(0, 1),
                    style: TextStyle(
                      color: isActive ? AppPalette.textPrimary : _Tokens.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: TextStyle(
                          color: isActive ? AppPalette.textPrimary : AppPalette.textMuted,
                          fontSize: 15,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            player.role == 'Batsman'
                                ? Icons.sports_cricket
                                : player.role == 'Bowler'
                                    ? Icons.sports_baseball
                                    : Icons.compare_arrows_rounded,
                            size: 12,
                            color: _Tokens.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            player.role,
                            style: TextStyle(
                              color: _Tokens.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Role Badges (C / WK)
                if (isActive) ...[
                  _RoleBadge(
                    label: 'C',
                    isActive: player.isCaptain,
                    activeColor: AppPalette.accent,
                    onTap: onToggleCaptain,
                  ),
                  const SizedBox(width: 8),
                  _RoleBadge(
                    label: 'WK',
                    isActive: player.isWicketKeeper,
                    activeColor: _Tokens.teamA, // Distinctive color
                    onTap: onToggleWK,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _RoleBadge({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : _Tokens.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : _Tokens.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : _Tokens.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STICKY BOTTOM CTA
// ─────────────────────────────────────────────────────────────────────────────
class _BottomCta extends StatefulWidget {
  const _BottomCta({
    required this.onTap,
    required this.teamA,
    required this.teamB,
  });
  final VoidCallback onTap;
  final List<PlayerInfo> teamA;
  final List<PlayerInfo> teamB;

  @override
  State<_BottomCta> createState() => _BottomCtaState();
}

class _BottomCtaState extends State<_BottomCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selA = widget.teamA.where((p) => p.isSelected).length;
    final selB = widget.teamB.where((p) => p.isSelected).length;
    // For testing: allow progression with at least 1 player selected per team.
    const int minPlayersPerTeam = 1;
    final isValid = selA >= minPlayersPerTeam && selB >= minPlayersPerTeam;

    return Container(
      decoration: const BoxDecoration(
        color: _Tokens.surface1,
        border: Border(top: BorderSide(color: _Tokens.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: _Tokens.teamA, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('$selA/11', style: TextStyle(color: selA >= minPlayersPerTeam ? _Tokens.teamA : AppPalette.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 16),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: _Tokens.teamB, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('$selB/11', style: TextStyle(color: selB >= minPlayersPerTeam ? _Tokens.teamB : AppPalette.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTapDown: isValid ? (_) => setState(() => _pressed = true) : null,
            onTapUp: isValid ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            } : null,
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isValid ? LinearGradient(
                    colors: _pressed
                        ? [const Color(0xFF0080BB), const Color(0xFF004FAA)]
                        : [const Color(0xFF00B4E8), const Color(0xFF0063D8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ) : null,
                  color: isValid ? null : _Tokens.surface3,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isValid ? [
                    BoxShadow(
                      color: AppPalette.accent.withValues(alpha: _pressed ? 0.2 : 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Scoring Setup',
                      style: TextStyle(
                        color: isValid ? Colors.white : _Tokens.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios_rounded, color: isValid ? Colors.white : _Tokens.muted, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 2 of 3  ·  Review and finalize team squads',
            style: TextStyle(
              color: _Tokens.muted.withValues(alpha: 0.55),
              fontSize: 10.5,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BREADCRUMBS STEP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _StepBar extends StatelessWidget {
  const _StepBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: _Tokens.surface1,
      child: const Row(
        children: [
          _Step(label: 'Match Info', index: 1, state: _StepState.done),
          _StepConnector(filled: true),
          _Step(label: 'Squads', index: 2, state: _StepState.active),
          _StepConnector(filled: false),
          _Step(label: 'Scoring', index: 3, state: _StepState.upcoming),
        ],
      ),
    );
  }
}

enum _StepState { done, active, upcoming }

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.index,
    required this.state,
  });
  final String label;
  final int index;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final isActive = state == _StepState.active;
    final isDone = state == _StepState.done;
    final Color dotColor = isDone
        ? AppPalette.success
        : isActive
            ? AppPalette.accent
            : _Tokens.muted;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppPalette.accent.withValues(alpha: 0.15)
                : isDone
                    ? AppPalette.success.withValues(alpha: 0.1)
                    : const Color(0xFF1A2A40),
            border: Border.all(color: dotColor, width: isActive ? 2 : 1.5),
            boxShadow: isActive
                ? [BoxShadow(color: AppPalette.accent.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: AppPalette.success, size: 14)
                : Text(
                    '$index',
                    style: TextStyle(
                      color: isActive ? AppPalette.accent : _Tokens.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppPalette.accent : _Tokens.muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: filled
                ? [AppPalette.success, AppPalette.success.withValues(alpha: 0.5)]
                : [const Color(0xFF1E3050), const Color(0xFF1E3050)],
          ),
        ),
      ),
    );
  }
}
