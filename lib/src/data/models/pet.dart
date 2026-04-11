import 'item.dart';

class Pet {
  final String id;
  final String name;
  final String description;
  final ItemRarity rarity;

  /// Fractional stamina regen (e.g. 0.05 → +5% from companion).
  final double staminaRegenBonus;

  /// Flat attack added after gear + perm upgrades.
  final int attackBonus;

  /// Flat defense added after gear + perm upgrades.
  final int defenseBonus;

  /// Added to accuracy stat (final hit chance still clamped in combat).
  final double accuracyBonus;

  /// Added to evasion.
  final double evasionBonus;

  /// Added to crit chance (0..1 scale).
  final double critChanceBonus;

  /// Added to crit damage multiplier.
  final double critDamageBonus;

  const Pet({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    this.staminaRegenBonus = 0,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.accuracyBonus = 0,
    this.evasionBonus = 0,
    this.critChanceBonus = 0,
    this.critDamageBonus = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rarity': rarity.name,
        'staminaRegenBonus': staminaRegenBonus,
        'attackBonus': attackBonus,
        'defenseBonus': defenseBonus,
        'accuracyBonus': accuracyBonus,
        'evasionBonus': evasionBonus,
        'critChanceBonus': critChanceBonus,
        'critDamageBonus': critDamageBonus,
      };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        rarity: ItemRarity.values.firstWhere(
          (e) => e.name == (json['rarity'] as String?),
          orElse: () => ItemRarity.normal,
        ),
        staminaRegenBonus: (json['staminaRegenBonus'] as num?)?.toDouble() ?? 0,
        attackBonus: (json['attackBonus'] as num?)?.toInt() ?? 0,
        defenseBonus: (json['defenseBonus'] as num?)?.toInt() ?? 0,
        accuracyBonus: (json['accuracyBonus'] as num?)?.toDouble() ?? 0,
        evasionBonus: (json['evasionBonus'] as num?)?.toDouble() ?? 0,
        critChanceBonus: (json['critChanceBonus'] as num?)?.toDouble() ?? 0,
        critDamageBonus: (json['critDamageBonus'] as num?)?.toDouble() ?? 0,
      );

  static List<Pet> allPets() => const [
        // COMMON (4)
        Pet(
          id: 'pet_fox',
          name: 'Fox',
          description: 'Clever hunter — extra punch and good stamina recovery.',
          rarity: ItemRarity.normal,
          staminaRegenBonus: 0.06,
          attackBonus: 2,
        ),
        Pet(
          id: 'pet_owl',
          name: 'Owl',
          description: 'Keeps watch — helps you land hits.',
          rarity: ItemRarity.normal,
          staminaRegenBonus: 0.03,
          accuracyBonus: 0.05,
        ),
        Pet(
          id: 'pet_beetle',
          name: 'Beetle',
          description: 'Hard shell — soaks a bit more damage.',
          rarity: ItemRarity.normal,
          staminaRegenBonus: 0.04,
          defenseBonus: 3,
        ),
        Pet(
          id: 'pet_rabbit',
          name: 'Dust Rabbit',
          description: 'Slippery — easier to dodge enemy swings.',
          rarity: ItemRarity.normal,
          staminaRegenBonus: 0.04,
          evasionBonus: 0.06,
        ),

        // RARE (3)
        Pet(
          id: 'pet_cat',
          name: 'Shadow Cat',
          description: 'Lucky strikes — more critical hits.',
          rarity: ItemRarity.rare,
          staminaRegenBonus: 0.05,
          critChanceBonus: 0.05,
          critDamageBonus: 0.10,
        ),
        Pet(
          id: 'pet_wolf',
          name: 'Dire Wolf',
          description: 'Fierce and unrelenting in combat.',
          rarity: ItemRarity.rare,
          staminaRegenBonus: 0.05,
          attackBonus: 8,
        ),
        Pet(
          id: 'pet_salamander',
          name: 'Fire Salamander',
          description: 'Blistering accuracy and searing pain.',
          rarity: ItemRarity.rare,
          accuracyBonus: 0.10,
          critDamageBonus: 0.20,
        ),

        // LEGENDARY (3)
        Pet(
          id: 'pet_stag',
          name: 'Spectral Stag',
          description: 'A phantasmal beast — grants immense elusive abilities.',
          rarity: ItemRarity.legendary,
          evasionBonus: 0.15,
          staminaRegenBonus: 0.10,
        ),
        Pet(
          id: 'pet_griffin',
          name: 'Golden Griffin',
          description: 'A symbol of majesty offering supreme combat prowess.',
          rarity: ItemRarity.legendary,
          attackBonus: 15,
          defenseBonus: 10,
        ),
        Pet(
          id: 'pet_panther',
          name: 'Void Panther',
          description: 'Strikes from the void with lethal precision.',
          rarity: ItemRarity.legendary,
          critChanceBonus: 0.10,
          evasionBonus: 0.10,
        ),

        // MYTHIC (2)
        Pet(
          id: 'pet_dragon',
          name: 'Astral Dragon',
          description: 'An ancient terror that obliterates foes effortlessly.',
          rarity: ItemRarity.mythic,
          attackBonus: 25,
          defenseBonus: 15,
          critDamageBonus: 0.50,
        ),
        Pet(
          id: 'pet_phoenix',
          name: 'Phoenix',
          description: 'Endless vitality and unerring flames.',
          rarity: ItemRarity.mythic,
          staminaRegenBonus: 0.25,
          critChanceBonus: 0.15,
          accuracyBonus: 0.15,
        ),
      ];
}
