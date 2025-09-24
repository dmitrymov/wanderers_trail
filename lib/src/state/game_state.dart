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

enum PermanentUpgrade { health, stamina, attack, defense }

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
  int _cachePermAttackLevel = -1, _cachePermDefenseLevel = -1;

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
    diamonds: 0,
    highScore: 0,
    maxHealth: 100,
    maxStamina: 100,
    healthUpgrades: 0,
    staminaUpgrades: 0,
    permHealthLevel: 0,
    permStaminaLevel: 0,
    permAttackLevel: 0,
    permDefenseLevel: 0,
  );

  // Upgrade config
  static const int healthUpgradeStep = 10;
  static const int staminaUpgradeStep = 10;

  // Permanent upgrade steps and cost formula (diamonds)
  static const int permHealthStep = 10;
  static const int permStaminaStep = 10;
  static const int permAttackStep = 1;
  static const int permDefenseStep = 1;

  int get healthUpgradeCost => 10 + 5 * profile.healthUpgrades;
  int get staminaUpgradeCost => 10 + 5 * profile.staminaUpgrades;

  // Diamonds and permanent upgrades
  int get diamonds => profile.diamonds;
  int get permHealthLevel => profile.permHealthLevel;
  int get permStaminaLevel => profile.permStaminaLevel;
  int get permAttackLevel => profile.permAttackLevel;
  int get permDefenseLevel => profile.permDefenseLevel;

  int permanentUpgradeCost(PermanentUpgrade u) {
    final level = switch (u) {
      PermanentUpgrade.health => permHealthLevel,
      PermanentUpgrade.stamina => permStaminaLevel,
      PermanentUpgrade.attack => permAttackLevel,
      PermanentUpgrade.defense => permDefenseLevel,
    };
    return 20 + 10 * level; // simple scaling
  }

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
      final s = (profile.stamina + regen).clamp(0, profile.maxStamina).toInt();
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
    final baseMaxH = 100 + permHealthLevel * permHealthStep;
    final baseMaxS = 100 + permStaminaLevel * permStaminaStep;
    _profile = profile.copyWith(
      health: baseMaxH,
      stamina: baseMaxS,
      maxHealth: baseMaxH,
      maxStamina: baseMaxS,
      healthUpgrades: 0,
      staminaUpgrades: 0,
      weapon: null, // cleared explicitly via sentinel-aware copyWith
      armor: null,
      ring: null,
      boots: null,
      savedStep: null,
      coins: 0,
    );
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  void prepareForCheckpointRun() {
    final baseMaxH = 100 + permHealthLevel * permHealthStep;
    final baseMaxS = 100 + permStaminaLevel * permStaminaStep;
    _profile = profile.copyWith(
      health: baseMaxH,
      stamina: baseMaxS,
      maxHealth: baseMaxH,
      maxStamina: baseMaxS,
      healthUpgrades: 0,
      staminaUpgrades: 0,
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

  // Leave battle: save progress at given step and preserve equipment.
  // Equipment should only be reset on a New Run.
  void leaveBattleAndResetEquipment({required int saveStep}) {
    // Save current progress
    _profile = profile.copyWith(savedStep: saveStep);
    notifyListeners();
    _persist();
  }

  bool upgradeHealth() {
    final cost = healthUpgradeCost;
    if (profile.coins < cost) return false;
    final newMax = profile.maxHealth + healthUpgradeStep;
    final int newHealth = (profile.health + healthUpgradeStep).clamp(0, newMax).toInt();
    _profile = profile.copyWith(
      maxHealth: newMax,
      health: newHealth,
      coins: profile.coins - cost,
      healthUpgrades: profile.healthUpgrades + 1,
    );
    notifyListeners();
    _persist();
    return true;
  }

  bool upgradeStamina() {
    final cost = staminaUpgradeCost;
    if (profile.coins < cost) return false;
    final newMax = profile.maxStamina + staminaUpgradeStep;
    final int newStamina = (profile.stamina + staminaUpgradeStep).clamp(0, newMax).toInt();
    _profile = profile.copyWith(
      maxStamina: newMax,
      stamina: newStamina,
      coins: profile.coins - cost,
      staminaUpgrades: profile.staminaUpgrades + 1,
    );
    notifyListeners();
    _persist();
    return true;
  }

  void addCoins(int amount) {
    _profile = profile.copyWith(coins: max(0, profile.coins + amount));
    notifyListeners();
    _persist();
  }

  void addDiamonds(int amount) {
    _profile = profile.copyWith(diamonds: max(0, profile.diamonds + amount));
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
    final int clamped = (profile.health - amount).clamp(0, profile.maxHealth).toInt();
    _profile = profile.copyWith(health: clamped);
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

  // Compute stats for an arbitrary loadout, including permanent upgrades
  StatsSummary computeStats({Item? weapon, Item? armor, Item? ring, Item? boots}) {
    final base = StatsSummary.fromItems(
      weapon: weapon,
      armor: armor,
      ring: ring,
      boots: boots,
    );
    return StatsSummary.withBonuses(
      base,
      attackBonus: permAttackLevel * permAttackStep,
      defenseBonus: permDefenseLevel * permDefenseStep,
    );
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
    _cachePermAttackLevel = -1;
    _cachePermDefenseLevel = -1;
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

      // Enemies: group by type subfolder if present, or by base filename without trailing digits
      final enemyPaths = map.keys
          .whereType<String>()
          .where((k) => k.startsWith('assets/images/enemies/'))
          .cast<String>()
          .toList(growable: false);

      _enemyAssetsByType.clear();

      String _enemyTypeFromPath(String p) {
        final parts = p.split('/');
        final int idx = parts.indexOf('enemies');
        if (idx < 0) return '';
        // If nested like enemies/<type>/<file>.png prefer folder name
        if (idx + 2 < parts.length && parts.last.toLowerCase().endsWith('.png')) {
          return parts[idx + 1].toLowerCase();
        }
        // Otherwise use filename base without trailing digits, e.g. bandit2.png -> bandit
        final file = parts.last.toLowerCase();
        if (!file.endsWith('.png')) return '';
        final base = file.split('.').first;
        // Remove trailing digits (e.g., bandit2 -> bandit)
        return base.replaceFirst(RegExp(r'\d+$'), '');
      }

      for (final p in enemyPaths) {
        final type = _enemyTypeFromPath(p);
        if (type.isEmpty) continue;
        _enemyAssetsByType.putIfAbsent(type, () => []).add(p);
      }

      // Sort variants by numeric hint in filename/path (ascending). Files without a number are treated as tier 1.
      int _extractNum(String s) {
        final m = RegExp(r'(\d+)').firstMatch(s);
        return m == null ? 1 : int.tryParse(m.group(1)!) ?? 1;
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

  // Expose available variant paths/count for preloading or random selection
  List<String> enemyVariantPaths(String type) {
    final key = type.toLowerCase();
    final list = _enemyAssetsByType[key];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }

  int enemyVariantCount(String type) {
    final key = type.toLowerCase();
    final list = _enemyAssetsByType[key];
    return list?.length ?? 0;
  }

  StatsSummary get statsSummary {
    final w = profile.weapon?.id;
    final a = profile.armor?.id;
    final r = profile.ring?.id;
    final b = profile.boots?.id;
    final dirty = _statsCache == null ||
        w != _cacheWeaponId || a != _cacheArmorId || r != _cacheRingId || b != _cacheBootsId ||
        _cachePermAttackLevel != permAttackLevel || _cachePermDefenseLevel != permDefenseLevel;
    if (dirty) {
      final base = StatsSummary.fromItems(
        weapon: profile.weapon,
        armor: profile.armor,
        ring: profile.ring,
        boots: profile.boots,
      );
      final withPerm = StatsSummary.withBonuses(
        base,
        attackBonus: permAttackLevel * permAttackStep,
        defenseBonus: permDefenseLevel * permDefenseStep,
      );
      _statsCache = withPerm;
      _cacheWeaponId = w;
      _cacheArmorId = a;
      _cacheRingId = r;
      _cacheBootsId = b;
      _cachePermAttackLevel = permAttackLevel;
      _cachePermDefenseLevel = permDefenseLevel;
    }
    return _statsCache!;
  }

  // Purchase a permanent upgrade using diamonds. Applies immediately to current run.
  bool purchasePermanent(PermanentUpgrade u) {
    final cost = permanentUpgradeCost(u);
    if (profile.diamonds < cost) return false;
    switch (u) {
      case PermanentUpgrade.health:
        final newMaxH = profile.maxHealth + permHealthStep;
        final newHealth = min(profile.health, newMaxH);
        _profile = profile.copyWith(
          diamonds: profile.diamonds - cost,
          permHealthLevel: profile.permHealthLevel + 1,
          maxHealth: newMaxH,
          health: newHealth,
        );
        break;
      case PermanentUpgrade.stamina:
        final newMaxS = profile.maxStamina + permStaminaStep;
        final newStam = min(profile.stamina, newMaxS);
        _profile = profile.copyWith(
          diamonds: profile.diamonds - cost,
          permStaminaLevel: profile.permStaminaLevel + 1,
          maxStamina: newMaxS,
          stamina: newStam,
        );
        break;
      case PermanentUpgrade.attack:
        _profile = profile.copyWith(
          diamonds: profile.diamonds - cost,
          permAttackLevel: profile.permAttackLevel + 1,
        );
        _invalidateStatsCache();
        break;
      case PermanentUpgrade.defense:
        _profile = profile.copyWith(
          diamonds: profile.diamonds - cost,
          permDefenseLevel: profile.permDefenseLevel + 1,
        );
        _invalidateStatsCache();
        break;
    }
    notifyListeners();
    _persist();
    return true;
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }
}
