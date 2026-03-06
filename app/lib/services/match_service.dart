import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/models/match_stats.dart';
import 'package:cricstatz/models/player.dart';
import 'package:cricstatz/services/supabase_service.dart';

class MatchService {
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
        .order('match_date', ascending: true);

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
        final aDate = a.matchDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.matchDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return matches;
  }

  static Future<List<Match>> getCompletedMatches() async {
    final rows = await SupabaseService.client
        .from('matches')
        .select()
        .eq('status', 'completed')
        .order('match_date', ascending: false);

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
}
