import 'package:cricstatz/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cricstatz/services/match_service.dart';
import 'upcoming_fixtures_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _Tokens {
  static const Color surface1 = Color(0xFF0B1829);
  static const Color surface2 = Color(0xFF0F2040);
  static const Color surface3 = Color(0xFF162A4D);
  static const Color border = Color(0xFF1E3055);
  static const Color muted = Color(0xFF64748B);
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ScoringSetupScreen extends StatefulWidget {
  final bool matchAlreadyCreated;
  final String teamAName;
  final String teamBName;
  final String? venue;
  final String format;
  final DateTime? date;
  final int overs;
  final List<String> teamASquadIds;
  final List<String> teamBSquadIds;

  const ScoringSetupScreen({
    super.key,
    this.matchAlreadyCreated = false,
    required this.teamAName,
    required this.teamBName,
    this.venue,
    required this.format,
    this.date,
    required this.overs,
    required this.teamASquadIds,
    required this.teamBSquadIds,
  });

  @override
  State<ScoringSetupScreen> createState() => _ScoringSetupScreenState();
}

class _ScoringSetupScreenState extends State<ScoringSetupScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  // Setup state defaults
  int _runsPerWide = 1;
  int _runsPerNoBall = 1;
  bool _allowByes = true;
  bool _allowLegByes = true;
  bool _countWideInOver = false;
  bool _countNoBallInOver = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    HapticFeedback.lightImpact();
    
    // Simulate Match Creation in Database
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _Tokens.surface2.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
              )
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppPalette.accent),
              SizedBox(height: 16),
              Text(
                'Creating Match...',
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.matchAlreadyCreated) {
      try {
        await MatchService.createMatch(
          teamAId: widget.teamAName,
          teamBId: widget.teamBName,
          venue: widget.venue,
          matchFormat: widget.format,
          matchDate: widget.date,
          oversLimit: widget.overs,
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create match: $e'), backgroundColor: Colors.red),
        );
        return;
      }
    }
    
    if (!mounted) return;
    
    // Close loading dialog
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppPalette.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Match setup saved!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    // Redirect to upcoming fixtures page
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const UpcomingFixturesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Extras Runs ──────────────────────────
                    const _SectionHeader(title: 'EXTRA RUNS', icon: Icons.exposure_plus_1_rounded),
                    
                    _CounterCard(
                      label: 'Runs per Wide',
                      value: _runsPerWide,
                      onIncrement: () => setState(() => _runsPerWide++),
                      onDecrement: () => setState(() {
                        if (_runsPerWide > 0) _runsPerWide--;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _CounterCard(
                      label: 'Runs per No-Ball',
                      value: _runsPerNoBall,
                      onIncrement: () => setState(() => _runsPerNoBall++),
                      onDecrement: () => setState(() {
                        if (_runsPerNoBall > 0) _runsPerNoBall--;
                      }),
                    ),
                    const SizedBox(height: 24),

                    // ── Ball Counts ──────────────────────────
                    const _SectionHeader(title: 'OVER COUNTING', icon: Icons.calculate_outlined),
                    
                    _ToggleCard(
                      label: 'Count Wide as legal delivery',
                      sublabel: 'If enabled, a wide ball reduces the remaining balls in the over.',
                      value: _countWideInOver,
                      onChanged: (v) => setState(() => _countWideInOver = v),
                    ),
                    const SizedBox(height: 12),
                    _ToggleCard(
                      label: 'Count No-Ball as legal delivery',
                      sublabel: 'If enabled, a no-ball reduces the remaining balls in the over.',
                      value: _countNoBallInOver,
                      onChanged: (v) => setState(() => _countNoBallInOver = v),
                    ),
                    const SizedBox(height: 24),

                    // ── Allowances ──────────────────────────
                    const _SectionHeader(title: 'ALLOWANCES', icon: Icons.rule_rounded),
                    
                    _ToggleCard(
                      label: 'Allow Byes',
                      sublabel: 'Runs scored without the ball hitting the bat or body.',
                      value: _allowByes,
                      onChanged: (v) => setState(() => _allowByes = v),
                    ),
                    const SizedBox(height: 12),
                    _ToggleCard(
                      label: 'Allow Leg Byes',
                      sublabel: 'Runs scored when the ball hits the batsman\'s body.',
                      value: _allowLegByes,
                      onChanged: (v) => setState(() => _allowLegByes = v),
                    ),
                    
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            
            // ── Sticky Bottom CTA ──────────────────────────────────────────
            _BottomCta(onTap: _onSave),
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
  const _Header({required this.pulseAnim});
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Back button
          Material(
            color: _Tokens.surface2,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppPalette.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Scoring Setup',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (context, child) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppPalette.accent.withValues(alpha: 0.4 + (pulseAnim.value * 0.6)),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.accent.withValues(alpha: pulseAnim.value * 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure run rules and extras allowed',
                  style: TextStyle(
                    fontSize: 13,
                    color: _Tokens.muted.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
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
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 14),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.accent, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _CounterCard extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterCard({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Tokens.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Tokens.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              _RoundButton(icon: Icons.remove_rounded, onTap: onDecrement),
              SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _RoundButton(icon: Icons.add_rounded, onTap: onIncrement),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Tokens.surface3,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: AppPalette.accent, size: 18),
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: value ? AppPalette.accent.withValues(alpha: 0.1) : _Tokens.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? AppPalette.accent.withValues(alpha: 0.5) : _Tokens.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: value ? AppPalette.accent : AppPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: _Tokens.muted.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeThumbColor: AppPalette.accent,
            activeTrackColor: AppPalette.accent.withValues(alpha: 0.2),
            inactiveThumbColor: _Tokens.muted,
            inactiveTrackColor: _Tokens.surface3,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STICKY BOTTOM CTA
// ─────────────────────────────────────────────────────────────────────────────
class _BottomCta extends StatefulWidget {
  const _BottomCta({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BottomCta> createState() => _BottomCtaState();
}

class _BottomCtaState extends State<_BottomCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Tokens.surface1,
        border: Border(top: BorderSide(color: _Tokens.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _pressed
                        ? [const Color(0xFF0080BB), const Color(0xFF004FAA)]
                        : [const Color(0xFF00B4E8), const Color(0xFF0063D8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.accent.withValues(alpha: _pressed ? 0.2 : 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Finish Match SetUp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.sports_esports_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 3 of 3  ·  Scoring configurations saved automatically',
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
          _Step(label: 'Squads', index: 2, state: _StepState.done),
          _StepConnector(filled: true),
          _Step(label: 'Scoring', index: 3, state: _StepState.active),
        ],
      ),
    );
  }
}

enum _StepState { done, active }

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
