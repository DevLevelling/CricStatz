import 'dart:ui' show ImageFilter;
import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/models/match_stats.dart';
import 'package:cricstatz/models/player.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScoreLiveUpdateScreen extends StatefulWidget {
  const ScoreLiveUpdateScreen({super.key});

  @override
  State<ScoreLiveUpdateScreen> createState() => _ScoreLiveUpdateScreenState();
}

class _ScoreLiveUpdateScreenState extends State<ScoreLiveUpdateScreen> {
  Match? _match;
  String? _tossWinner;
  String? _decision;
  String? _battingTeamName;
  String? _teamA;
  String? _teamB;
  String? _battingTeamId;
  String? _bowlingTeamId;
  List<Player> _battingTeamPlayers = [];
  List<Player> _bowlingTeamPlayers = [];
  bool _playersLoaded = false; // Track if players have been fetched
  String? _fetchError; // Holds an error message if fetch fails

  // Current match state - track actual batsmen and bowler
  int _strikerIndex = 0;
  int _nonStrikerIndex = 1;
  int _bowlerIndex = -1;

  // Scoring state
  int _runs = 0;
  int _wickets = 0;
  double _overs = 0.0;
  int _oversLimit = 0;
  final List<String> _recentBalls = [];
  final List<String> _currentOverBalls = [];
  int _legalBallsBowled = 0;
  int _partnershipRuns = 0;
  int _partnershipBalls = 0;

  // Per-player stats tracking
  final Map<String, Map<String, dynamic>> _playerStats = {};

