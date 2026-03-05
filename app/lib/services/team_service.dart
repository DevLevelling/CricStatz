import 'package:cricstatz/models/player.dart';
import 'package:cricstatz/models/profile.dart';
import 'package:cricstatz/models/team.dart';
import 'package:cricstatz/models/team_member.dart';
import 'package:cricstatz/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

class TeamService {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static Future<Team> createTeam({
    required String name,
    required String shortCode,
  }) async {
    final userId = SupabaseService.currentUser!.id;
    final data = await SupabaseService.client.from('teams').insert({
      'name': name,
      'short_code': shortCode,
      'created_by': userId,
    }).select().single();

    return Team.fromJson(data);
  }

  static Future<List<Team>> getMyTeams() async {
    final userId = SupabaseService.currentUser!.id;

    // Teams where user is creator
    final createdTeams = await SupabaseService.client
        .from('teams')
        .select()
        .eq('created_by', userId);

    // Teams where user is a member
    final memberTeamIds = await SupabaseService.client
        .from('team_members')
        .select('team_id')
        .eq('profile_id', userId);

    final memberIds =
        (memberTeamIds as List).map((e) => e['team_id'] as String).toList();

    List<Team> teams =
        (createdTeams as List).map((e) => Team.fromJson(e)).toList();

    if (memberIds.isNotEmpty) {
      final memberTeams = await SupabaseService.client
          .from('teams')
          .select()
          .inFilter('id', memberIds);

      final memberTeamList =
          (memberTeams as List).map((e) => Team.fromJson(e)).toList();

      // Avoid duplicates (user could be creator AND member)
      final existingIds = teams.map((t) => t.id).toSet();
      for (final team in memberTeamList) {
        if (!existingIds.contains(team.id)) {
          teams.add(team);
        }
      }
    }

    return teams;
  }

  static Future<void> addMember({
    required String teamId,
    required String profileId,
  }) async {
    await SupabaseService.client.from('team_members').insert({
      'team_id': teamId,
      'profile_id': profileId,
    });
  }

  static Future<void> removeMember({
    required String teamId,
    required String profileId,
  }) async {
    await SupabaseService.client
        .from('team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('profile_id', profileId);
  }

  static Future<List<Profile>> getTeamMembers(String teamId) async {
    final data = await SupabaseService.client
        .from('team_members')
        .select('profile_id, profiles(*)')
        .eq('team_id', teamId);

    return (data as List)
        .map((e) => Profile.fromJson(e['profiles'] as Map<String, dynamic>))
        .toList();
  }

  static Future<List<TeamMember>> getTeamMemberRecords(String teamId) async {
    final data = await SupabaseService.client
        .from('team_members')
        .select()
        .eq('team_id', teamId);

    return (data as List).map((e) => TeamMember.fromJson(e)).toList();
  }

  static Future<void> deleteTeam(String teamId) async {
    await SupabaseService.client.from('teams').delete().eq('id', teamId);
  }

  static Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? shortCode,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (shortCode != null) updates['short_code'] = shortCode;

    final data = await SupabaseService.client
        .from('teams')
        .update(updates)
        .eq('id', teamId)
        .select()
        .single();

    return Team.fromJson(data);
  }

  static Future<List<Player>> getTeamPlayers(String teamId) async {
    var resolvedTeamId = teamId.trim();
    if (resolvedTeamId.isEmpty) return <Player>[];

    if (!_uuidPattern.hasMatch(resolvedTeamId)) {
      final mapped = await resolveTeamId(resolvedTeamId);
      if (mapped == null || mapped.isEmpty) {
        throw Exception('Unable to resolve team reference "$teamId" to a team ID');
      }
      resolvedTeamId = mapped;
    }

    dynamic data;
    try {
      data = await SupabaseService.client
          .from('players')
          .select('id,team_id,name,role')
          .eq('team_id', resolvedTeamId);
    } catch (e) {
      // `players` table may not exist in some deployments.
      debugPrint('Primary players query failed for team $resolvedTeamId: $e');
      return _getPlayersFromTeamMembers(resolvedTeamId);
    }

    // guard in case API returns a string with bad JSON
    if (data is String) {
      debugPrint('Warning: expected list but received string: $data');
      throw FormatException('Unexpected string response');
    }

    final rawRows = (data as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final players = <Player>[];
    for (final row in rawRows) {
      try {
        players.add(Player.fromJson(row));
      } catch (e) {
        // Skip malformed rows so one bad record does not block live scoring.
        debugPrint('Skipping malformed player row for team $resolvedTeamId: $e');
      }
    }

    return players;
  }

  static Future<List<Player>> _getPlayersFromTeamMembers(String teamId) async {
    final data = await SupabaseService.client
        .from('team_members')
        .select('profile_id, profiles(username, display_name, role)')
        .eq('team_id', teamId);

    final rows = (data as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final players = <Player>[];
    for (final row in rows) {
      final profileId = (row['profile_id'] ?? '').toString();
      final profile = row['profiles'] as Map<String, dynamic>?;
      final displayName = (profile?['display_name'] ?? '').toString().trim();
      final username = (profile?['username'] ?? '').toString().trim();
      final role = (profile?['role'] ?? 'Player').toString();
      final name = displayName.isNotEmpty
          ? displayName
          : (username.isNotEmpty ? username : 'Unknown Player');

      if (profileId.isEmpty) continue;

      players.add(
        Player(
          id: profileId,
          teamId: teamId,
          name: name,
          role: role,
        ),
      );
    }

    return players;
  }

  static Future<String?> resolveTeamId(String teamRef) async {
    if (teamRef.isEmpty) return null;
    final normalizedRef = teamRef.trim();

    if (_uuidPattern.hasMatch(normalizedRef)) {
      return normalizedRef;
    }

    try {
      final byName = await SupabaseService.client
          .from('teams')
          .select('id')
          .ilike('name', normalizedRef)
          .limit(1)
          .maybeSingle();
      if (byName != null && byName['id'] != null) {
        return byName['id'].toString();
      }
    } catch (_) {}

    try {
      final byShortCode = await SupabaseService.client
          .from('teams')
          .select('id')
          .ilike('short_code', normalizedRef)
          .limit(1)
          .maybeSingle();
      if (byShortCode != null && byShortCode['id'] != null) {
        return byShortCode['id'].toString();
      }
    } catch (_) {}

    return null;
  }
}
