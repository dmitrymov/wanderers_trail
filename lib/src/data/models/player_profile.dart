import 'item.dart';

class PlayerProfile {
  final String userId; // future login
  final int health; // current health
  final int stamina; // current stamina
  final int coins;
  final int highScore;

  // Run-limited maximums (reset on New Run / Resume Checkpoint)
  final int maxHealth;
  final int maxStamina;

  // Number of upgrades purchased this run (affects cost scaling)
  final int healthUpgrades;
  final int staminaUpgrades;

  final Item? weapon;
  final Item? armor;
  final Item? ring;
  final Item? boots;

  final String? selectedPetId;
  final int? savedStep; // last saved run step for Continue

  const PlayerProfile({
    required this.userId,
    required this.health,
    required this.stamina,
    required this.coins,
    required this.highScore,
    required this.maxHealth,
    required this.maxStamina,
    required this.healthUpgrades,
    required this.staminaUpgrades,
    this.weapon,
    this.armor,
    this.ring,
    this.boots,
    this.selectedPetId,
    this.savedStep,
  });

  static const Object _unset = Object();

  PlayerProfile copyWith({
    String? userId,
    int? health,
    int? stamina,
    int? coins,
    int? highScore,
    int? maxHealth,
    int? maxStamina,
    int? healthUpgrades,
    int? staminaUpgrades,
    Object? weapon = _unset,
    Object? armor = _unset,
    Object? ring = _unset,
    Object? boots = _unset,
    Object? selectedPetId = _unset,
    Object? savedStep = _unset,
  }) => PlayerProfile(
        userId: userId ?? this.userId,
        health: health ?? this.health,
        stamina: stamina ?? this.stamina,
        coins: coins ?? this.coins,
        highScore: highScore ?? this.highScore,
        maxHealth: maxHealth ?? this.maxHealth,
        maxStamina: maxStamina ?? this.maxStamina,
        healthUpgrades: healthUpgrades ?? this.healthUpgrades,
        staminaUpgrades: staminaUpgrades ?? this.staminaUpgrades,
        weapon: identical(weapon, _unset) ? this.weapon : weapon as Item?,
        armor: identical(armor, _unset) ? this.armor : armor as Item?,
        ring: identical(ring, _unset) ? this.ring : ring as Item?,
        boots: identical(boots, _unset) ? this.boots : boots as Item?,
        selectedPetId: identical(selectedPetId, _unset) ? this.selectedPetId : selectedPetId as String?,
        savedStep: identical(savedStep, _unset) ? this.savedStep : savedStep as int?,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'health': health,
        'stamina': stamina,
        'coins': coins,
        'highScore': highScore,
        'maxHealth': maxHealth,
        'maxStamina': maxStamina,
        'healthUpgrades': healthUpgrades,
        'staminaUpgrades': staminaUpgrades,
        'weapon': weapon?.toJson(),
        'armor': armor?.toJson(),
        'ring': ring?.toJson(),
        'boots': boots?.toJson(),
        'selectedPetId': selectedPetId,
        'savedStep': savedStep,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        userId: json['userId'] as String,
        health: (json['health'] as num).toInt(),
        stamina: (json['stamina'] as num).toInt(),
        coins: (json['coins'] as num).toInt(),
        highScore: (json['highScore'] as num).toInt(),
        maxHealth: (json['maxHealth'] as num?)?.toInt() ?? (json['health'] as num).toInt(),
        maxStamina: (json['maxStamina'] as num?)?.toInt() ?? (json['stamina'] as num).toInt(),
        healthUpgrades: (json['healthUpgrades'] as num?)?.toInt() ?? 0,
        staminaUpgrades: (json['staminaUpgrades'] as num?)?.toInt() ?? 0,
        weapon:
            json['weapon'] == null ? null : Item.fromJson(json['weapon'] as Map<String, dynamic>),
        armor: json['armor'] == null ? null : Item.fromJson(json['armor'] as Map<String, dynamic>),
        ring: json['ring'] == null ? null : Item.fromJson(json['ring'] as Map<String, dynamic>),
        boots: json['boots'] == null ? null : Item.fromJson(json['boots'] as Map<String, dynamic>),
        selectedPetId: json['selectedPetId'] as String?,
        savedStep: (json['savedStep'] as num?)?.toInt(),
      );

  static PlayerProfile defaults({required String userId}) => PlayerProfile(
        userId: userId,
        health: 100,
        stamina: 100,
        coins: 0,
        highScore: 0,
        maxHealth: 100,
        maxStamina: 100,
        healthUpgrades: 0,
        staminaUpgrades: 0,
        savedStep: null,
      );
}
