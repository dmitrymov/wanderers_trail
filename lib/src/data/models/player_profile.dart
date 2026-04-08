import 'item.dart';
import 'hero_class.dart';

class PlayerProfile {
  final String userId; // future login
  final int health; // current health
  final int stamina; // current stamina
  final int coins;
  final int diamonds; // premium currency
  final int highScore;
  final int highestUnlockedLevel;
  final int equipmentKeys;

  // Run-limited maximums (reset on New Run / Resume Checkpoint)
  final int maxHealth;
  final int maxStamina;
  final double speedMultiplier;

  // Number of upgrades purchased this run (affects cost scaling)
  final int healthUpgrades;
  final int staminaUpgrades;
  final int speedUpgrades;

  // Permanent upgrade levels (persist across runs)
  final int permHealthLevel;   // +10 max health per level
  final int permStaminaLevel;  // +10 max stamina per level
  final int permAttackLevel;   // +1 attack per level
  final int permDefenseLevel;  // +1 defense per level
  final int permSpeedLevel;    // +0.1 max speed multiplier per level

  final Item? weapon;
  final Item? armor;
  final Item? ring;
  final Item? boots;

  final Item? journeyWeapon;
  final Item? journeyArmor;
  final Item? journeyRing;
  final Item? journeyBoots;

  final String? selectedPetId;
  final String selectedClassId;
  final List<String> unlockedClassIds;
  final int? savedStep; // last saved run step for Continue
  final bool hasEquipmentBeenSeparated; // One-time migration flag

  const PlayerProfile({
    required this.userId,
    required this.health,
    required this.stamina,
    required this.coins,
    required this.diamonds,
    required this.highScore,
    required this.highestUnlockedLevel,
    required this.equipmentKeys,
    required this.maxHealth,
    required this.maxStamina,
    required this.healthUpgrades,
    required this.staminaUpgrades,
    required this.speedUpgrades,
    required this.permHealthLevel,
    required this.permStaminaLevel,
    required this.permAttackLevel,
    required this.permDefenseLevel,
    required this.permSpeedLevel,
    required this.speedMultiplier,
    this.weapon,
    this.armor,
    this.ring,
    this.boots,
    this.journeyWeapon,
    this.journeyArmor,
    this.journeyRing,
    this.journeyBoots,
    this.selectedPetId,
    required this.selectedClassId,
    required this.unlockedClassIds,
    this.savedStep,
    required this.hasEquipmentBeenSeparated,
  });

  static const Object _unset = Object();

