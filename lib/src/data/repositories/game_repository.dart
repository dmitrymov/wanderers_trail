import '../models/player_profile.dart';

abstract class GameRepository {
  Future<PlayerProfile> loadProfile({required String userId});
  Future<void> saveProfile(PlayerProfile profile);
}