  // History for Undo
  final List<Map<String, dynamic>> _history = [];
  int _innings = 1;
  int _firstInningsRuns = 0; // Track 1st innings total
  int _target = 0;
  bool _isTransitionInProgress = false;
  bool _isBowlerPickerVisible = false;
  bool _bowlerPickerForce = false;
  bool _hasEnsuredLiveStatus = false;
  bool _hasInitializedSession = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitializedSession) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _hasInitializedSession = true;
      _match = args['match'] as Match?;
      _tossWinner = (args['tossWinner'] as String?) ?? _match?.tossWinner;
      _decision = ((args['decision'] as String?) ?? _match?.tossDecision)
          ?.toUpperCase();

      debugPrint('=== Match Started ===');
      debugPrint('Toss Winner: $_tossWinner');
      debugPrint('Decision: $_decision');

      if (_match != null) {
        if (!_hasEnsuredLiveStatus) {
          _hasEnsuredLiveStatus = true;
          MatchService.ensureMatchLive(_match!.id).catchError((e) {
            debugPrint('Failed to ensure live status: $e');
          });
        }

        _oversLimit = _match!.oversLimit;
        _teamA = _match!.teamAId;
        _teamB = _match!.teamBId;
        debugPrint('Team A ID: $_teamA');
        debugPrint('Team B ID: $_teamB');

        if (_battingTeamName == null) {
          final teamA = _teamA!;
          final teamB = _teamB!;
          final isBatDecision = _decision == 'BAT';
          _battingTeamName = isBatDecision
              ? _tossWinner
              : (_tossWinner == teamA ? teamB : teamA);

          debugPrint('Batting Team Name: $_battingTeamName');

          // Determine batting and bowling team IDs
          // _tossWinner should be a team ID for this logic to work
          if (isBatDecision) {
            // Toss winner chose to bat
            _battingTeamId = _tossWinner;
            _bowlingTeamId = _tossWinner == teamA ? teamB : teamA;
            debugPrint('Decision is BAT - Winner bats');
          } else {
            // Toss winner chose to field, so other team bats
            _battingTeamId = _tossWinner == teamA ? teamB : teamA;
            _bowlingTeamId = _tossWinner;
            debugPrint('Decision is FIELD - Winner fields');
          }

          debugPrint(
              'Final - Batting Team ID: $_battingTeamId, Bowling Team ID: $_bowlingTeamId');

          // Fetch batting team players first, then restore existing score.
          _fetchBattingTeamPlayers().then((_) {
            if (mounted && _playersLoaded && _fetchError == null) {
              debugPrint(
                  'Players fetched successfully, restoring previous score if available');
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _restoreOrInitializeLiveScore();
                }
              });
            }
          });
        }
      }
    }
  }

  int get _maxWickets {
    if (_battingTeamPlayers.length <= 1) return 1;
    return _battingTeamPlayers.length - 1;
  }

  String _oversStringFromBalls(int legalBalls) {
    final overs = legalBalls ~/ 6;
    final balls = legalBalls % 6;
    return '$overs.$balls';
  }

  double _calculateCurrentRunRate() {
    if (_legalBallsBowled == 0) return 0.0;
    return _runs / (_legalBallsBowled / 6.0);
  }

  double _calculateRequiredRunRate() {
    if (_innings != 2 || _target == 0 || _oversLimit == 0) return 0.0;
    final ballsRemaining = (_oversLimit * 6) - _legalBallsBowled;
    final runsRemaining = _target - _runs;
    if (runsRemaining <= 0 || ballsRemaining <= 0) return 0.0;
    return (runsRemaining * 6.0) / ballsRemaining;
  }

  void _switchStrike() {
    final temp = _strikerIndex;
    _strikerIndex = _nonStrikerIndex;
    _nonStrikerIndex = temp;
  }

  void _showBowlerSelectionDialog({bool force = false}) {
    if (!mounted || _bowlingTeamPlayers.isEmpty) return;
    if (!force && _bowlerIndex >= 0 && _isBowlerPickerVisible) return;
    setState(() {
      _bowlerPickerForce = force;
      _isBowlerPickerVisible = true;
    });
  }

  void _hideBowlerSelectionDialog() {
    if (_bowlerPickerForce) return;
    setState(() {
      _isBowlerPickerVisible = false;
    });
  }

  void _selectBowler(int index) {
    setState(() {
      _bowlerIndex = index;
      _isBowlerPickerVisible = false;
      _bowlerPickerForce = false;
    });
    _syncScore();
  }

  void _updateOversFromBalls() {
    _overs = double.parse(_oversStringFromBalls(_legalBallsBowled));
  }

  void _bringNextBatterIn(int dismissedIndex) {
    int nextBatsmanIndex = 0;
    while (nextBatsmanIndex < _battingTeamPlayers.length) {
      final candidate = _battingTeamPlayers[nextBatsmanIndex];
      final isOut = _playerStats[candidate.id]?['out'] ?? false;
      final inMiddle = nextBatsmanIndex == _strikerIndex ||
          nextBatsmanIndex == _nonStrikerIndex;
      if (!isOut && !inMiddle) {
        if (dismissedIndex == _strikerIndex) {
          _strikerIndex = nextBatsmanIndex;
        } else {
          _nonStrikerIndex = nextBatsmanIndex;
        }
        return;
      }
      nextBatsmanIndex++;
    }
  }

  bool get _hasValidBowlerIndex =>
      _bowlerIndex >= 0 && _bowlerIndex < _bowlingTeamPlayers.length;

  Player? get _currentBowler =>
      _hasValidBowlerIndex ? _bowlingTeamPlayers[_bowlerIndex] : null;

  void _checkAutomaticTransitions() {
    if (_wickets >= _maxWickets) {
      _handleInningsOrMatchComplete();
      return;
    }

    if (_innings == 2 && _target > 0 && _runs >= _target) {
      _handleInningsOrMatchComplete();
      return;
    }

    if (_oversLimit > 0 && _legalBallsBowled >= (_oversLimit * 6)) {
      _handleInningsOrMatchComplete();
    }
  }

  Future<void> _syncScore() async {
    if (_match == null) return;

    final crr = _calculateCurrentRunRate();
    final reqRate = _calculateRequiredRunRate();
    final ballsRemaining = _oversLimit > 0
        ? ((_oversLimit * 6) - _legalBallsBowled).clamp(0, 9999)
        : 0;
    final runsRemaining = (_target - _runs).clamp(0, 9999);

    final summary = ScoreSummary(
      inningsName: _innings == 1 ? '1st Innings' : '2nd Innings',
      runs: _runs.toString(),
      wickets: _wickets.toString(),
      overs: _oversStringFromBalls(_legalBallsBowled),
      crr: crr.toStringAsFixed(2),
      target: _target > 0 ? _target.toString() : null,
      reqRate: _innings == 2 ? reqRate.toStringAsFixed(2) : null,
      summaryText: _innings == 2 && _target > 0
          ? (_runs >= _target
              ? 'Target achieved'
              : 'Need $runsRemaining from $ballsRemaining balls')
          : null,
      battingTeam: _battingTeamName ?? 'Batting Team',
    );

    // Build batsman list with proper indices
    final batsmen = <BatsmanScore>[];

    if (_strikerIndex >= 0 && _strikerIndex < _battingTeamPlayers.length) {
      final striker = _battingTeamPlayers[_strikerIndex];
      final strikerStats = _playerStats[striker.id] ?? {};
      batsmen.add(
        BatsmanScore(
          name: striker.name,
          runs: (strikerStats['runs'] ?? 0).toString(),
          balls: (strikerStats['balls'] ?? 0).toString(),
          fours: strikerStats['fours'] ?? 0,
          sixes: strikerStats['sixes'] ?? 0,
          sr: strikerStats['sr'] ?? '0.0',
          isActive: true,
        ),
      );
    }

    if (_nonStrikerIndex >= 0 &&
        _nonStrikerIndex < _battingTeamPlayers.length) {
      final nonStriker = _battingTeamPlayers[_nonStrikerIndex];
      final nonStrikerStats = _playerStats[nonStriker.id] ?? {};
      batsmen.add(
        BatsmanScore(
          name: nonStriker.name,
          runs: (nonStrikerStats['runs'] ?? 0).toString(),
          balls: (nonStrikerStats['balls'] ?? 0).toString(),
          fours: nonStrikerStats['fours'] ?? 0,
          sixes: nonStrikerStats['sixes'] ?? 0,
          sr: nonStrikerStats['sr'] ?? '0.0',
          isActive: false,
        ),
      );
    }

    // Get current bowler with proper stats
    final currentBowler = _currentBowler;
    BowlerScore bowler = BowlerScore(
      name: currentBowler?.name ?? 'Bowler',
      overs: '0.0',
      maidens: '0',
      runs: '0',
      wickets: '0',
      econ: '0.0',
      currentOverBalls: List<String>.from(_currentOverBalls),
    );

    if (currentBowler != null) {
      final bowlerPlayer = currentBowler;
      final bowlerStats = _playerStats[bowlerPlayer.id] ?? {};
      final ballsBowled = (bowlerStats['balls_bowled'] ?? 0) as int;
      final runsConceded = (bowlerStats['runs'] ?? 0) as int;

      // Convert balls bowled to overs format
      final overs = ballsBowled ~/ 6;
      final balls = ballsBowled % 6;
      final oversStr = '$overs.$balls';

      // Calculate economy rate
      final econ = ballsBowled > 0
          ? (runsConceded / (ballsBowled / 6.0)).toStringAsFixed(2)
          : '0.0';

      bowler = BowlerScore(
        name: bowlerPlayer.name,
        overs: oversStr,
        maidens: '0',
        runs: runsConceded.toString(),
        wickets: (bowlerStats['wickets'] ?? 0).toString(),
        econ: econ,
        currentOverBalls: List<String>.from(_currentOverBalls),
      );
    }

    try {
      await MatchService.updateLiveScore(
        matchId: _match!.id,
        summary: summary,
        batsmen: batsmen,
        bowler: bowler,
        partnership: Partnership(
          runs: _partnershipRuns.toString(),
          balls: _partnershipBalls.toString(),
        ),
      );
    } catch (e) {
      debugPrint('Error syncing score: $e');
    }
  }

  Future<void> _restoreOrInitializeLiveScore() async {
    final restored = await _restoreExistingLiveScore();
    if (!restored) {
      await _syncScore();
    }
  }

  int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  int _ballsFromOversString(String overs) {
    final parts = overs.split('.');
    if (parts.isEmpty) return 0;
    final completedOvers = int.tryParse(parts[0]) ?? 0;
    final ballsInCurrentOver =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return (completedOvers * 6) + ballsInCurrentOver.clamp(0, 5);
  }

  int _playerIndexByName(List<Player> players, String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return -1;
    for (var i = 0; i < players.length; i++) {
      if (players[i].name.trim().toLowerCase() == normalized) return i;
    }
    return -1;
  }

  Future<bool> _restoreExistingLiveScore() async {
    if (_match == null) return false;

    try {
      final stats = await MatchService.getLiveScore(_match!.id);
      final summary = stats['summary'] as ScoreSummary?;
      if (summary == null) return false;

      final batsmen = (stats['batsmen'] as List<dynamic>? ?? <dynamic>[])
          .whereType<BatsmanScore>()
          .toList();
      final bowler = stats['bowler'] as BowlerScore?;
      final partnership = stats['partnership'] as Partnership?;

      final restoredRuns = _parseIntSafe(summary.runs);
      final restoredWickets = _parseIntSafe(summary.wickets);
      final restoredBalls = _ballsFromOversString(summary.overs);
      final restoredTarget = _parseIntSafe(summary.target);
      final restoredInnings =
          summary.inningsName.toLowerCase().contains('2nd') ? 2 : 1;

      setState(() {
        _runs = restoredRuns;
        _wickets = restoredWickets;
        _legalBallsBowled = restoredBalls;
        _updateOversFromBalls();
        _target = restoredTarget;
        _innings = restoredInnings;
        _firstInningsRuns =
            restoredTarget > 0 ? restoredTarget - 1 : _firstInningsRuns;
        _battingTeamName = summary.battingTeam ?? _battingTeamName;
        _partnershipRuns = _parseIntSafe(partnership?.runs);
        _partnershipBalls = _parseIntSafe(partnership?.balls);

        _currentOverBalls
          ..clear()
          ..addAll(
              (bowler?.currentOverBalls ?? const <String>[]).cast<String>());
        _recentBalls
          ..clear()
          ..addAll(_currentOverBalls.reversed.take(6));

        for (final b in batsmen) {
          final index = _playerIndexByName(_battingTeamPlayers, b.name);
          if (index < 0) continue;
          final playerId = _battingTeamPlayers[index].id;
          _playerStats[playerId] = {
            ...(_playerStats[playerId] ?? <String, dynamic>{}),
            'runs': _parseIntSafe(b.runs),
            'balls': _parseIntSafe(b.balls),
            'fours': b.fours,
            'sixes': b.sixes,
            'sr': b.sr,
          };
          if (b.isActive == true) {
            _strikerIndex = index;
          } else if (_nonStrikerIndex == _strikerIndex ||
              _nonStrikerIndex == 1) {
            _nonStrikerIndex = index;
          }
        }

        if (_nonStrikerIndex == _strikerIndex &&
            _battingTeamPlayers.length > 1) {
          _nonStrikerIndex = _strikerIndex == 0 ? 1 : 0;
        }

        if (bowler != null) {
          final bowlerIndex =
              _playerIndexByName(_bowlingTeamPlayers, bowler.name);
          if (bowlerIndex >= 0) {
            _bowlerIndex = bowlerIndex;
            final bowlerId = _bowlingTeamPlayers[bowlerIndex].id;
            _playerStats[bowlerId] = {
              ...(_playerStats[bowlerId] ?? <String, dynamic>{}),
              'runs': _parseIntSafe(bowler.runs),
              'wickets': _parseIntSafe(bowler.wickets),
              'balls_bowled': _ballsFromOversString(bowler.overs),
              'economy': bowler.econ,
            };
          }
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchBattingTeamPlayers() async {
    debugPrint('=== _fetchBattingTeamPlayers START ===');
    debugPrint(
        '_battingTeamId: $_battingTeamId (type: ${_battingTeamId.runtimeType})');
    debugPrint(
        '_bowlingTeamId: $_bowlingTeamId (type: ${_bowlingTeamId.runtimeType})');

    if (_battingTeamId == null || _bowlingTeamId == null) {
      debugPrint('❌ ERROR: Team IDs are null, returning early');
      debugPrint('  _battingTeamId: $_battingTeamId');
      debugPrint('  _bowlingTeamId: $_bowlingTeamId');
      if (mounted) {
        setState(() {
          _playersLoaded = false;
          _fetchError = 'Team IDs are missing for this match.';
        });
      }
      return;
    }

    if (_battingTeamId!.isEmpty || _bowlingTeamId!.isEmpty) {
      debugPrint('❌ ERROR: Team IDs are empty strings');
      if (mounted) {
        setState(() {
          _playersLoaded = false;
          _fetchError = 'Team IDs are empty for this match.';
        });
      }
      return;
    }

    try {
      if (_match == null) {
        throw Exception('Match is missing while loading squads');
      }

      final squads = await MatchService.getMatchSquadPlayers(_match!.id);
      final teamAPlayers = squads['teamA'] ?? <Player>[];
      final teamBPlayers = squads['teamB'] ?? <Player>[];

      final isTeamABatting = _battingTeamId == _teamA;
      final battingPlayers = isTeamABatting ? teamAPlayers : teamBPlayers;
      final bowlingPlayers = isTeamABatting ? teamBPlayers : teamAPlayers;

      if (teamAPlayers.isEmpty || teamBPlayers.isEmpty) {
        throw Exception(
          'Squads not found on match. Save team squads first in squad selection.',
        );
      }

      debugPrint('✅ Loaded squad players from match row');
      debugPrint('  teamA squad: ${teamAPlayers.length}');
      debugPrint('  teamB squad: ${teamBPlayers.length}');
      debugPrint('  batting players: ${battingPlayers.length}');
      debugPrint('  bowling players: ${bowlingPlayers.length}');

      if (mounted) {
        setState(() {
          _battingTeamPlayers = battingPlayers;
          _bowlingTeamPlayers = bowlingPlayers;
          _playersLoaded = true;
          _fetchError = null;

          debugPrint(
              '📊 setState called - Initializing player stats from squads');
          debugPrint('  Batting squad: ${battingPlayers.length} players');
          debugPrint('  Bowling squad: ${bowlingPlayers.length} players');

          // Initialize player stats for batting team
          for (final player in battingPlayers) {
            if (!_playerStats.containsKey(player.id)) {
              _playerStats[player.id] = {
                'runs': 0,
                'balls': 0,
                'fours': 0,
                'sixes': 0,
                'sr': '0.0',
                'out': false,
              };
              debugPrint(
                  '  ✓ Initialized batsman: ${player.name} (ID: ${player.id})');
            }
          }

          // Initialize player stats for bowling team
          for (final player in bowlingPlayers) {
            if (!_playerStats.containsKey(player.id)) {
              _playerStats[player.id] = {
                'runs': 0,
                'balls': 0,
                'fours': 0,
                'sixes': 0,
                'sr': '0.0',
                'out': false,
                'balls_bowled': 0,
                'wickets': 0,
                'economy': '0.0'
              };
              debugPrint(
                  '  ✓ Initialized bowler: ${player.name} (ID: ${player.id})');
            }
          }

          debugPrint('=== _fetchBattingTeamPlayers COMPLETE ===');
        });
        if (_bowlerIndex < 0 && bowlingPlayers.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showBowlerSelectionDialog(force: true);
          });
        }
      } else {
        debugPrint('⚠️ Widget not mounted, setState not called');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching team players: $e');
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      if (mounted) {
        setState(() {
          _playersLoaded = false;
          _fetchError = e.toString();
        });
      }
    }
  }

  void _saveHistory() {
    _history.add({
      'runs': _runs,
      'wickets': _wickets,
      'overs': _overs,
      'legalBallsBowled': _legalBallsBowled,
      'recentBalls': List<String>.from(_recentBalls),
      'currentOverBalls': List<String>.from(_currentOverBalls),
      'strikerIndex': _strikerIndex,
      'nonStrikerIndex': _nonStrikerIndex,
      'bowlerIndex': _bowlerIndex,
      'partnershipRuns': _partnershipRuns,
      'partnershipBalls': _partnershipBalls,
      'playerStats': Map<String, Map<String, dynamic>>.from(_playerStats
          .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)))),
    });
    if (_history.length > 20) _history.removeAt(0);
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      final last = _history.removeLast();
      _runs = last['runs'] as int;
      _wickets = last['wickets'] as int;
      _overs = last['overs'] as double;
      _legalBallsBowled = (last['legalBallsBowled'] ?? 0) as int;
      _recentBalls.clear();
      _recentBalls.addAll(last['recentBalls'] as List<String>);
      _currentOverBalls.clear();
      _currentOverBalls.addAll(
          (last['currentOverBalls'] as List<dynamic>? ?? <dynamic>[])
              .cast<String>());
      _strikerIndex = last['strikerIndex'] as int;
      _nonStrikerIndex = last['nonStrikerIndex'] as int;
      _bowlerIndex = last['bowlerIndex'] as int;
      _partnershipRuns = (last['partnershipRuns'] ?? 0) as int;
      _partnershipBalls = (last['partnershipBalls'] ?? 0) as int;
      _playerStats.clear();
      final stats = last['playerStats'] as Map<String, Map<String, dynamic>>;
      _playerStats.addAll(
          stats.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))));
    });
    _syncScore();
    HapticFeedback.mediumImpact();
  }

  bool get _canBowlNextLegalBall =>
      _oversLimit == 0 || _legalBallsBowled < (_oversLimit * 6);

  void _applyBall({
    required String label,
    int runDelta = 0,
    bool isLegal = true,
    bool isWicket = false,
    int? dismissedBatsmanIndex,
    bool creditWicketToBowler = true,
  }) {
    // For legal balls, respect overs limit and innings transitions.
    if (isLegal && !_canBowlNextLegalBall) {
      _handleInningsOrMatchComplete();
      return;
    }
    if (_bowlerIndex < 0 || _bowlerIndex >= _bowlingTeamPlayers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a bowler before scoring')),
      );
      _showBowlerSelectionDialog(force: true);
      return;
    }

    _saveHistory();

    setState(() {
      // Update team runs
      _runs += runDelta;
      if (isWicket) {
        _wickets++;
      } else {
        _partnershipRuns += runDelta;
      }

      _recentBalls.insert(0, label);
      if (_recentBalls.length > 6) _recentBalls.removeLast();
      _currentOverBalls.add(label);

      // Update per-player stats (only for legal balls)
      if (isLegal &&
          _strikerIndex >= 0 &&
          _strikerIndex < _battingTeamPlayers.length) {
        final striker = _battingTeamPlayers[_strikerIndex];
        if (!_playerStats.containsKey(striker.id)) {
          _playerStats[striker.id] = {
            'runs': 0,
            'balls': 0,
            'fours': 0,
            'sixes': 0,
            'sr': '0.0',
            'out': false
          };
        }

        // Add runs to striker
        _playerStats[striker.id]!['runs'] =
            (_playerStats[striker.id]!['runs'] as int) + runDelta;

        // Add ball faced
        _playerStats[striker.id]!['balls'] =
            (_playerStats[striker.id]!['balls'] as int) + 1;

        // Track fours and sixes
        if (runDelta == 4) {
          _playerStats[striker.id]!['fours'] =
              (_playerStats[striker.id]!['fours'] as int) + 1;
        } else if (runDelta == 6) {
          _playerStats[striker.id]!['sixes'] =
              (_playerStats[striker.id]!['sixes'] as int) + 1;
        }

        // Calculate strike rate
        final balls = _playerStats[striker.id]!['balls'] as int;
        final runs = _playerStats[striker.id]!['runs'] as int;
        if (balls > 0) {
          _playerStats[striker.id]!['sr'] =
              ((runs / balls) * 100).toStringAsFixed(2);
        }

        _partnershipBalls += 1;
      }

      // Update bowler stats
      if (isLegal &&
          _bowlerIndex >= 0 &&
          _bowlerIndex < _bowlingTeamPlayers.length) {
        final bowler = _bowlingTeamPlayers[_bowlerIndex];
        if (!_playerStats.containsKey(bowler.id)) {
          _playerStats[bowler.id] = {
            'runs': 0,
            'balls': 0,
            'fours': 0,
            'sixes': 0,
            'sr': '0.0',
            'out': false,
            'balls_bowled': 0,
            'wickets': 0,
            'economy': '0.0'
          };
        }
        _playerStats[bowler.id]!['balls_bowled'] =
            (_playerStats[bowler.id]!['balls_bowled'] as int) + 1;
        _playerStats[bowler.id]!['runs'] =
            (_playerStats[bowler.id]!['runs'] as int) + runDelta;
        if (isWicket && creditWicketToBowler) {
          _playerStats[bowler.id]!['wickets'] =
              (_playerStats[bowler.id]!['wickets'] as int) + 1;
        }
      }

      if (isLegal) {
        _legalBallsBowled += 1;
        _updateOversFromBalls();
      }

      if (isWicket && dismissedBatsmanIndex != null) {
        final dismissedPlayer = _battingTeamPlayers[dismissedBatsmanIndex];
        _playerStats.putIfAbsent(
            dismissedPlayer.id,
            () => {
                  'runs': 0,
                  'balls': 0,
                  'fours': 0,
                  'sixes': 0,
                  'sr': '0.0',
                  'out': false,
                });
        _playerStats[dismissedPlayer.id]!['out'] = true;
        _partnershipRuns = 0;
        _partnershipBalls = 0;
        _bringNextBatterIn(dismissedBatsmanIndex);
      } else if (!isWicket && runDelta.isOdd) {
        _switchStrike();
      }

      if (isLegal && _legalBallsBowled % 6 == 0) {
        _switchStrike();
        _bowlerIndex = -1;
        _currentOverBalls.clear();
      } else if (_currentOverBalls.length > 8) {
        _currentOverBalls.removeAt(0);
      }

      if (_wickets > _maxWickets) {
        _wickets = _maxWickets;
      }

      if (isWicket && _wickets >= _maxWickets) {
        _currentOverBalls.clear();
      }

      if (_strikerIndex >= _battingTeamPlayers.length) {
        _strikerIndex = 0;
      }
      if (_nonStrikerIndex >= _battingTeamPlayers.length) {
        _nonStrikerIndex = _battingTeamPlayers.length > 1 ? 1 : 0;
      }
      if (_strikerIndex == _nonStrikerIndex && _battingTeamPlayers.length > 1) {
        final fallback = _strikerIndex == 0 ? 1 : 0;
        if (fallback < _battingTeamPlayers.length) {
          _nonStrikerIndex = fallback;
        }
      }
    });

    _syncScore();
    if (isLegal &&
        _legalBallsBowled % 6 == 0 &&
        _wickets < _maxWickets &&
        (_oversLimit == 0 || _legalBallsBowled < (_oversLimit * 6))) {
      _showBowlerSelectionDialog(force: true);
    }
    _checkAutomaticTransitions();
  }

  void _startSecondInnings() {
    if (_teamA == null || _teamB == null || _battingTeamName == null) return;
    setState(() {
      // Save first innings total
      _firstInningsRuns = _runs;
      debugPrint('First innings run saved: $_firstInningsRuns');

      _innings = 2;
      // Swap batting side
      _battingTeamName = _battingTeamName == _teamA ? _teamB : _teamA;
      // Swap team IDs
      final temp = _battingTeamId;
      _battingTeamId = _bowlingTeamId;
      _bowlingTeamId = temp;
      debugPrint(
          'Second innings setup: batting=$_battingTeamId, bowling=$_bowlingTeamId');

      // Reset scoring state
      _runs = 0;
      _wickets = 0;
      _overs = 0.0;
      _legalBallsBowled = 0;
      _target = _firstInningsRuns + 1;
      _recentBalls.clear();
      _currentOverBalls.clear();
      _history.clear();
      _strikerIndex = 0;
      _nonStrikerIndex = 1;
      _bowlerIndex = -1;
      _partnershipRuns = 0;
      _partnershipBalls = 0;

      // Clear player stats for second innings teams
      _playerStats.clear();
      _playersLoaded = false;
    });
    _fetchBattingTeamPlayers().then((_) {
      // if fetch returns empty, UI will show message
    });
    _syncScore();
  }

  void _handleInningsOrMatchComplete() {
    if (_isTransitionInProgress) return;
    _isTransitionInProgress = true;
    if (_innings == 1) {
      // Ask user to start second innings.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppPalette.bgSecondary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'End 1st Innings?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Overs limit reached. Start scoring for the second team?',
            style: TextStyle(color: AppPalette.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isTransitionInProgress = false;
                Navigator.pop(context);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppPalette.textMuted),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _startSecondInnings();
                _isTransitionInProgress = false;
              },
              style: FilledButton.styleFrom(backgroundColor: AppPalette.accent),
              child: const Text(
                'START 2ND INNINGS',
                style: TextStyle(
                    color: AppPalette.bgSecondary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      // Second innings also finished -> mark match complete and go to results.
      if (_match == null) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppPalette.accent),
        ),
      );
      MatchService.completeMatch(_match!.id).then((_) {
        if (!mounted) return;
        _isTransitionInProgress = false;
        Navigator.pop(context); // close loader
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.results,
          (route) => false,
        );
      }).catchError((_) {
        if (!mounted) return;
        _isTransitionInProgress = false;
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark match as completed'),
          ),
        );
      });
    }
  }

  void _addRun(int run, {bool isExtra = false, String? label}) {
    final ballLabel = label ?? run.toString();
    final countsAsLegalBall = !isExtra;

    _applyBall(
      label: ballLabel,
      runDelta: run,
      isLegal: countsAsLegalBall,
    );
    HapticFeedback.lightImpact();
  }

  void _addExtra(String type) {
    final isLegal = type == 'LB' || type == 'B';
    _applyBall(
      label: type,
      runDelta: 1,
      isLegal: isLegal,
    );
    HapticFeedback.selectionClick();
  }

  void _onWicket() {
    _showWicketPopup();
  }

  void _showWicketPopup() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withAlpha((0.95 * 255).toInt()),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: AppPalette.live.withAlpha((0.3 * 255).toInt())),
              boxShadow: [
                BoxShadow(
                    color: AppPalette.live.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 40,
                    spreadRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.live.withAlpha((0.1 * 255).toInt())),
                  child: const Icon(Icons.gavel_rounded,
                      color: AppPalette.live, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('WICKET!',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                const Text('Select Wicket Type',
                    style:
                        TextStyle(color: AppPalette.textMuted, fontSize: 14)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _WicketTypeButton(
                        label: 'Bowled', onTap: () => _confirmWicket('Bowled')),
                    _WicketTypeButton(
                        label: 'Caught', onTap: () => _confirmWicket('Caught')),
                    _WicketTypeButton(
                        label: 'LBW', onTap: () => _confirmWicket('LBW')),
                    _WicketTypeButton(
                        label: 'Run Out',
                        onTap: () => _confirmWicket('Run Out')),
                    _WicketTypeButton(
                        label: 'Stumped',
                        onTap: () => _confirmWicket('Stumped')),
                    _WicketTypeButton(
                        label: 'Hit Wicket',
                        onTap: () => _confirmWicket('Hit Wicket')),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL',
                      style: TextStyle(
                          color: AppPalette.textMuted,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmWicket(String type) {
    Navigator.pop(context); // Close type selection

    // Step 2: Select which batsman is out
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withAlpha((0.95 * 255).toInt()),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: AppPalette.accent.withAlpha((0.2 * 255).toInt())),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('WHO IS OUT?',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(height: 24),
                if (_fetchError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text('Error loading players',
                            style: const TextStyle(color: Colors.red)),
                        Text(_fetchError!,
                            style: const TextStyle(
                                color: AppPalette.textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                else if (_battingTeamPlayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No players found',
                      style: TextStyle(color: AppPalette.textMuted),
                    ),
                  )
                else
                  ...[
                    if (_strikerIndex >= 0 &&
                        _strikerIndex < _battingTeamPlayers.length)
                      MapEntry(
                          _strikerIndex, _battingTeamPlayers[_strikerIndex]),
                    if (_nonStrikerIndex >= 0 &&
                        _nonStrikerIndex < _battingTeamPlayers.length &&
                        _nonStrikerIndex != _strikerIndex)
                      MapEntry(_nonStrikerIndex,
                          _battingTeamPlayers[_nonStrikerIndex]),
                  ].asMap().entries.map((entry) {
                    final index = entry.value.key;
                    final player = entry.value.value;
                    final initials = player.name
                        .split(' ')
                        .map((word) =>
                            word.isNotEmpty ? word[0].toUpperCase() : '')
                        .join();
                    final isStriker = index == _strikerIndex;
                    final isLast = entry.key == 1;

                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isStriker
                                ? AppPalette.accent
                                : AppPalette.textMuted,
                            child: Text(
                              initials,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${player.name} ${isStriker ? '(Striker)' : '(Non-Striker)'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () => _finalizeWicket(type, index),
                        ),
                        if (!isLast)
                          const Divider(color: AppPalette.cardStroke),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _finalizeWicket(String type, int dismissedIndex) {
    Navigator.pop(context); // Close player selection

    if (dismissedIndex < 0 || dismissedIndex >= _battingTeamPlayers.length) {
      return;
    }

    final dismissedPlayer = _battingTeamPlayers[dismissedIndex];
    final creditToBowler = type != 'Run Out';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WICKET! - $type (${dismissedPlayer.name})',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppPalette.live,
        duration: const Duration(seconds: 1),
      ),
    );

    _applyBall(
      label: 'W',
      runDelta: 0,
      isLegal: true,
      isWicket: true,
      dismissedBatsmanIndex: dismissedIndex,
      creditWicketToBowler: creditToBowler,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration:
                const BoxDecoration(gradient: AppPalette.surfaceGradient),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const SizedBox(height: 16),
                        _buildScoreCard(),
                        const SizedBox(height: 24),
                        _buildBatsmanStats(),
                        const SizedBox(height: 16),
                        _buildBowlerStats(),
                        const SizedBox(height: 24),
                        _buildRecentBalls(),
                      ],
                    ),
                  ),
                  _buildKeypad(),
                ],
              ),
            ),
          ),
          if (_isBowlerPickerVisible) _buildBowlerPickerOverlay(),
        ],
      ),
    );
  }

  Widget _buildBowlerPickerOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: GestureDetector(
          onTap: _hideBowlerSelectionDialog,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: AppPalette.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.cardStroke),
                ),
                constraints: const BoxConstraints(maxHeight: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Bowler',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: ListView.separated(
                        itemCount: _bowlingTeamPlayers.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: AppPalette.cardStroke),
                        itemBuilder: (_, index) {
                          final player = _bowlingTeamPlayers[index];
                          return ListTile(
                            title: Text(
                              player.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () => _selectBowler(index),
                          );
                        },
                      ),
                    ),
                    if (!_bowlerPickerForce)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _hideBowlerSelectionDialog,
                          child: const Text('CANCEL'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final teamA = _teamA ?? _match?.teamAId ?? 'Team A';
    final teamB = _teamB ?? _match?.teamBId ?? 'Team B';

    // Primary source of truth for who is currently batting.
    final battingTeam = _battingTeamName ??
        (_decision == 'BAT'
            ? _tossWinner
            : (_tossWinner == teamA ? teamB : teamA)) ??
        teamA;

    final inningsLabel = _innings == 1 ? '1st Innings' : '2nd Innings';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xCC111721),
        border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppPalette.textPrimary, size: 20),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$teamA vs $teamB',
                  style: const TextStyle(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  '$battingTeam Batting • $inningsLabel',
                  style: const TextStyle(
                      color: AppPalette.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppPalette.accent.withAlpha((0.2 * 255).toInt())),
        gradient: LinearGradient(
          colors: [
            AppPalette.accent.withAlpha((0.1 * 255).toInt()),
            const Color(0xFF1E293B).withAlpha((0.1 * 255).toInt()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_runs',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1),
                        ),
                        TextSpan(
                          text: '-$_wickets',
                          style: TextStyle(
                              color:
                                  Colors.white.withAlpha((0.6 * 255).toInt()),
                              fontSize: 32,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _oversLimit > 0
                        ? 'Overs: ${_oversStringFromBalls(_legalBallsBowled)} / $_oversLimit'
                        : 'Overs: ${_oversStringFromBalls(_legalBallsBowled)}',
                    style: TextStyle(
                      color:
                          AppPalette.textMuted.withAlpha((0.8 * 255).toInt()),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('CRR',
                      style:
                          TextStyle(color: AppPalette.textMuted, fontSize: 12)),
                  Text(
                    _calculateCurrentRunRate().toStringAsFixed(2),
                    style: const TextStyle(
                        color: AppPalette.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatsmanStats() {
    // Show error if fetch failed
    if (_fetchError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load players',
                style: TextStyle(color: AppPalette.textMuted)),
            const SizedBox(height: 8),
            Text(_fetchError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (_battingTeamId != null) _fetchBattingTeamPlayers();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show loading while players are being fetched
    if (!_playersLoaded) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardStroke),
        ),
        child: const Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppPalette.accent),
            ),
          ),
        ),
      );
    }

    if (_battingTeamPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No players available',
              style: TextStyle(color: AppPalette.textMuted),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (_battingTeamId != null) _fetchBattingTeamPlayers();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final striker =
        _strikerIndex >= 0 && _strikerIndex < _battingTeamPlayers.length
            ? _battingTeamPlayers[_strikerIndex]
            : null;
    final nonStriker =
        _nonStrikerIndex >= 0 && _nonStrikerIndex < _battingTeamPlayers.length
            ? _battingTeamPlayers[_nonStrikerIndex]
            : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.cardStroke),
      ),
      child: Column(
        children: [
          if (striker != null)
            _StatsRow(
              name: '${striker.name}*',
              runs: (_playerStats[striker.id]?['runs'] ?? 0).toString(),
              balls: (_playerStats[striker.id]?['balls'] ?? 0).toString(),
              sr: (_playerStats[striker.id]?['sr'] ?? '0.0').toString(),
              isStriker: true,
            ),
          if (nonStriker != null) ...[
            const Divider(color: AppPalette.cardStroke, height: 24),
            _StatsRow(
              name: nonStriker.name,
              runs: (_playerStats[nonStriker.id]?['runs'] ?? 0).toString(),
              balls: (_playerStats[nonStriker.id]?['balls'] ?? 0).toString(),
              sr: (_playerStats[nonStriker.id]?['sr'] ?? '0.0').toString(),
              isStriker: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBowlerStats() {
    // Show error if fetch failed
    if (_fetchError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load bowlers',
                style: TextStyle(color: AppPalette.textMuted)),
            const SizedBox(height: 8),
            Text(_fetchError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (_bowlingTeamId != null) _fetchBattingTeamPlayers();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show loading while players are being fetched
    if (!_playersLoaded) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardStroke),
        ),
        child: const Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppPalette.accent),
            ),
          ),
        ),
      );
    }

    if (_bowlingTeamPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No bowlers available',
              style: TextStyle(color: AppPalette.textMuted),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (_bowlingTeamId != null) _fetchBattingTeamPlayers();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final bowler =
        _bowlerIndex >= 0 && _bowlerIndex < _bowlingTeamPlayers.length
            ? _bowlingTeamPlayers[_bowlerIndex]
            : null;

    if (bowler == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardStroke),
        ),
        child: Center(
          child: FilledButton(
            onPressed: () => _showBowlerSelectionDialog(force: true),
            child: const Text('Select Bowler'),
          ),
        ),
      );
    }

    final bowlerStats = _playerStats[bowler.id] ?? {};
    final ballsBowled = (bowlerStats['balls_bowled'] ?? 0) as int;
    final overs = ballsBowled ~/ 6;
    final balls = ballsBowled % 6;
    final maidens = (bowlerStats['maidens'] ?? 0);
    final runs = (bowlerStats['runs'] ?? 0);
    final wickets = (bowlerStats['wickets'] ?? 0);
    final econ = ballsBowled > 0
        ? (runs / (ballsBowled / 6.0)).toStringAsFixed(2)
        : '0.0';

    final figures = '$overs.$balls-$maidens-$runs-$wickets';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bgSecondary.withAlpha((0.5 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.cardStroke),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showBowlerSelectionDialog(),
              child: const Text('Change Bowler'),
            ),
          ),
          _BowlerRow(name: bowler.name, figures: figures, econ: econ),
        ],
      ),
    );
  }

  Widget _buildRecentBalls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT BALLS',
            style: TextStyle(
                color: AppPalette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _recentBalls.map((b) => _BallCircle(label: b)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    final canScore =
        _bowlerIndex >= 0 && _bowlerIndex < _bowlingTeamPlayers.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppPalette.cardStroke)),
      ),
      child: Column(
        children: [
          if (!canScore)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Select bowler to start scoring',
                style: TextStyle(color: AppPalette.textMuted),
              ),
            ),
          IgnorePointer(
            ignoring: !canScore,
            child: Opacity(
              opacity: canScore ? 1.0 : 0.45,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _KeyButton(label: '0', onTap: () => _addRun(0)),
                      _KeyButton(label: '1', onTap: () => _addRun(1)),
                      _KeyButton(label: '2', onTap: () => _addRun(2)),
                      _KeyButton(label: '3', onTap: () => _addRun(3)),
                      _KeyButton(
                          label: '4',
                          onTap: () => _addRun(4),
                          isHighlight: true),
                      _KeyButton(
                          label: '6',
                          onTap: () => _addRun(6),
                          isHighlight: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _KeyButton(
                          label: 'WD',
                          onTap: () => _addExtra('WD'),
                          isSpecial: true),
                      _KeyButton(
                          label: 'NB',
                          onTap: () => _addExtra('NB'),
                          isSpecial: true),
                      _KeyButton(
                          label: 'LB',
                          onTap: () => _addExtra('LB'),
                          isSpecial: true),
                      _KeyButton(
                          label: 'B',
                          onTap: () => _addExtra('B'),
                          isSpecial: true),
                      _KeyButton(label: 'W', onTap: _onWicket, isAlert: true),
                      _KeyButton(
                          icon: Icons.undo, onTap: _undo, isSpecial: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow(
      {required this.name,
      required this.runs,
      required this.balls,
      required this.sr,
      required this.isStriker});
  final String name, runs, balls, sr;
  final bool isStriker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
                color: isStriker ? Colors.white : AppPalette.textMuted,
                fontWeight: isStriker ? FontWeight.bold : FontWeight.normal),
          ),
        ),
        _StatItem(label: 'R', value: runs),
        _StatItem(label: 'B', value: balls),
        _StatItem(label: 'SR', value: sr, width: 50),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.width = 30});
  final String label, value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppPalette.textMuted, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _BowlerRow extends StatelessWidget {
  const _BowlerRow(
      {required this.name, required this.figures, required this.econ});
  final String name, figures, econ;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(name, style: const TextStyle(color: Colors.white))),
        _StatItem(label: 'O-M-R-W', value: figures, width: 80),
        _StatItem(label: 'ECON', value: econ, width: 40),
      ],
    );
  }
}

