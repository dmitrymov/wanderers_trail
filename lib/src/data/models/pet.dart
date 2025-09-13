class Pet {
  final String id;
  final String name;
  final String description;
  final double staminaRegenBonus; // e.g. +0.05 means +5%

  const Pet({
    required this.id,
    required this.name,
    required this.description,
    required this.staminaRegenBonus,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'staminaRegenBonus': staminaRegenBonus,
      };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        staminaRegenBonus: (json['staminaRegenBonus'] as num).toDouble(),
      );

  static List<Pet> starterPets() => const [
        Pet(
          id: 'pet_fox',
          name: 'Fox',
          description: 'Clever companion. +5% stamina regen.',
          staminaRegenBonus: 0.05,
        ),
        Pet(
          id: 'pet_owl',
          name: 'Owl',
          description: 'Wise watcher. +5% stamina regen.',
          staminaRegenBonus: 0.05,
        ),
        Pet(
          id: 'pet_beetle',
          name: 'Beetle',
          description: 'Sturdy friend. +5% stamina regen.',
          staminaRegenBonus: 0.05,
        ),
      ];
}
