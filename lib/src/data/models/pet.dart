class Pet {
  final String id;
  final String name;
  final String description;

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
        staminaRegenBonus: (json['staminaRegenBonus'] as num?)?.toDouble() ?? 0,
        attackBonus: (json['attackBonus'] as num?)?.toInt() ?? 0,
        defenseBonus: (json['defenseBonus'] as num?)?.toInt() ?? 0,
        accuracyBonus: (json['accuracyBonus'] as num?)?.toDouble() ?? 0,
        evasionBonus: (json['evasionBonus'] as num?)?.toDouble() ?? 0,
        critChanceBonus: (json['critChanceBonus'] as num?)?.toDouble() ?? 0,
        critDamageBonus: (json['critDamageBonus'] as num?)?.toDouble() ?? 0,
      );

  static List<Pet> starterPets() => const [
        Pet(
          id: 'pet_fox',
          name: 'Fox',
          description: 'Clever hunter — extra punch and good stamina recovery.',
          staminaRegenBonus: 0.06,
          attackBonus: 2,
        ),
        Pet(
          id: 'pet_owl',
          name: 'Owl',
          description: 'Keeps watch — helps you land hits.',
          staminaRegenBonus: 0.03,
          accuracyBonus: 0.05,
        ),
        Pet(
          id: 'pet_beetle',
          name: 'Beetle',
          description: 'Hard shell — soaks a bit more damage.',
          staminaRegenBonus: 0.04,
          defenseBonus: 3,
        ),
        Pet(
          id: 'pet_cat',
          name: 'Shadow Cat',
          description: 'Lucky strikes — more critical hits.',
          staminaRegenBonus: 0.05,
          critChanceBonus: 0.05,
        ),
        Pet(
          id: 'pet_rabbit',
          name: 'Dust Rabbit',
          description: 'Slippery — easier to dodge enemy swings.',
          staminaRegenBonus: 0.04,
          evasionBonus: 0.06,
        ),
      ];
}
