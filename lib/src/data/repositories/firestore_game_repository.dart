import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player_profile.dart';
import 'game_repository.dart';

class FirestoreGameRepository implements GameRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Future<PlayerProfile> loadProfile({required String userId}) async {
    final doc = await _db.collection('profiles').doc(userId).get();
    if (!doc.exists) {
      final profile = PlayerProfile.defaults(userId: userId);
      await saveProfile(profile);
      return profile;
    }
    return PlayerProfile.fromJson(doc.data()!);
  }

  @override
  Future<void> saveProfile(PlayerProfile profile) async {
    await _db.collection('profiles').doc(profile.userId).set(profile.toJson(), SetOptions(merge: true));
  }
}
