import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';
import '../data/models/item.dart';
import '../data/models/pet.dart';
import '../data/models/player_profile.dart';
import '../data/models/hero_class.dart';
import '../data/repositories/game_repository.dart';
import '../core/stats.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../ui/overlay/overlay_service.dart';

enum PermanentUpgrade { health, stamina, attack, defense, speed }

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
  String? _cachePetId;
  int _cachePermAttackLevel = -1, _cachePermDefenseLevel = -1;

  // Asset readiness flag
  bool _assetsReady = false;
  bool get assetsReady => _assetsReady;

  bool _isEndlessMode = false;
  bool get isEndlessMode => _isEndlessMode;
  void setIsEndlessMode(bool val) {
    _isEndlessMode = val;
    _invalidateStatsCache();
    notifyListeners();
  }

  // Ephemeral combat state for tuning regen
  bool _inCombat = false;
  void setCombatActive(bool v) {
    _inCombat = v;
  }

  // Temporary blessing state
  DateTime? _blessUntil;
  double _blessAttackSpeedMul = 1.0; // >1 means faster
  double _blessStaminaRegenMul = 1.0; // >1 means more regen
  bool get isBlessActive =>
      _blessUntil != null && DateTime.now().isBefore(_blessUntil!);
  double get blessingAttackSpeedMultiplier =>
      isBlessActive ? _blessAttackSpeedMul : 1.0;
  double get attackSpeedMultiplier =>
      blessingAttackSpeedMultiplier * profile.speedMultiplier;
  double get staminaRegenMultiplier =>
      isBlessActive ? _blessStaminaRegenMul : 1.0;
  int get blessRemainingSeconds {
    if (!isBlessActive) return 0;
    final secs = _blessUntil!.difference(DateTime.now()).inSeconds;
    return max(0, secs);
  }

  String applyTemporaryBlessing({
    Duration duration = const Duration(seconds: 30),
  }) {
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

  // --- Class Skill State ---
  final Map<String, DateTime> _lastSkillUsage = {};

  // Active timed buffs from skills
  bool _isIronWallActive = false;
  bool _isShadowStrikeActive = false;
  int _shadowStrikeHitsRemaining = 0;
  bool _isBloodlustActive = false;

  bool get isIronWallActive => _isIronWallActive;
  bool get isShadowStrikeActive => _isShadowStrikeActive;
  bool get isBloodlustActive => _isBloodlustActive;

  bool canUseSkill(String classId) {
    final cls = HeroClass.get(classId);
    final skill = cls.skill;
    if (skill == null) return false;
    if (skill.cooldownSec <= 0) return true; // Passive or no CD

    final last = _lastSkillUsage[classId];
    if (last == null) return true;
    
    final elapsed = DateTime.now().difference(last).inSeconds;
    return elapsed >= skill.cooldownSec;
  }

  double getSkillCooldownProgress(String classId) {
    final cls = HeroClass.get(classId);
    final skill = cls.skill;
    if (skill == null || skill.cooldownSec <= 0) return 1.0;

    final last = _lastSkillUsage[classId];
    if (last == null) return 1.0;

    final elapsed = DateTime.now().difference(last).inSeconds;
    return (elapsed / skill.cooldownSec).clamp(0.0, 1.0);
  }

  bool isSkillOffCooldown(String skillId) {
    final last = _lastSkillUsage[profile.selectedClassId];
    if (last == null) return true;
    final cls = HeroClass.get(profile.selectedClassId);
    final skill = cls.skill;
    if (skill == null || skill.id != skillId) return true;
    final elapsed = DateTime.now().difference(last).inSeconds;
    return elapsed >= skill.cooldownSec;
  }

  void startSkillCooldown(String skillId) {
    _lastSkillUsage[profile.selectedClassId] = DateTime.now();
    notifyListeners();
  }

  void activateSkillBuff(String skillId) {
    switch (skillId) {
      case 'iron_wall':
        _isIronWallActive = true;
        Timer(const Duration(seconds: 5), () {
          _isIronWallActive = false;
          notifyListeners();
        });
        break;
      case 'shadow_strike':
        _isShadowStrikeActive = true;
        _shadowStrikeHitsRemaining = 3;
        break;
      case 'bloodlust':
        _isBloodlustActive = true;
        _invalidateStatsCache();
        Timer(const Duration(seconds: 8), () {
          _isBloodlustActive = false;
          _invalidateStatsCache();
          notifyListeners();
        });
        break;
    }
    notifyListeners();
  }

  int getSkillSecondsRemaining(String skillId) {
    final last = _lastSkillUsage[profile.selectedClassId];
    if (last == null) return 0;
    final cls = HeroClass.get(profile.selectedClassId);
    final skill = cls.skill;
    if (skill == null || skill.id != skillId) return 0;
    final elapsed = DateTime.now().difference(last).inSeconds;
    return max(0, skill.cooldownSec - elapsed);
  }

  /// Triggers the skill for the currently selected class.
  /// Returns a map with effect details (e.g. {type: 'instant_damage', value: 1.5})
  Map<String, dynamic>? useActiveSkill() {
    final classId = profile.selectedClassId;
    if (!canUseSkill(classId)) return null;

    final cls = HeroClass.get(classId);
    final skill = cls.skill;
    if (skill == null) return null;

    _lastSkillUsage[classId] = DateTime.now();

    Map<String, dynamic>? result;

    switch (skill.id) {
      case 'power_strike':
        result = {'type': 'damage_multiplier', 'value': 1.5, 'name': 'Power Strike'};
        break;
      
      case 'iron_wall':
        _isIronWallActive = true;
        result = {'type': 'buff', 'name': 'Iron Wall', 'duration': 5};
        Timer(const Duration(seconds: 5), () {
          _isIronWallActive = false;
          notifyListeners();
        });
        break;

      case 'shadow_strike':
        _isShadowStrikeActive = true;
        _shadowStrikeHitsRemaining = 3;
        result = {'type': 'buff', 'name': 'Shadow Strike', 'hits': 3};
        break;

      case 'arcane_burst':
        result = {'type': 'instant_damage', 'value': 4.0, 'name': 'Arcane Burst'};
        break;

      case 'bloodlust':
        _isBloodlustActive = true;
        _invalidateStatsCache(); // Speed changes
        result = {'type': 'buff', 'name': 'Bloodlust', 'duration': 8};
        Timer(const Duration(seconds: 8), () {
          _isBloodlustActive = false;
          _invalidateStatsCache();
          notifyListeners();
        });
        break;
    }

    notifyListeners();
    return result;
  }

  void consumeShadowStrikeHit() {
    if (_shadowStrikeHitsRemaining > 0) {
      _shadowStrikeHitsRemaining--;
      if (_shadowStrikeHitsRemaining == 0) {
        _isShadowStrikeActive = false;
      }
      notifyListeners();
    }
  }

  // --- End Class Skill State ---

  static const PlayerProfile _placeholder = PlayerProfile(
    userId: 'local',
    health: 100,
    stamina: 100,
    coins: 0,
    diamonds: 0,
    highScore: 0,
    highestUnlockedLevel: 1,
    equipmentKeys: 0,
    maxHealth: 100,
    maxStamina: 100,
    healthUpgrades: 0,
    staminaUpgrades: 0,
    speedUpgrades: 0,
    permHealthLevel: 0,
    permStaminaLevel: 0,
    permAttackLevel: 0,
    permDefenseLevel: 0,
    permSpeedLevel: 0,
    speedMultiplier: 0.1,
    selectedClassId: 'survivor',
    unlockedClassIds: ['survivor'],
    hasEquipmentBeenSeparated: true,
  );

  // Upgrade config
  static const int healthUpgradeStep = 10;
  static const int staminaUpgradeStep = 10;
  static const double speedUpgradeStep = 0.1;

  // Permanent upgrade steps and cost formula (diamonds)
  static const int permHealthStep = 10;
  static const int permStaminaStep = 10;
  static const int permAttackStep = 1;
  static const int permDefenseStep = 1;
  static const double permSpeedStep = 0.1;

  int get healthUpgradeCost => 10 + 5 * profile.healthUpgrades;
  int get staminaUpgradeCost => 10 + 5 * profile.staminaUpgrades;
  int get speedUpgradeCost => 50 + 25 * profile.speedUpgrades;

  double get maxSpeedMultiplier =>
      (1.0 + profile.speedUpgrades * speedUpgradeStep + profile.permSpeedLevel * permSpeedStep + selectedClass.speedBonus).clamp(1.0, 3.0);

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
      PermanentUpgrade.speed => profile.permSpeedLevel,
    };
    return 20 + 10 * level; // simple scaling
  }

  Future<void> init() async {
    // For now use a fixed local user id; later replace with auth uid.
    _profile = await repo.loadProfile(userId: 'local');
    
    // One-time migration: Clear legacy journey items from permanent slots as requested.
    // This only runs once per user to avoid clobbering new Shop purchases.
    if (!profile.hasEquipmentBeenSeparated) {
      clearPermanentEquipment();
      _profile = profile.copyWith(hasEquipmentBeenSeparated: true);
      _persist();
    }
    
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
      final regen =
          (2 * (1.0 + petBonus) * idleMul * staminaRegenMultiplier).round();
      final s = (profile.stamina + regen).clamp(0, profile.maxStamina).toInt();
      _profile = profile.copyWith(stamina: s);
      notifyListeners();
      _persist();
    });
  }

  Pet? get selectedPet {
    final id = profile.selectedPetId;
    if (id == null) return null;
    return Pet.starterPets().firstWhere(
      (p) => p.id == id,
      orElse: () => Pet.starterPets().first,
    );
  }

  void selectPet(String petId) {
    _profile = profile.copyWith(selectedPetId: petId);
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  HeroClass get selectedClass => HeroClass.get(profile.selectedClassId);

  void selectClass(String classId) {
    if (!profile.unlockedClassIds.contains(classId)) return;
    _profile = profile.copyWith(selectedClassId: classId);
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  bool unlockClass(String classId, int cost, bool useDiamonds) {
    if (profile.unlockedClassIds.contains(classId)) return true;
    if (useDiamonds) {
      if (profile.diamonds < cost) return false;
      _profile = profile.copyWith(
        diamonds: profile.diamonds - cost,
        unlockedClassIds: [...profile.unlockedClassIds, classId],
      );
    } else {
      if (profile.coins < cost) return false;
      _profile = profile.copyWith(
        coins: profile.coins - cost,
        unlockedClassIds: [...profile.unlockedClassIds, classId],
      );
    }
    notifyListeners();
    _persist();
    return true;
  }

  void setSpeedMultiplier(double value) {
    _profile = profile.copyWith(speedMultiplier: value);
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  void resetForNewRun() {
    final cls = selectedClass;
    final baseMaxH = 100 + permHealthLevel * permHealthStep + cls.healthBonus;
    final baseMaxS = 100 + permStaminaLevel * permStaminaStep + cls.staminaBonus;
    _profile = profile.copyWith(
      health: baseMaxH,
      stamina: baseMaxS,
      maxHealth: baseMaxH,
      maxStamina: baseMaxS,
      healthUpgrades: 0,
      staminaUpgrades: 0,
      speedUpgrades: 0,
      speedMultiplier: profile.speedMultiplier.clamp(0.1, 1.0),
      journeyWeapon: null, // explicitly cleared for the new run
      journeyArmor: null,
      journeyRing: null,
      journeyBoots: null,
      savedStep: null,
      coins: 0,
    );
    // If endless mode acts like the old "classic" mode, we might want to preserve 
    // the fact that items are lost or kept. For now, since "Hero Equipment" is permanent,
    // we do NOT clear standard weapon/armor/ring/boots.
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  void prepareForCheckpointRun() {
    final cls = selectedClass;
    final baseMaxH = 100 + permHealthLevel * permHealthStep + cls.healthBonus;
    final baseMaxS = 100 + permStaminaLevel * permStaminaStep + cls.staminaBonus;
    _profile = profile.copyWith(
      health: baseMaxH,
      stamina: baseMaxS,
      maxHealth: baseMaxH,
      maxStamina: baseMaxS,
      healthUpgrades: 0,
      staminaUpgrades: 0,
      speedUpgrades: 0,
      speedMultiplier: profile.speedMultiplier.clamp(0.1, 1.0 + profile.permSpeedLevel * permSpeedStep),
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

  void addKeys(int amount) {
    _profile = profile.copyWith(equipmentKeys: profile.equipmentKeys + amount);
    notifyListeners();
    _persist();
  }

  /// Triggered after defeating a boss
  void rewardBossDefeat(int level) {
    // Reward: Diamonds + 1 Key
    addDiamonds(50 + (level * 10)); 
    addKeys(1);
    
    // Unlock next level if applicable
    if (level >= profile.highestUnlockedLevel) {
      _profile = profile.copyWith(highestUnlockedLevel: level + 1);
    }
    
    notifyListeners();
    _persist();
  }

  /// Reward logic for endless mode steps
  void processEndlessStep(int step) {
    if (!_isEndlessMode) return;
    
    // Every 10 levels: Money gift (Flat 100 for now)
    if (step > 0 && step % 10 == 0) {
      addCoins(100);
      OverlayService.showToast('Endless Reward: +100 Coins!');
    }
    
    // Every 30 levels: Diamonds gift (Flat 10 for now)
    if (step > 0 && step % 30 == 0) {
      addDiamonds(10);
      OverlayService.showToast('Endless Reward: +10 Diamonds!');
    }
  }

  void clearRunProgress() {
    _profile = profile.copyWith(savedStep: null);
    notifyListeners();
    _persist();
  }

  // End journey: save progress if needed and clear temporary items.
  void endJourney({int? saveStep}) {
    // Save current progress
    _profile = profile.copyWith(
      savedStep: saveStep ?? profile.savedStep,
      journeyWeapon: null,
      journeyArmor: null,
      journeyRing: null,
      journeyBoots: null,
    );
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  bool upgradeHealth() {
    final cost = healthUpgradeCost;
    if (profile.coins < cost) return false;
    final newMax = profile.maxHealth + healthUpgradeStep;
    final int newHealth =
        (profile.health + healthUpgradeStep).clamp(0, newMax).toInt();
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
    final int newStamina =
        (profile.stamina + staminaUpgradeStep).clamp(0, newMax).toInt();
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

  bool upgradeSpeed() {
    final cost = speedUpgradeCost;
    if (profile.coins < cost) return false;
    _profile = profile.copyWith(
      coins: profile.coins - cost,
      speedUpgrades: profile.speedUpgrades + 1,
    );
    // Automatically bump current speed if it was at previous max
    if (profile.speedMultiplier >= maxSpeedMultiplier - speedUpgradeStep - 0.01) {
      _profile = _profile!.copyWith(speedMultiplier: maxSpeedMultiplier);
    }
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
    if (_isIronWallActive) {
      amount = (amount * 0.25).round();
      if (amount < 1 && amount > 0) amount = 1; // Minimum 1 if was non-zero
    }
    final h = max(0, profile.health - (amount.toInt()));
    _profile = profile.copyWith(health: h);
    notifyListeners();
    _persist();
  }

  void gainHealth(int amount) {
    final h = min(totalMaxHealth, profile.health + amount);
    _profile = profile.copyWith(health: h);
    notifyListeners();
    _persist();
  }

  /// Open an equipment chest from the shop.
  /// Deducts cost (Diamonds or Keys) and yields a permanent item.
  Item? openChest(String chestType, {bool useKey = false}) {
    final isEpic = chestType == 'epic';
    final diamondCost = isEpic ? 150 : 50;

    if (useKey) {
      if (profile.equipmentKeys < 1) return null;
      _profile = profile.copyWith(equipmentKeys: profile.equipmentKeys - 1);
    } else {
      if (profile.diamonds < diamondCost) return null;
      _profile = profile.copyWith(diamonds: profile.diamonds - diamondCost);
    }

    // Roll item logic:
    // Regular chest: Score 40 (Uncommon/Rare/Legendary bias)
    // Epic chest: Score 120 (Rare/Legendary/Mystic bias)
    final rarity = isEpic ? _rollRarityForEpic() : _rollRarityForRegular();
    Item it = Item.heroicDrop(rarity: rarity, idGen: () => _uuid.v4());

    // Hard-Equip to permanent slot
    switch (it.type) {
      case ItemType.weapon:
        _profile = profile.copyWith(weapon: it);
        break;
      case ItemType.armor:
        _profile = profile.copyWith(armor: it);
        break;
      case ItemType.ring:
        _profile = profile.copyWith(ring: it);
        break;
      case ItemType.boots:
        _profile = profile.copyWith(boots: it);
        break;
    }

    _invalidateStatsCache();
    notifyListeners();
    _persist();
    return it;
  }

  void buyCurrencyPack(String type, int amount) {
    if (type == 'diamonds') {
      _profile = profile.copyWith(diamonds: profile.diamonds + amount);
    } else {
      _profile = profile.copyWith(coins: profile.coins + amount);
    }
    notifyListeners();
    _persist();
  }

  ItemRarity _rollRarityForRegular() {
    final rnd = Random();
    final roll = rnd.nextInt(100);
    if (roll < 50) return ItemRarity.normal;
    if (roll < 80) return ItemRarity.uncommon;
    if (roll < 95) return ItemRarity.rare;
    return ItemRarity.legendary;
  }

  ItemRarity _rollRarityForEpic() {
    final rnd = Random();
    final roll = rnd.nextInt(100);
    if (roll < 40) return ItemRarity.rare;
    if (roll < 85) return ItemRarity.legendary;
    return ItemRarity.mystic;
  }

  void clearPermanentEquipment() {
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

  // Equipment found in journey (wild drops)
  void equip(Item item) {
    // Finding items during a run (wild drops) ALWAYS goes to journey slots.
    // Permanent slots are only modified via Shop Chests or external events.
    switch (item.type) {
      case ItemType.weapon:
        _profile = profile.copyWith(journeyWeapon: item);
        break;
      case ItemType.armor:
        _profile = profile.copyWith(journeyArmor: item);
        break;
      case ItemType.ring:
        _profile = profile.copyWith(journeyRing: item);
        break;
      case ItemType.boots:
        _profile = profile.copyWith(journeyBoots: item);
        break;
    }
    _invalidateStatsCache();
    notifyListeners();
    _persist();
  }

  // Compute stats for an arbitrary loadout, including permanent upgrades
  StatsSummary computeStats({
    Item? weapon,
    Item? armor,
    Item? ring,
    Item? boots,
    Pet? petForBonuses,
  }) {
    final base = StatsSummary.fromItems(
      weapon: weapon,
      armor: armor,
      ring: ring,
      boots: boots,
    );
    final withPerm = StatsSummary.withBonuses(
      base,
      attackBonus: permAttackLevel * permAttackStep,
      defenseBonus: permDefenseLevel * permDefenseStep,
    );
    final pet = petForBonuses ?? selectedPet;
    if (pet == null) return withPerm;
    return StatsSummary.withPetBonuses(
      withPerm,
      attackBonus: pet.attackBonus,
      defenseBonus: pet.defenseBonus,
      accuracyBonus: pet.accuracyBonus,
      evasionBonus: pet.evasionBonus,
      critChanceBonus: pet.critChanceBonus,
      critDamageBonus: pet.critDamageBonus,
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
    } catch (e, st) {
      debugPrint('[GameState] _persist failed: $e\n$st');
    }
  }

  void _invalidateStatsCache() {
    _statsCache = null;
    _cacheWeaponId = null;
    _cacheArmorId = null;
    _cacheRingId = null;
    _cacheBootsId = null;
    _cachePetId = null;
    _cachePermAttackLevel = -1;
    _cachePermDefenseLevel = -1;
  }

  // --- Asset manifest scanning for weapon images ---
  List<String> _weaponAssets = [];
  final Map<String, List<String>> _enemyAssetsByType = {};

  Future<void> _loadAssetManifest() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> map =
          jsonDecode(manifest) as Map<String, dynamic>;
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

      String enemyTypeFromPath(String p) {
        final parts = p.split('/');
        final int idx = parts.indexOf('enemies');
        if (idx < 0) return '';
        // If nested like enemies/<type>/<file>.png prefer folder name
        if (idx + 2 < parts.length &&
            parts.last.toLowerCase().endsWith('.png')) {
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
        final type = enemyTypeFromPath(p);
        if (type.isEmpty) continue;
        _enemyAssetsByType.putIfAbsent(type, () => []).add(p);
      }

      // Sort variants by numeric hint in filename/path (ascending). Files without a number are treated as tier 1.
      int extractNum(String s) {
        final m = RegExp(r'(\d+)').firstMatch(s);
        return m == null ? 1 : int.tryParse(m.group(1)!) ?? 1;
      }

      for (final e in _enemyAssetsByType.entries) {
        e.value.sort((a, b) {
          final na = extractNum(a), nb = extractNum(b);
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
    final reg = RegExp(
      r".*/.+?_" + rarityDigit + r"\d+\.png$",
      caseSensitive: false,
    );
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

  // ---- Stats Getters ----
  int get totalMaxHealth => profile.maxHealth + selectedClass.healthBonus;
  int get totalMaxStamina => profile.maxStamina + selectedClass.staminaBonus;

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
    // If a journey item exists, it overrides the home (permanent) item for this run.
    final curW = profile.journeyWeapon ?? profile.weapon;
    final curA = profile.journeyArmor ?? profile.armor;
    final curR = profile.journeyRing ?? profile.ring;
    final curB = profile.journeyBoots ?? profile.boots;

    final w = curW?.id;
    final a = curA?.id;
    final r = curR?.id;
    final b = curB?.id;
    final petId = profile.selectedPetId;
    final dirty =
        _statsCache == null ||
        w != _cacheWeaponId ||
        a != _cacheArmorId ||
        r != _cacheRingId ||
        b != _cacheBootsId ||
        petId != _cachePetId ||
        _cachePermAttackLevel != permAttackLevel ||
        _cachePermDefenseLevel != permDefenseLevel;
    if (dirty) {
      final base = StatsSummary.fromItems(
        weapon: curW,
        armor: curA,
        ring: curR,
        boots: curB,
      );
      final withPerm = StatsSummary.withBonuses(
        base,
        attackBonus: permAttackLevel * permAttackStep,
        defenseBonus: permDefenseLevel * permDefenseStep,
      );
      final cls = selectedClass;
      final withClass = StatsSummary.withPetBonuses(
        withPerm,
        attackBonus: cls.attackBonus,
        defenseBonus: cls.defenseBonus,
        critChanceBonus: cls.critChanceBonus,
        critDamageBonus: cls.critDamageBonus,
      );

      final pet = selectedPet;
      final withPet = pet == null
          ? withClass
          : StatsSummary.withPetBonuses(
              withClass,
              attackBonus: pet.attackBonus,
              defenseBonus: pet.defenseBonus,
              accuracyBonus: pet.accuracyBonus,
              evasionBonus: pet.evasionBonus,
              critChanceBonus: pet.critChanceBonus,
              critDamageBonus: pet.critDamageBonus,
            );

      // Apply class speed bonus to attackMs
      double speedMultiplier = 1.0 + cls.speedBonus;
      if (_isBloodlustActive) speedMultiplier += 0.5; // +50% speed from Bloodlust

      if (speedMultiplier != 1.0) {
        final newMs = (withPet.attackMs / speedMultiplier).round().clamp(200, 2000);
        _statsCache = StatsSummary(
          attack: withPet.attack,
          defense: withPet.defense,
          accuracy: withPet.accuracy,
          evasion: withPet.evasion,
          critChance: _isShadowStrikeActive ? 1.0 : withPet.critChance,
          critDamage: withPet.critDamage,
          attackMs: newMs,
          dps: withPet.dps * speedMultiplier,
        );
      } else {
        _statsCache = withPet;
      }
      _cacheWeaponId = w;
      _cacheArmorId = a;
      _cacheRingId = r;
      _cacheBootsId = b;
      _cachePetId = petId;
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
      case PermanentUpgrade.speed:
        _profile = profile.copyWith(
          diamonds: profile.diamonds - cost,
          permSpeedLevel: profile.permSpeedLevel + 1,
        );
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