  PlayerProfile copyWith({
    String? userId,
    int? health,
    int? stamina,
    int? coins,
    int? diamonds,
    int? highScore,
    int? highestUnlockedLevel,
    int? equipmentKeys,
    int? maxHealth,
    int? maxStamina,
    int? healthUpgrades,
    int? staminaUpgrades,
    int? speedUpgrades,
    int? permHealthLevel,
    int? permStaminaLevel,
    int? permAttackLevel,
    int? permDefenseLevel,
    int? permSpeedLevel,
    double? speedMultiplier,
    Object? weapon = _unset,
    Object? armor = _unset,
    Object? ring = _unset,
    Object? boots = _unset,
    Object? journeyWeapon = _unset,
    Object? journeyArmor = _unset,
    Object? journeyRing = _unset,
    Object? journeyBoots = _unset,
    Object? selectedPetId = _unset,
    String? selectedClassId,
    List<String>? unlockedClassIds,
    Object? savedStep = _unset,
    bool? hasEquipmentBeenSeparated,
  }) => PlayerProfile(
        userId: userId ?? this.userId,
        health: health ?? this.health,
        stamina: stamina ?? this.stamina,
        coins: coins ?? this.coins,
        diamonds: diamonds ?? this.diamonds,
        highScore: highScore ?? this.highScore,
        highestUnlockedLevel: highestUnlockedLevel ?? this.highestUnlockedLevel,
        equipmentKeys: equipmentKeys ?? this.equipmentKeys,
        maxHealth: maxHealth ?? this.maxHealth,
        maxStamina: maxStamina ?? this.maxStamina,
        healthUpgrades: healthUpgrades ?? this.healthUpgrades,
        staminaUpgrades: staminaUpgrades ?? this.staminaUpgrades,
        speedUpgrades: speedUpgrades ?? this.speedUpgrades,
        permHealthLevel: permHealthLevel ?? this.permHealthLevel,
        permStaminaLevel: permStaminaLevel ?? this.permStaminaLevel,
        permAttackLevel: permAttackLevel ?? this.permAttackLevel,
        permDefenseLevel: permDefenseLevel ?? this.permDefenseLevel,
        permSpeedLevel: permSpeedLevel ?? this.permSpeedLevel,
        speedMultiplier: speedMultiplier ?? this.speedMultiplier,
        weapon: identical(weapon, _unset) ? this.weapon : weapon as Item?,
        armor: identical(armor, _unset) ? this.armor : armor as Item?,
        ring: identical(ring, _unset) ? this.ring : ring as Item?,
        boots: identical(boots, _unset) ? this.boots : boots as Item?,
        journeyWeapon: identical(journeyWeapon, _unset) ? this.journeyWeapon : journeyWeapon as Item?,
        journeyArmor: identical(journeyArmor, _unset) ? this.journeyArmor : journeyArmor as Item?,
        journeyRing: identical(journeyRing, _unset) ? this.journeyRing : journeyRing as Item?,
        journeyBoots: identical(journeyBoots, _unset) ? this.journeyBoots : journeyBoots as Item?,
        selectedPetId: identical(selectedPetId, _unset) ? this.selectedPetId : selectedPetId as String?,
        selectedClassId: selectedClassId ?? this.selectedClassId,
        unlockedClassIds: unlockedClassIds ?? this.unlockedClassIds,
        savedStep: identical(savedStep, _unset) ? this.savedStep : savedStep as int?,
        hasEquipmentBeenSeparated: hasEquipmentBeenSeparated ?? this.hasEquipmentBeenSeparated,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'health': health,
        'stamina': stamina,
        'coins': coins,
        'diamonds': diamonds,
        'highScore': highScore,
        'highestUnlockedLevel': highestUnlockedLevel,
        'equipmentKeys': equipmentKeys,
        'maxHealth': maxHealth,
        'maxStamina': maxStamina,
        'healthUpgrades': healthUpgrades,
        'staminaUpgrades': staminaUpgrades,
        'speedUpgrades': speedUpgrades,
        'permHealthLevel': permHealthLevel,
        'permStaminaLevel': permStaminaLevel,
        'permAttackLevel': permAttackLevel,
        'permDefenseLevel': permDefenseLevel,
        'permSpeedLevel': permSpeedLevel,
        'speedMultiplier': speedMultiplier,
        'weapon': weapon?.toJson(),
        'armor': armor?.toJson(),
        'ring': ring?.toJson(),
        'boots': boots?.toJson(),
        'journeyWeapon': journeyWeapon?.toJson(),
        'journeyArmor': journeyArmor?.toJson(),
        'journeyRing': journeyRing?.toJson(),
        'journeyBoots': journeyBoots?.toJson(),
        'selectedPetId': selectedPetId,
        'selectedClassId': selectedClassId,
        'unlockedClassIds': unlockedClassIds,
        'savedStep': savedStep,
        'hasEquipmentBeenSeparated': hasEquipmentBeenSeparated,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        userId: json['userId'] as String,
        health: (json['health'] as num).toInt(),
        stamina: (json['stamina'] as num).toInt(),
        coins: (json['coins'] as num).toInt(),
        diamonds: (json['diamonds'] as num?)?.toInt() ?? 0,
        highScore: (json['highScore'] as num).toInt(),
        highestUnlockedLevel: (json['highestUnlockedLevel'] as num?)?.toInt() ?? 1,
        equipmentKeys: (json['equipmentKeys'] as num?)?.toInt() ?? 0,
        maxHealth: (json['maxHealth'] as num?)?.toInt() ?? (json['health'] as num).toInt(),
        maxStamina: (json['maxStamina'] as num?)?.toInt() ?? (json['stamina'] as num).toInt(),
        healthUpgrades: (json['healthUpgrades'] as num?)?.toInt() ?? 0,
        staminaUpgrades: (json['staminaUpgrades'] as num?)?.toInt() ?? 0,
        speedUpgrades: (json['speedUpgrades'] as num?)?.toInt() ?? 0,
        permHealthLevel: (json['permHealthLevel'] as num?)?.toInt() ?? 0,
        permStaminaLevel: (json['permStaminaLevel'] as num?)?.toInt() ?? 0,
        permAttackLevel: (json['permAttackLevel'] as num?)?.toInt() ?? 0,
        permDefenseLevel: (json['permDefenseLevel'] as num?)?.toInt() ?? 0,
        permSpeedLevel: (json['permSpeedLevel'] as num?)?.toInt() ?? 0,
        speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble() ?? 1.0,
        weapon:
            json['weapon'] == null ? null : Item.fromJson(json['weapon'] as Map<String, dynamic>),
        armor: json['armor'] == null ? null : Item.fromJson(json['armor'] as Map<String, dynamic>),
        ring: json['ring'] == null ? null : Item.fromJson(json['ring'] as Map<String, dynamic>),
        boots: json['boots'] == null ? null : Item.fromJson(json['boots'] as Map<String, dynamic>),
        journeyWeapon:
            json['journeyWeapon'] == null ? null : Item.fromJson(json['journeyWeapon'] as Map<String, dynamic>),
        journeyArmor: json['journeyArmor'] == null ? null : Item.fromJson(json['journeyArmor'] as Map<String, dynamic>),
        journeyRing: json['journeyRing'] == null ? null : Item.fromJson(json['journeyRing'] as Map<String, dynamic>),
        journeyBoots: json['journeyBoots'] == null ? null : Item.fromJson(json['journeyBoots'] as Map<String, dynamic>),
        selectedPetId: json['selectedPetId'] as String?,
        selectedClassId: json['selectedClassId'] as String? ?? 'survivor',
        unlockedClassIds: (json['unlockedClassIds'] as List<dynamic>?)?.cast<String>() ?? ['survivor'],
        savedStep: (json['savedStep'] as num?)?.toInt(),
        hasEquipmentBeenSeparated: json['hasEquipmentBeenSeparated'] as bool? ?? false,
      );

  static PlayerProfile defaults({required String userId}) => PlayerProfile(
        userId: userId,
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
        unlockedClassIds: const ['survivor'],
        savedStep: null,
        hasEquipmentBeenSeparated: true, // New profiles don't need reset
      );

  HeroClass get heroClass => HeroClass.get(selectedClassId);
}
