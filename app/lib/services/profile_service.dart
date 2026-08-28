import 'package:cricstatz/models/profile.dart';
import 'package:cricstatz/services/supabase_service.dart';

class ProfileService {
  static Future<Profile?> getProfile(String userId) async {
    final data = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  static Future<Profile> createProfile({
    required String userId,
    required String username,
    required String displayName,
    String? avatarUrl,
    required String role,
  }) async {
    String inviteCode;
    try {
      inviteCode = await SupabaseService.client
          .rpc('generate_invite_code') as String;
    } catch (_) {
      // Fallback: Generate a random 6-character uppercase alphanumeric code locally
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final radixStr = timestamp.toRadixString(36).toUpperCase();
      if (radixStr.length >= 6) {
        inviteCode = radixStr.substring(radixStr.length - 6);
      } else {
        inviteCode = radixStr.padLeft(6, 'A');
      }
    }

    final data = await SupabaseService.client.from('profiles').insert({
      'id': userId,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role,
      'invite_code': inviteCode,
    }).select().single();

    return Profile.fromJson(data);
  }

  static Future<Profile> updateProfile({
    required String userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? role,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (role != null) updates['role'] = role;

    final data = await SupabaseService.client
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return Profile.fromJson(data);
  }

  static Future<List<Profile>> searchByUsername(String query) async {
    final data = await SupabaseService.client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .limit(20);

    return (data as List).map((e) => Profile.fromJson(e)).toList();
  }

  static Future<List<Profile>> getAllProfiles() async {
    final data = await SupabaseService.client
        .from('profiles')
        .select()
        .order('display_name', ascending: true);
        
    return (data as List).map((e) => Profile.fromJson(e)).toList();
  }

  static Future<Profile?> findByInviteCode(String code) async {
    final data = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  static Future<bool> isUsernameAvailable(String username) async {
    final data = await SupabaseService.client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return data == null;
  }
}
