import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';
import '../data/models/item.dart';
import '../data/models/pet.dart';
import '../data/models/player_profile.dart';
import '../data/repositories/game_repository.dart';
import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  final GameRepository repo;
  GameState(this.repo);

  PlayerProfile? _profile;
  PlayerProfile get profile => _profile ?? _placeholder;

  static const _uuid = Uuid();
  Timer? _regenTimer;

  static const PlayerProfile _placeholder = PlayerProfile(
    userId: 'local',
    health: 100,
    stamina: 100,
    coins: 0,
    highScore: 0,
  );

  Future<void> init() async {
    // For now use a fixed local user id; later replace with auth uid.
    _profile = await repo.loadProfile(userId: 'local');
    _startRegen();
    notifyListeners();
  }

  void _startRegen() {
    _regenTimer?.cancel();
    _regenTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final petBonus = selectedPet?.staminaRegenBonus ?? 0.0;
      final regen = (2 * (1.0 + petBonus)).round();
      final s = (profile.stamina + regen).clamp(0, 100);
      _profile = profile.copyWith(stamina: s);
      notifyListeners();
      _persist();
    });
  }

  Pet? get selectedPet {
    final id = profile.selectedPetId;
    if (id == null) return null;
    return Pet.starterPets().firstWhere((p) => p.id == id, orElse: () => Pet.starterPets().first);
  }

  void selectPet(String petId) {
    _profile = profile.copyWith(selectedPetId: petId);
    notifyListeners();
    _persist();
  }

  void upgradeHealth() {
    _profile = profile.copyWith(health: (profile.health + 10).clamp(0, 200));
    notifyListeners();
    _persist();
  }

  void upgradeStamina() {
    _profile = profile.copyWith(stamina: (profile.stamina + 10).clamp(0, 200));
    notifyListeners();
    _persist();
  }

  void addCoins(int amount) {
    _profile = profile.copyWith(coins: max(0, profile.coins + amount));
    notifyListeners();
    _persist();
  }

  void updateHighScore(int score) {
    if (score > profile.highScore) {
      _profile = profile.copyWith(highScore: score);
      notifyListeners();
      _persist();
    }
  }

  // Equipment
  void equip(Item item) {
    switch (item.type) {
      case ItemType.weapon:
        _profile = profile.copyWith(weapon: item);
        break;
      case ItemType.armor:
        _profile = profile.copyWith(armor: item);
        break;
      case ItemType.ring:
        _profile = profile.copyWith(ring: item);
        break;
      case ItemType.boots:
        _profile = profile.copyWith(boots: item);
        break;
    }
    notifyListeners();
    _persist();
  }

  // Called when a monster is defeated; 40% chance to drop
  Item? maybeDrop({required int runScore}) {
    final roll = Random().nextDouble();
    if (roll < 0.4) {
      return Item.randomDrop(runScore: runScore, idGen: () => _uuid.v4());
    }
    return null;
  }

  Future<void> _persist() async {
    try {
      final p = profile;
      await repo.saveProfile(p);
    } catch (_) {
      // ignore for now
    }
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }
}
