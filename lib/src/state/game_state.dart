import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';
import '../data/models/item.dart';
import '../data/models/pet.dart';
import '../data/models/player_profile.dart';
import '../data/repositories/game_repository.dart';
import '../core/stats.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GameState extends ChangeNotifier {
  final GameRepository repo;
  GameState(this.repo);

  PlayerProfile? _profile;
  PlayerProfile get profile => _profile ?? _placeholder;

  static const _uuid = Uuid();
  Timer? _regenTimer;

  // Cached stats summary (recomputed when equipped item IDs change)
  StatsSummary? _statsCache;
  String? _cacheWeaponId, _cacheArmorId, _cacheRingId, _cacheBootsId;

  // Asset readiness flag
  bool _assetsReady = false;
  bool get assetsReady => _assetsReady;

  // Ephemeral combat state for tuning regen
  bool _inCombat = false;
  void setCombatActive(bool v) {
    _inCombat = v;
  }

  // Temporary blessing state
  DateTime? _blessUntil;
  double _blessAttackSpeedMul = 1.0; // >1 means faster
  double _blessStaminaRegenMul = 1.0; // >1 means more regen
  bool get isBlessActive => _blessUntil != null && DateTime.now().isBefore(_blessUntil!);
  double get attackSpeedMultiplier => isBlessActive ? _blessAttackSpeedMul : 1.0;
  double get staminaRegenMultiplier => isBlessActive ? _blessStaminaRegenMul : 1.0;
  int get blessRemainingSeconds {
    if (!isBlessActive) return 0;
    final secs = _blessUntil!.difference(DateTime.now()).inSeconds;
    return max(0, secs);
  }

  String applyTemporaryBlessing({Duration duration = const Duration(seconds: 30)}) {
    _blessUntil = DateTime.now().add(duration);
    _blessAttackSpeedMul = 1.15; // +15% attack speed
    _blessStaminaRegenMul = 1.5; // +50% regen
    notifyListeners();
    return 'Blessing of Vigor: +15% attack speed and +50% stamina regen for ${duration.inSeconds}s';
  }

  void clearBlessing() {
    _blessUntil = null;
    _blessAttackSpeedMul = 1.0;
    _blessStaminaRegenMul = 1.0;
    notifyListeners();
  }

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
    await _loadAssetManifest();
    _startRegen();
    notifyListeners();
  }

  void _startRegen() {
    _regenTimer?.cancel();
    _regenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final petBonus = selectedPet?.staminaRegenBonus ?? 0.0;
      // Base 2 stamina per second; +50% when not in combat
      final idleMul = _inCombat ? 1.0 : 1.5;
      final regen = (2 * (1.0 + petBonus) * idleMul * staminaRegenMultiplier).round();
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

  void resetForNewRun() {
    _profile = profile.copyWith(
      health: 100,
      stamina: 100,
      weapon: null, // cleared explicitly via sentinel-aware copyWith
      armor: null,
      ring: null,
      boots: null,
      savedStep: null,
    );
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  void prepareForCheckpointRun() {
    _profile = profile.copyWith(
      health: 100,
      stamina: 100,
      savedStep: null,
    );
    notifyListeners();
    _persist();
  }

  void saveRunProgress(int step) {
    _profile = profile.copyWith(savedStep: step);
    notifyListeners();
    _persist();
  }

  void clearRunProgress() {
    _profile = profile.copyWith(savedStep: null);
    notifyListeners();
    _persist();
  }

  // Leave battle: save progress at given step and reset equipment so the next
  // continue will start from the saved step with empty gear.
  void leaveBattleAndResetEquipment({required int saveStep}) {
    // Save current progress first
    _profile = profile.copyWith(savedStep: saveStep);
    // Reset equipment
    _profile = profile.copyWith(
      weapon: null,
      armor: null,
      ring: null,
      boots: null,
    );
    _invalidateStatsCache();
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

  // Try to consume stamina; returns false if not enough.
  bool tryConsumeStamina(int amount) {
    if (profile.stamina < amount) return false;
    final newStamina = max(0, profile.stamina - amount);
    _profile = profile.copyWith(stamina: newStamina);
    notifyListeners();
    _persist();
    return true;
  }

  void updateHighScore(int score) {
    if (score > profile.highScore) {
      _profile = profile.copyWith(highScore: score);
      notifyListeners();
      _persist();
    }
  }

  void loseHealth(int amount) {
    _profile = profile.copyWith(health: max(0, profile.health - amount));
    notifyListeners();
    _persist();
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
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  // Called when a monster is defeated; 90% chance to drop
  Item? maybeDrop({required int runScore}) {
    final roll = Random().nextDouble();
    if (roll < 0.9) {
      var it = Item.randomDrop(runScore: runScore, idGen: () => _uuid.v4());
      // If weapon and we have known assets, pick a matching one by rarity
      if (it.type == ItemType.weapon) {
        final img = _pickWeaponImage(it);
        if (img != null) {
          it = it.copyWith(imageAsset: img);
        }
      }
      return it;
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

  void _invalidateStatsCache() {
    _statsCache = null;
    _cacheWeaponId = null;
    _cacheArmorId = null;
    _cacheRingId = null;
    _cacheBootsId = null;
  }

  // --- Asset manifest scanning for weapon images ---
  List<String> _weaponAssets = [];
  final Map<String, List<String>> _enemyAssetsByType = {};

  Future<void> _loadAssetManifest() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> map = jsonDecode(manifest) as Map<String, dynamic>;
      await _loadMonsterConfig();

      // Weapons
      _weaponAssets = map.keys
          .whereType<String>()
          .where((k) => k.startsWith('assets/images/weapons/'))
          .cast<String>()
          .toList(growable: false);

      // Enemies: group by type subfolder if present
      final enemyPaths = map.keys
          .whereType<String>()
          .where((k) => k.startsWith('assets/images/enemies/'))
          .cast<String>()
          .toList(growable: false);

      _enemyAssetsByType.clear();
      for (final p in enemyPaths) {
        // Expect either enemies/<type>.png OR enemies/<type>/<variant>.png
        final parts = p.split('/');
        final int idx = parts.indexOf('enemies');
        if (idx < 0) continue;
        String type;
        if (idx + 2 < parts.length && parts[idx + 2].endsWith('.png')) {
          // enemies/<type>/<file.png>
          type = parts[idx + 1].toLowerCase();
        } else if (idx + 1 < parts.length && parts.last.endsWith('.png')) {
          // enemies/<type>.png
          type = parts[idx + 1].split('.').first.toLowerCase();
        } else {
          continue;
        }
        _enemyAssetsByType.putIfAbsent(type, () => []).add(p);
      }

      // Sort variants by numeric hint in filename/path (ascending), fallback by path
      int _extractNum(String s) {
        final m = RegExp(r'(\d+)').firstMatch(s);
        return m == null ? 1 << 30 : int.tryParse(m.group(1)!) ?? (1 << 30);
      }
      for (final e in _enemyAssetsByType.entries) {
        e.value.sort((a, b) {
          final na = _extractNum(a), nb = _extractNum(b);
          if (na != nb) return na.compareTo(nb);
          return a.compareTo(b);
        });
      }
    } catch (_) {
      _weaponAssets = const [];
      _enemyAssetsByType.clear();
    } finally {
      _assetsReady = true;
    }
  }

  String? _pickWeaponImage(Item item) {
    if (_weaponAssets.isEmpty) return null;
    // rarity digit mapping
    final rarityDigit = switch (item.rarity) {
      ItemRarity.normal => '0',
      ItemRarity.uncommon => '1',
      ItemRarity.rare => '2',
      ItemRarity.legendary => '3',
      ItemRarity.mystic => '4',
    };
    // Match files that contain '_<rarityDigit><number>.png'
    final reg = RegExp(r".*/.+?_" + rarityDigit + r"\d+\.png$", caseSensitive: false);
    final candidates = _weaponAssets.where((p) => reg.hasMatch(p)).toList();
    if (candidates.isEmpty) return null;
    candidates.shuffle();
    return candidates.first;
  }

  // ---- Monster balance/config ----
  Map<String, dynamic> _monsterConfig = const {};

  Future<void> _loadMonsterConfig() async {
    try {
      final s = await rootBundle.loadString('assets/config/monsters.json');
      _monsterConfig = jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      _monsterConfig = const {};
    }
  }

  double _cfgNum(List<String> path, double fallback) {
    dynamic cur = _monsterConfig;
    for (final k in path) {
      if (cur is Map<String, dynamic> && cur.containsKey(k)) {
        cur = cur[k];
      } else {
        return fallback;
      }
    }
    if (cur is num) return cur.toDouble();
    return fallback;
  }

  int _cfgInt(List<String> path, int fallback) {
    dynamic cur = _monsterConfig;
    for (final k in path) {
      if (cur is Map<String, dynamic> && cur.containsKey(k)) {
        cur = cur[k];
      } else {
        return fallback;
      }
    }
    if (cur is num) return cur.toInt();
    return fallback;
  }

  // Public accessors for UI/game logic
  double cfgNum(List<String> path, double fallback) => _cfgNum(path, fallback);
  int cfgInt(List<String> path, int fallback) => _cfgInt(path, fallback);

  String pickEnemyImage(String type, {required int difficultyIndex}) {
    final key = type.toLowerCase();
    final list = _enemyAssetsByType[key];
    if (list == null || list.isEmpty) {
      // Fallback to flat image if variants not found
      return 'assets/images/enemies/$key.png';
    }
    final idx = difficultyIndex.clamp(0, list.length - 1);
    return list[idx];
  }

  StatsSummary get statsSummary {
    final w = profile.weapon?.id;
    final a = profile.armor?.id;
    final r = profile.ring?.id;
    final b = profile.boots?.id;
    final dirty = _statsCache == null ||
        w != _cacheWeaponId || a != _cacheArmorId || r != _cacheRingId || b != _cacheBootsId;
    if (dirty) {
      _statsCache = StatsSummary.fromItems(
        weapon: profile.weapon,
        armor: profile.armor,
        ring: profile.ring,
        boots: profile.boots,
      );
      _cacheWeaponId = w;
      _cacheArmorId = a;
      _cacheRingId = r;
      _cacheBootsId = b;
    }
    return _statsCache!;
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }
}
