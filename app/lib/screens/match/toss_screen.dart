import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/coin_flip_widget.dart';
import 'package:flutter/material.dart';

class TossScreen extends StatefulWidget {
  const TossScreen({super.key});

  @override
  State<TossScreen> createState() => _TossScreenState();
}

enum TossStep { choosingCaller, flipping, results }

class _TossScreenState extends State<TossScreen> {
  final GlobalKey<CoinFlipWidgetState> _coinKey = GlobalKey();
  TossStep _step = TossStep.choosingCaller;
  
  Match? _match;
  String? _tossCaller; // Team ID
  String? _tossWinner; // Team ID
  String? _decision;    // 'BAT' or 'BOWL'
  String _callSide = 'HEADS'; // 'HEADS' or 'TAILS'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _match ??= ModalRoute.of(context)?.settings.arguments as Match?;
    if (_match != null && _tossCaller == null) {
      _tossCaller = _match!.teamAId;
    }
  }

  void _onFlip() async {
    if (_tossCaller == null) return;
    
    setState(() => _step = TossStep.flipping);
    
    // The coin widget returns a bool: true=Heads, false=Tails.
    // If the outcome matches the caller's chosen side, the caller wins.
    final isHeads = await _coinKey.currentState?.flip();
    
    if (isHeads != null) {
      setState(() {
        final callerChoseHeads = _callSide == 'HEADS';
        final callerWins =
            (isHeads && callerChoseHeads) || (!isHeads && !callerChoseHeads);

        if (isHeads) {
          // Just for visual feedback; winner is based on callerWins below.
        } else {
          // Same here; outcome is already in isHeads.
        }

        _tossWinner = callerWins
            ? _tossCaller
            : (_tossCaller == _match?.teamAId
                ? _match?.teamBId
                : _match?.teamAId);

        _step = TossStep.results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_match == null) {
      return Scaffold(body: Center(child: Text('No match data found', style: TextStyle(color: AppPalette.textPrimary))));
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      if (_step == TossStep.choosingCaller) _buildCallerSelection(),
                      
                      const SizedBox(height: 40),
                      CoinFlipWidget(key: _coinKey),
                      
                      const SizedBox(height: 40),
                      if (_step == TossStep.results) _buildTossResult(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: AppPalette.textPrimary, size: 20),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Toss',
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCallerSelection() {
    return Column(
      children: [
        Text(
          'Who is calling the toss?',
          style: TextStyle(color: AppPalette.textMuted, fontSize: 16),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _TeamTossCard(
              name: _match!.teamAId, 
              isSelected: _tossCaller == _match!.teamAId,
              onTap: () => setState(() => _tossCaller = _match!.teamAId),
            )),
            const SizedBox(width: 16),
            Expanded(child: _TeamTossCard(
              name: _match!.teamBId, 
              isSelected: _tossCaller == _match!.teamBId,
              onTap: () => setState(() => _tossCaller = _match!.teamBId),
            )),
          ],
        ),
        SizedBox(height: 24),
        Text(
          'What is the call?',
          style: TextStyle(color: AppPalette.textMuted, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DecisionButton(
                label: 'HEADS',
                icon: Icons.circle,
                isSelected: _callSide == 'HEADS',
                onTap: () => setState(() => _callSide = 'HEADS'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DecisionButton(
                label: 'TAILS',
                icon: Icons.circle_outlined,
                isSelected: _callSide == 'TAILS',
                onTap: () => setState(() => _callSide = 'TAILS'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTossResult() {
    return Column(
      children: [
        Text(
          '$_tossWinner won the toss!',
          style: TextStyle(color: AppPalette.accent, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          'Choose to Bat or Bowl',
          style: TextStyle(color: AppPalette.textMuted, fontSize: 16),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _DecisionButton(
              label: 'BAT',
              icon: Icons.sports_cricket,
              isSelected: _decision == 'BAT',
              onTap: () => setState(() => _decision = 'BAT'),
            )),
            const SizedBox(width: 16),
            Expanded(child: _DecisionButton(
              label: 'BOWL',
              icon: Icons.sports_baseball,
              isSelected: _decision == 'BOWL',
              onTap: () => setState(() => _decision = 'BOWL'),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    String label = 'FLIP COIN';
    VoidCallback? action = _onFlip;
    bool visible = true;

    if (_step == TossStep.flipping) {
      visible = false;
    } else if (_step == TossStep.results) {
      label = 'START SCORING';
      action = _decision != null ? _onStartScoring : null;
    }

    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(
            backgroundColor: action != null ? AppPalette.accent : AppPalette.accent.withValues(alpha: 0.3),
            foregroundColor: AppPalette.bgSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Future<void> _onStartScoring() async {
    if (_match == null || _tossWinner == null || _decision == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: AppPalette.accent)),
    );

    try {
      await MatchService.updateMatchToss(
        _match!.id,
        _tossWinner!,
        _decision!,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushNamed(
          context,
          AppRoutes.liveUpdate,
          arguments: {
            'match': _match,
            'tossWinner': _tossWinner,
            'decision': _decision,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update toss: $e')),
        );
      }
    }
  }
}

class _TeamTossCard extends StatelessWidget {
  const _TeamTossCard({required this.name, required this.isSelected, required this.onTap});
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.accent.withValues(alpha: 0.1) : AppPalette.cardPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppPalette.accent : AppPalette.cardStroke, width: 2),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppPalette.cardPrimary,
              child: Text(name[0], style: TextStyle(color: AppPalette.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppPalette.accent : AppPalette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({required this.label, required this.icon, required this.isSelected, required this.onTap});
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.accent : AppPalette.cardPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : AppPalette.cardStroke),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppPalette.textPrimary, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppPalette.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
