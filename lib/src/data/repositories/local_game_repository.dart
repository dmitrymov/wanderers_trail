import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_profile.dart';
import 'game_repository.dart';

class LocalGameRepository implements GameRepository {
  static const _kKey = 'wanderers_profile';

  @override
  Future<PlayerProfile> loadProfile({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kKey);
    if (str == null) {
      final profile = PlayerProfile.defaults(userId: userId);
      await saveProfile(profile);
      return profile;
    }
    final jsonMap = jsonDecode(str) as Map<String, dynamic>;
    return PlayerProfile.fromJson(jsonMap);
  }

  @override
  Future<void> saveProfile(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(profile.toJson()));
  }
}