class _BallCircle extends StatelessWidget {
  const _BallCircle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    bool isWicket = label == 'W';
    bool isBoundary = label == '4' || label == '6';

    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isWicket
            ? AppPalette.live.withAlpha((0.2 * 255).toInt())
            : (isBoundary
                ? AppPalette.accent.withAlpha((0.2 * 255).toInt())
                : AppPalette.bgSecondary),
        border: Border.all(
            color: isWicket
                ? AppPalette.live
                : (isBoundary ? AppPalette.accent : AppPalette.cardStroke)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isWicket
                ? AppPalette.live
                : (isBoundary ? AppPalette.accent : Colors.white),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton(
      {this.label,
      this.icon,
      required this.onTap,
      this.isHighlight = false,
      this.isSpecial = false,
      this.isAlert = false});
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isHighlight, isSpecial, isAlert;

  @override
  Widget build(BuildContext context) {
    Color bg = isAlert
        ? AppPalette.live
        : (isHighlight
            ? AppPalette.accent
            : (isSpecial ? const Color(0xFF1E293B) : const Color(0xFF334155)));
    Color fg = (isHighlight || isAlert) ? AppPalette.bgSecondary : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: fg, size: 20)
              : Text(label!,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
      ),
    );
  }
}

class _WicketTypeButton extends StatelessWidget {
  const _WicketTypeButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.cardStroke),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
