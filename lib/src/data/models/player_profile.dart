import 'item.dart';

class PlayerProfile {
  final String userId; // future login
  final int health;
  final int stamina;
  final int coins;
  final int highScore;

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
    this.weapon,
    this.armor,
    this.ring,
    this.boots,
    this.selectedPetId,
    this.savedStep,
  });

  PlayerProfile copyWith({
    String? userId,
    int? health,
    int? stamina,
    int? coins,
    int? highScore,
    Item? weapon,
    Item? armor,
    Item? ring,
    Item? boots,
    String? selectedPetId,
    int? savedStep,
  }) => PlayerProfile(
        userId: userId ?? this.userId,
        health: health ?? this.health,
        stamina: stamina ?? this.stamina,
        coins: coins ?? this.coins,
        highScore: highScore ?? this.highScore,
        weapon: weapon ?? this.weapon,
        armor: armor ?? this.armor,
        ring: ring ?? this.ring,
        boots: boots ?? this.boots,
        selectedPetId: selectedPetId ?? this.selectedPetId,
        savedStep: savedStep ?? this.savedStep,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'health': health,
        'stamina': stamina,
        'coins': coins,
        'highScore': highScore,
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
        savedStep: null,
      );
}
