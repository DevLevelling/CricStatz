import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/models/match_stats.dart';
import 'package:cricstatz/models/player.dart';
import 'package:cricstatz/services/supabase_service.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class MatchService {
  static final Logger _logger = Logger();
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static Map<String, dynamic> _parseLiveScoreRow(Map<String, dynamic> data) {
    final summaryJson = data['summary'] as Map<String, dynamic>;
    final partnershipJson = data['partnership'] as Map<String, dynamic>;
    final batsmenJson = data['batsmen'] as List<dynamic>;
    final bowlerJson = data['bowler'] as Map<String, dynamic>;

    return {
      'summary': ScoreSummary.fromJson(summaryJson),
      'partnership': Partnership.fromJson(partnershipJson),
      'batsmen': batsmenJson
          .map((e) => BatsmanScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      'bowler': BowlerScore.fromJson(bowlerJson),
      'updated_at': data['updated_at'] as String?,
    };
  }

  static Future<Match> createMatch({
    required String teamAId,
    required String teamBId,
    String? venue,
    String? matchFormat,
    DateTime? matchDate,
    required int oversLimit,
    List<String>? teamASquad,
    List<String>? teamBSquad,
  }) async {
    final userId = SupabaseService.currentUser!.id;
    final data = await SupabaseService.client
        .from('matches')
        .insert({
          'team_a_id': teamAId,
          'team_b_id': teamBId,
          'venue': venue,
          'match_format': matchFormat,
          'match_date': matchDate?.toIso8601String(),
          'overs_limit': oversLimit,
          'status': 'upcoming',
          'created_by': userId,
          'team_a_squad': teamASquad,
          'team_b_squad': teamBSquad,
        })
        .select()
        .single();

    return Match.fromJson(data);
  }

  static Future<List<Match>> getUpcomingMatches() async {
    final data = await SupabaseService.client
        .from('matches')
        .select()
        .eq('status', 'upcoming')
        .order('created_at', ascending: false);

    final upcomingMatches =
        (data as List).map((e) => Match.fromJson(e)).toList();

    // Exclude any upcoming row that already has a live score record.
    final liveScoreRows =
        await SupabaseService.client.from('live_scores').select('match_id');
    final startedMatchIds = (liveScoreRows as List)
        .map((row) => (row as Map<String, dynamic>)['match_id']?.toString())
        .whereType<String>()
        .toSet();

    return upcomingMatches
        .where((match) => !startedMatchIds.contains(match.id))
        .toList();
  }

  static Future<List<Match>> getLiveMatches() async {
    final statusLiveRows = await SupabaseService.client
        .from('matches')
        .select()
        .eq('status', 'live');

    final statusLiveMatches =
        (statusLiveRows as List).map((e) => Match.fromJson(e)).toList();

    final liveScoreRows = await SupabaseService.client
        .from('live_scores')
        .select('match_id, updated_at')
        .order('updated_at', ascending: false);

    final matchIdsFromLiveScores = (liveScoreRows as List)
        .map((row) => (row as Map<String, dynamic>)['match_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (matchIdsFromLiveScores.isEmpty) {
      return statusLiveMatches.where((m) => m.status != 'completed').toList();
    }

    final liveScoreMatchesRows = await SupabaseService.client
        .from('matches')
        .select()
        .inFilter('id', matchIdsFromLiveScores.toList())
        .neq('status', 'completed');

    final liveScoreMatches =
        (liveScoreMatchesRows as List).map((e) => Match.fromJson(e)).toList();

    final merged = <String, Match>{};
    for (final match in statusLiveMatches) {
      if (match.status != 'completed') {
        merged[match.id] = match;
      }
    }
    for (final match in liveScoreMatches) {
      merged[match.id] = match;
    }

    final matches = merged.values.toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? a.matchDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? b.matchDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return matches;
  }

  static Future<List<Match>> getCompletedMatches() async {
    final rows = await SupabaseService.client
        .from('matches')
        .select()
        .eq('status', 'completed')
        .order('created_at', ascending: false);

    return (rows as List).map((e) => Match.fromJson(e)).toList();
  }

  static Future<Match> getMatchDetails(String matchId) async {
    final data = await SupabaseService.client
        .from('matches')
        .select()
        .eq('id', matchId)
        .single();
    return Match.fromJson(data);
  }

  static Future<Map<String, dynamic>> getLiveScore(String matchId) async {
    // Assumes a `live_scores` table with a row per match_id and nested
    // JSON columns: summary, partnership, batsmen (array), bowler.
    final data = await SupabaseService.client
        .from('live_scores')
        .select()
        .eq('match_id', matchId)
        .single();
    return _parseLiveScoreRow(data);
  }

  static Stream<Map<String, dynamic>?> streamLiveScore(String matchId) {
    return SupabaseService.client
        .from('live_scores')
        .stream(primaryKey: ['match_id'])
        .eq('match_id', matchId)
        .map((rows) {
          if (rows.isEmpty) return null;
          final row = rows.first;
          return _parseLiveScoreRow(row);
        });
  }

  static Future<List<Map<String, dynamic>>> getScoreboard(
      String matchId) async {
    // Assumes a `scoreboards` table with one row per match_id and an
    // `innings` JSON array column. Each innings object should match:
    // {
    //   "innings": "India 1st Innings",
    //   "total": "240/10 (50.0)",
    //   "batting": [ { ...BatsmanScore json... } ],
    //   "bowling": [ { ...BowlerScore json... } ]
    // }
    final data = await SupabaseService.client
        .from('scoreboards')
        .select('innings')
        .eq('match_id', matchId)
        .maybeSingle();

    if (data == null || data['innings'] == null) {
      return [];
    }

    final inningsList = data['innings'] as List<dynamic>;

    return inningsList.map<Map<String, dynamic>>((rawInnings) {
      final map = rawInnings as Map<String, dynamic>;
      final battingJson = map['batting'] as List<dynamic>? ?? [];
      final bowlingJson = map['bowling'] as List<dynamic>? ?? [];

      return {
        'innings': map['innings'] as String? ?? '',
        'total': map['total'] as String? ?? '',
        'batting': battingJson
            .map((e) => BatsmanScore.fromJson(e as Map<String, dynamic>))
            .toList(),
        'bowling': bowlingJson
            .map((e) => BowlerScore.fromJson(e as Map<String, dynamic>))
            .toList(),
      };
    }).toList();
  }

  static Future<Map<String, dynamic>> getMatchPlayers(String matchId) async {
    // Assumes a `match_players` table with JSON columns:
    // - playing_xi: array of { name, role, stat, badge }
    // - bench: array of { name, role }
    final data = await SupabaseService.client
        .from('match_players')
        .select('playing_xi, bench')
        .eq('match_id', matchId)
        .maybeSingle();

    if (data == null) {
      return {
        'playingXI': <Map<String, dynamic>>[],
        'bench': <Map<String, dynamic>>[],
      };
    }

    final playingXi = (data['playing_xi'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final bench = (data['bench'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return {
      'playingXI': playingXi,
      'bench': bench,
    };
  }

  static Future<Match?> getLatestLiveMatch() async {
    try {
      final data = await SupabaseService.client
          .from('matches')
          .select()
          .eq('status', 'live')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data != null) return Match.fromJson(data);
    } catch (_) {
      // Fallback when updated_at does not exist in schema.
    }

    final statusFallback = await SupabaseService.client
        .from('matches')
        .select()
        .eq('status', 'live')
        .order('match_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (statusFallback != null) return Match.fromJson(statusFallback);

    // Last-resort fallback: infer live match from latest live score row.
    final liveScoreRow = await SupabaseService.client
        .from('live_scores')
        .select('match_id, updated_at')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final matchId = liveScoreRow?['match_id']?.toString();
    if (matchId == null || matchId.isEmpty) return null;

    final matchRow = await SupabaseService.client
        .from('matches')
        .select()
        .eq('id', matchId)
        .neq('status', 'completed')
        .maybeSingle();

    if (matchRow == null) return null;
    return Match.fromJson(matchRow);
  }

  static DateTime _parseRowDate(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Stream<Match?> streamLatestLiveMatch() {
    return SupabaseService.client
        .from('live_scores')
        .stream(primaryKey: ['match_id']).asyncMap((rows) async {
      // Primary source of truth for "started" matches.
      if (rows.isNotEmpty) {
        final sortedRows = List<Map<String, dynamic>>.from(rows)
          ..sort((a, b) {
            final aUpdated = _parseRowDate(a, 'updated_at');
            final bUpdated = _parseRowDate(b, 'updated_at');
            return bUpdated.compareTo(aUpdated);
          });

        for (final row in sortedRows) {
          final matchId = row['match_id']?.toString();
          if (matchId == null || matchId.isEmpty) continue;

          final matchRow = await SupabaseService.client
              .from('matches')
              .select()
              .eq('id', matchId)
              .neq('status', 'completed')
              .maybeSingle();
          if (matchRow != null) {
            return Match.fromJson(matchRow);
          }
        }
      }

      // Fallback when no live score row exists yet.
      return getLatestLiveMatch();
    });
  }

  static Stream<List<Match>> streamLiveMatches() {
    return SupabaseService.client
        .from('matches')
        .stream(primaryKey: ['id']).asyncMap((_) => getLiveMatches());
  }

  static Future<void> updateMatchToss(
      String matchId, String winnerId, String decision) async {
    await SupabaseService.client.from('matches').update({
      'toss_winner': winnerId,
      'toss_decision': decision,
      'status': 'live',
    }).eq('id', matchId);
  }

  static Future<void> updateMatchSquads({
    required String matchId,
    required List<String> teamASquad,
    required List<String> teamBSquad,
  }) async {
    final response = await SupabaseService.client
        .from('matches')
        .update({
          'team_a_squad': teamASquad,
          'team_b_squad': teamBSquad,
        })
        .eq('id', matchId)
        .select('id, team_a_squad, team_b_squad')
        .maybeSingle();

    if (response == null) {
      throw Exception('Squad update returned no row for match $matchId');
    }

    final savedA =
        (response['team_a_squad'] as List<dynamic>? ?? <dynamic>[]).length;
    final savedB =
        (response['team_b_squad'] as List<dynamic>? ?? <dynamic>[]).length;
    if (savedA != teamASquad.length || savedB != teamBSquad.length) {
      throw Exception(
        'Squad update mismatch. expected: A=${teamASquad.length}, B=${teamBSquad.length} '
        'saved: A=$savedA, B=$savedB',
      );
    }
  }

  static Future<Map<String, List<Player>>> getMatchSquadPlayers(
      String matchId) async {
    final data = await SupabaseService.client
        .from('matches')
        .select('team_a_squad, team_b_squad')
        .eq('id', matchId)
        .maybeSingle();

    if (data == null) {
      return {
        'teamA': <Player>[],
        'teamB': <Player>[],
      };
    }

    final teamAIds = (data['team_a_squad'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .where((id) => id.isNotEmpty)
        .toList();
    final teamBIds = (data['team_b_squad'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .where((id) => id.isNotEmpty)
        .toList();

    final allIds = <String>{...teamAIds, ...teamBIds}.toList();
    if (allIds.isEmpty) {
      return {
        'teamA': <Player>[],
        'teamB': <Player>[],
      };
    }

    final profiles = await SupabaseService.client
        .from('profiles')
        .select('id, display_name, username, role')
        .inFilter('id', allIds);

    final profileMap = <String, Map<String, dynamic>>{};
    for (final raw in (profiles as List)) {
      final row = raw as Map<String, dynamic>;
      profileMap[row['id'].toString()] = row;
    }

    List<Player> mapToPlayers(List<String> ids) {
      return ids.map((id) {
        final profile = profileMap[id];
        final displayName = (profile?['display_name'] ?? '').toString().trim();
        final username = (profile?['username'] ?? '').toString().trim();
        final role = (profile?['role'] ?? 'Player').toString();
        final name = displayName.isNotEmpty
            ? displayName
            : (username.isNotEmpty ? username : 'Unknown Player');
        return Player(
          id: id,
          teamId: '',
          name: name,
          role: role,
        );
      }).toList();
    }

    return {
      'teamA': mapToPlayers(teamAIds),
      'teamB': mapToPlayers(teamBIds),
    };
  }

  static Future<void> completeMatch(String matchId) async {
    await SupabaseService.client
        .from('matches')
        .update({'status': 'completed'}).eq('id', matchId);
  }

  static Future<void> updateLiveScore({
    required String matchId,
    required ScoreSummary summary,
    required List<BatsmanScore> batsmen,
    required BowlerScore bowler,
    Partnership? partnership,
  }) async {
    // Keep match state aligned with scoring updates.
    await SupabaseService.client
        .from('matches')
        .update({'status': 'live'})
        .eq('id', matchId)
        .neq('status', 'completed');

    // Upsert live score record.
    final data = {
      'match_id': matchId,
      'summary': summary.toJson(),
      'batsmen': batsmen.map((e) => e.toJson()).toList(),
      'bowler': bowler.toJson(),
      'partnership': partnership?.toJson() ?? {'runs': '0', 'balls': '0'},
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SupabaseService.client
        .from('live_scores')
        .upsert(data, onConflict: 'match_id');
  }

  static Future<void> ensureMatchLive(String matchId) async {
    await SupabaseService.client
        .from('matches')
        .update({'status': 'live'})
        .eq('id', matchId)
        .neq('status', 'completed');
  }

  static Future<void> deleteMatch(String matchId) async {
    final impactedRows = await SupabaseService.client
        .from('player_stats')
        .select('user_id')
        .eq('match_id', matchId);

    final impactedUserIds = <String>{};
    for (final raw in (impactedRows as List)) {
      final row = raw as Map<String, dynamic>;
      final userId = row['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        impactedUserIds.add(userId);
      }
    }

    await SupabaseService.client
        .from('matches')
        .delete()
        .eq('id', matchId);

    for (final userId in impactedUserIds) {
      await _rebuildPlayerCareerStats(userId);
    }
  }

  /// Aggregate completed-match data into:
  /// 1) player_stats (per-match rows)
  /// 2) player_dismissals (dismissal tracking)
  /// 3) match_records (historical match summary)
  /// 4) player_career_stats (overall cached totals)
  static Future<void> aggregatePlayerStats(String matchId) async {
    try {
      final matchRow = await SupabaseService.client
          .from('matches')
          .select(
              'id, team_a_id, team_b_id, venue, match_format, match_date, status, toss_winner, toss_decision')
          .eq('id', matchId)
          .maybeSingle();

      if (matchRow == null) {
        _logger.w('No match found for $matchId');
        return;
      }

      final liveScore = await SupabaseService.client
          .from('live_scores')
          .select('summary, batsmen')
          .eq('match_id', matchId)
          .maybeSingle();

      if (liveScore == null) {
        _logger.w('No live score found for match $matchId');
        return;
      }

      final summaryData = liveScore['summary'];
      late Map<String, dynamic> summary;
      if (summaryData is String) {
        summary = jsonDecode(summaryData) as Map<String, dynamic>;
      } else if (summaryData is Map<String, dynamic>) {
        summary = summaryData;
      } else {
        _logger.w('Unexpected summary type: ${summaryData.runtimeType}');
        return;
      }

      final firstInnings = summary['first_innings'] as Map<String, dynamic>?;
      if (firstInnings == null) {
        _logger.w('No first_innings in summary for match $matchId');
        return;
      }

      final seasonYear = DateTime.tryParse(matchRow['match_date']?.toString() ?? '')?.year;
      final season = seasonYear?.toString();
      final format = matchRow['match_format']?.toString();

      final profiles =
          await SupabaseService.client.from('profiles').select('id, display_name');
      final nameToUserId = <String, String>{};
      for (final raw in (profiles as List)) {
        final row = raw as Map<String, dynamic>;
        final id = row['id']?.toString();
        final name = row['display_name']?.toString().trim();
        if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
          nameToUserId[name] = id;
        }
      }

      final statsToInsert = <Map<String, dynamic>>[];
      final dismissalsToInsert = <Map<String, dynamic>>[];
      final affectedUserIds = <String>{};

      void addBattingRows(List<dynamic>? batsmen, int inningsNumber) {
        if (batsmen == null) return;
        for (final batter in batsmen) {
          if (batter is! Map<String, dynamic>) continue;
          final name = batter['name']?.toString();
          if (name == null || name.isEmpty) continue;
          final userId = nameToUserId[name];
          if (userId == null) {
            _logger.w('Player "$name" not found in profiles');
            continue;
          }

          final runs = _toInt(batter['runs']);
          final balls = _toInt(batter['balls']);
          final fours = _toInt(batter['fours']);
          final sixes = _toInt(batter['sixes']);
          final dismissal = batter['dismissal']?.toString();

          statsToInsert.add({
            'match_id': matchId,
            'user_id': userId,
            'player_name': name,
            'runs_scored': runs,
            'balls_faced': balls,
            'fours': fours,
            'sixes': sixes,
            'batting_sr': balls > 0 ? ((runs / balls) * 100).toStringAsFixed(2) : '0.00',
            'batting_avg': runs.toString(),
            'dismissal_mode': dismissal,
            'innings_number': inningsNumber,
            if (season != null) 'season': season,
            if (format != null) 'format': format,
          });

          if (!_isNotOutDismissal(dismissal)) {
            dismissalsToInsert.add({
              'match_id': matchId,
              'user_id': userId,
              'how_out': dismissal,
              'runs_at_dismissal': runs,
              'balls_faced': balls,
              'innings_number': inningsNumber,
            });
          }

          affectedUserIds.add(userId);
        }
      }

      void addBowlingRows(List<dynamic>? bowlers, int inningsNumber) {
        if (bowlers == null) return;
        for (final bowler in bowlers) {
          if (bowler is! Map<String, dynamic>) continue;
          final name = bowler['name']?.toString();
          if (name == null || name.isEmpty) continue;
          final userId = nameToUserId[name];
          if (userId == null) {
            _logger.w('Bowler "$name" not found in profiles');
            continue;
          }

          final runsConceded = _toInt(bowler['runs']);
          final ballsBowled = _parseOvers(bowler['overs']?.toString() ?? '0');
          final wickets = _toInt(bowler['wickets']);
          final maidens = _toInt(bowler['maidens']);

          statsToInsert.add({
            'match_id': matchId,
            'user_id': userId,
            'player_name': name,
            'runs_conceded': runsConceded,
            'balls_bowled': ballsBowled,
            'wickets': wickets,
            'maidens': maidens,
            'economy': ballsBowled > 0
                ? (runsConceded / (ballsBowled / 6.0)).toStringAsFixed(2)
                : '0.00',
            'innings_number': inningsNumber,
            if (season != null) 'season': season,
            if (format != null) 'format': format,
          });

          affectedUserIds.add(userId);
        }
      }

      addBattingRows(firstInnings['batsmen'] as List<dynamic>?, 1);
      addBowlingRows(firstInnings['bowler'] as List<dynamic>?, 1);
      addBattingRows(liveScore['batsmen'] as List<dynamic>?, 2);
      addBowlingRows(summary['all_bowlers'] as List<dynamic>?, 2);

      // Keep operation idempotent for retries/re-opens of result screen.
      await SupabaseService.client
          .from('player_stats')
          .delete()
          .eq('match_id', matchId);
      await SupabaseService.client
          .from('player_dismissals')
          .delete()
          .eq('match_id', matchId);

      if (statsToInsert.isNotEmpty) {
        await SupabaseService.client.from('player_stats').insert(statsToInsert);
      }
      if (dismissalsToInsert.isNotEmpty) {
        await SupabaseService.client.from('player_dismissals').insert(dismissalsToInsert);
      }

      try {
        await _upsertMatchRecord(matchRow, summary, firstInnings, matchId);
      } catch (e, stackTrace) {
        // Keep career updates running even if match record write fails.
        _logger.e('Failed to upsert match record for $matchId: $e',
            error: e, stackTrace: stackTrace);
      }

      for (final userId in affectedUserIds) {
        await _rebuildPlayerCareerStats(userId);
      }

      _logger.i(
          'Aggregated match $matchId: ${statsToInsert.length} player_stats rows, ${dismissalsToInsert.length} dismissals, ${affectedUserIds.length} career updates');
    } catch (e, stackTrace) {
      _logger.e('Error aggregating player stats for match $matchId: $e', error: e, stackTrace: stackTrace);
      // Don't throw - stats aggregation is non-critical
    }
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _isNotOutDismissal(String? dismissal) {
    if (dismissal == null || dismissal.trim().isEmpty) return true;
    final normalized = dismissal.trim().toLowerCase();
    return normalized.contains('not out') || normalized.contains('batting');
  }

  static Future<void> _upsertMatchRecord(
    Map<String, dynamic> matchRow,
    Map<String, dynamic> summary,
    Map<String, dynamic> firstInnings,
    String matchId,
  ) async {
    final teamAId = await _resolveTeamId(matchRow['team_a_id']?.toString());
    final teamBId = await _resolveTeamId(matchRow['team_b_id']?.toString());
    if (teamAId == null || teamBId == null) return;

    final firstRuns = _toInt(firstInnings['runs']);
    final firstWickets = _toInt(firstInnings['wickets']);
    final firstOvers = firstInnings['overs']?.toString();

    final secondRuns = _toInt(summary['runs']);
    final secondWickets = _toInt(summary['wickets']);
    final secondOvers = summary['overs']?.toString();

    final tossWinnerId = await _resolveTeamId(matchRow['toss_winner']?.toString());
    final tossDecision = matchRow['toss_decision']?.toString();

    String? firstBattingTeamId;
    if (tossWinnerId != null && tossDecision != null) {
      if (tossDecision == 'bat') {
        firstBattingTeamId = tossWinnerId;
      } else if (tossDecision == 'bowl') {
        firstBattingTeamId = tossWinnerId == teamAId ? teamBId : teamAId;
      }
    }

    final resolvedFirstBattingTeamId = firstBattingTeamId ?? teamAId;
    final secondBattingTeamId = resolvedFirstBattingTeamId == teamAId ? teamBId : teamAId;

    String? winningTeamId;
    String? marginType;
    int? marginValue;
    if (secondRuns > firstRuns) {
      winningTeamId = secondBattingTeamId;
      marginType = 'wickets';
      final squadSize = _toInt(summary['squad_size']);
      final maxWickets = squadSize > 1 ? squadSize - 1 : 10;
      marginValue = (maxWickets - secondWickets).clamp(0, maxWickets);
    } else if (firstRuns > secondRuns) {
      winningTeamId = resolvedFirstBattingTeamId;
      marginType = 'runs';
      marginValue = firstRuns - secondRuns;
    }

    final teamARuns = resolvedFirstBattingTeamId == teamAId ? firstRuns : secondRuns;
    final teamAWickets = resolvedFirstBattingTeamId == teamAId ? firstWickets : secondWickets;
    final teamAOvers = resolvedFirstBattingTeamId == teamAId ? firstOvers : secondOvers;
    final teamBRuns = resolvedFirstBattingTeamId == teamBId ? firstRuns : secondRuns;
    final teamBWickets = resolvedFirstBattingTeamId == teamBId ? firstWickets : secondWickets;
    final teamBOvers = resolvedFirstBattingTeamId == teamBId ? firstOvers : secondOvers;

    final payload = {
      'match_id': matchId,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'format': matchRow['match_format']?.toString() ?? 'T20',
      'venue': matchRow['venue']?.toString(),
        'match_date': matchRow['match_date'] ?? DateTime.now().toIso8601String(),
      'status': (matchRow['status']?.toString() ?? 'completed') == 'completed'
          ? 'completed'
          : 'no_result',
      'winning_team_id': winningTeamId,
      'margin_type': marginType,
      'margin_value': marginValue,
      'team_a_runs': teamARuns,
      'team_a_wickets': teamAWickets,
      'team_a_overs': teamAOvers,
      'team_b_runs': teamBRuns,
      'team_b_wickets': teamBWickets,
      'team_b_overs': teamBOvers,
      'toss_winner_id': tossWinnerId,
      'toss_decision': tossDecision,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SupabaseService.client
        .from('match_records')
        .upsert(payload, onConflict: 'match_id');
  }

  static Future<String?> _resolveTeamId(String? teamRef) async {
    if (teamRef == null) return null;
    final normalized = teamRef.trim();
    if (normalized.isEmpty) return null;

    if (_uuidPattern.hasMatch(normalized)) {
      return normalized;
    }

    try {
      final byName = await SupabaseService.client
          .from('teams')
          .select('id')
          .ilike('name', normalized)
          .limit(1)
          .maybeSingle();
      if (byName != null && byName['id'] != null) {
        return byName['id'].toString();
      }
    } catch (_) {}

    try {
      final byCode = await SupabaseService.client
          .from('teams')
          .select('id')
          .ilike('short_code', normalized)
          .limit(1)
          .maybeSingle();
      if (byCode != null && byCode['id'] != null) {
        return byCode['id'].toString();
      }
    } catch (_) {}

    return null;
  }

  static Future<void> _rebuildPlayerCareerStats(String userId) async {
    final rows = await SupabaseService.client
        .from('player_stats')
        .select(
        'match_id, runs_scored, balls_faced, fours, sixes, dismissal_mode, runs_conceded, balls_bowled, wickets')
        .eq('user_id', userId);

    final statsRows = (rows as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    if (statsRows.isEmpty) {
      await SupabaseService.client
          .from('player_career_stats')
          .delete()
          .eq('user_id', userId);
      return;
    }

    final matchIds = <String>{};
    final battingMatchIds = <String>{};
    final bowlingMatchIds = <String>{};

    int innings = 0;
    int notOuts = 0;
    int runsScored = 0;
    int ballsFaced = 0;
    int fours = 0;
    int sixes = 0;
    int highestScore = 0;

    int bowlingInnings = 0;
    int runsConceded = 0;
    int ballsBowled = 0;
    int wickets = 0;
    int bestWickets = 0;
    int bestRunsConceded = 999999;

    for (final row in statsRows) {
      final matchId = row['match_id']?.toString();
      if (matchId != null && matchId.isNotEmpty) {
        matchIds.add(matchId);
      }

      final rowRuns = _toInt(row['runs_scored']);
      final rowBalls = _toInt(row['balls_faced']);
      final rowFours = _toInt(row['fours']);
      final rowSixes = _toInt(row['sixes']);

      if (rowRuns > 0 || rowBalls > 0 || rowFours > 0 || rowSixes > 0) {
        innings += 1;
        runsScored += rowRuns;
        ballsFaced += rowBalls;
        fours += rowFours;
        sixes += rowSixes;
        if (rowRuns > highestScore) {
          highestScore = rowRuns;
        }
        if (!_isNotOutDismissal(row['dismissal_mode']?.toString())) {
          // dismissed inning
        } else {
          notOuts += 1;
        }
        if (matchId != null && matchId.isNotEmpty) {
          battingMatchIds.add(matchId);
        }
      }

      final rowRunsConceded = _toInt(row['runs_conceded']);
      final rowBallsBowled = _toInt(row['balls_bowled']);
      final rowWickets = _toInt(row['wickets']);
      if (rowRunsConceded > 0 || rowBallsBowled > 0 || rowWickets > 0) {
        bowlingInnings += 1;
        runsConceded += rowRunsConceded;
        ballsBowled += rowBallsBowled;
        wickets += rowWickets;
        if (rowWickets > bestWickets ||
            (rowWickets == bestWickets && rowRunsConceded < bestRunsConceded)) {
          bestWickets = rowWickets;
          bestRunsConceded = rowRunsConceded;
        }
        if (matchId != null && matchId.isNotEmpty) {
          bowlingMatchIds.add(matchId);
        }
      }
    }

    final outs = (innings - notOuts).clamp(0, innings);
    final battingAvg = outs > 0 ? (runsScored / outs) : runsScored.toDouble();
    final strikeRate = ballsFaced > 0 ? ((runsScored / ballsFaced) * 100) : 0.0;
    final bowlingAvg = wickets > 0 ? (runsConceded / wickets) : 0.0;
    final economy = ballsBowled > 0 ? (runsConceded / (ballsBowled / 6.0)) : 0.0;

    final payload = {
      'user_id': userId,
      'matches_played': matchIds.length,
      'innings': innings,
      'runs_scored': runsScored,
      'balls_faced': ballsFaced,
      'highest_score': highestScore,
      'fours': fours,
      'sixes': sixes,
      'batting_avg': battingAvg.toStringAsFixed(2),
      'strike_rate': strikeRate.toStringAsFixed(2),
      'not_outs': notOuts,
      'bowling_matches': bowlingMatchIds.length,
      'bowling_innings': bowlingInnings,
      'runs_conceded': runsConceded,
      'balls_bowled': ballsBowled,
      'wickets': wickets,
      'best_figures': '$bestWickets/$bestRunsConceded',
      'bowling_avg': bowlingAvg.toStringAsFixed(2),
      'economy': economy.toStringAsFixed(2),
      'last_updated': DateTime.now().toIso8601String(),
    };

    await SupabaseService.client
        .from('player_career_stats')
        .upsert(payload, onConflict: 'user_id');
  }

  /// Helper: Convert overs format (e.g., "2.0", "1.3") to total balls
  static int _parseOvers(String oversStr) {
    try {
      final parts = oversStr.split('.');
      if (parts.length == 2) {
        final overs = int.tryParse(parts[0]) ?? 0;
        final balls = int.tryParse(parts[1]) ?? 0;
        return (overs * 6) + balls;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
