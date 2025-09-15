import 'dart:math';

enum ItemType { weapon, armor, ring, boots }

enum ItemRarity { normal, uncommon, rare, legendary, mystic }

enum ItemStatType {
  attack, // weapon base
  defense, // armor/boots base
  accuracy, // ring base
  agility, // affects attack speed
  critChance, // 0..1
  critDamage, // 0..1 extra damage multiplier
  health, // +max health maybe used later
  evasion, // 0..1 chance to dodge
  stamina, // max stamina bonus maybe used later
}

class Item {
  final String id;
  final ItemType type;
  final String name;
  final int power; // base value depending on type
  final int level;
  final ItemRarity rarity;
  final Map<ItemStatType, double> stats; // additional stats beyond base
  final String? imageAsset; // optional asset path for icon/sprite

  const Item({
    required this.id,
    required this.type,
    required this.name,
    required this.power,
    required this.level,
    required this.rarity,
    this.stats = const {},
    this.imageAsset,
  });

  Item copyWith({
    String? id,
    ItemType? type,
    String? name,
    int? power,
    int? level,
    ItemRarity? rarity,
    Map<ItemStatType, double>? stats,
    String? imageAsset,
  }) => Item(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        power: power ?? this.power,
        level: level ?? this.level,
        rarity: rarity ?? this.rarity,
        stats: stats ?? this.stats,
        imageAsset: imageAsset ?? this.imageAsset,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'power': power,
        'level': level,
        'rarity': rarity.name,
        'stats': stats.map((k, v) => MapEntry(k.name, v)),
        'image': imageAsset,
      };

  factory Item.fromJson(Map<String, dynamic> json) {
    final rarityStr = json['rarity'] as String?;
    final statsJson = json['stats'] as Map<String, dynamic>?;
    final stats = <ItemStatType, double>{};
    if (statsJson != null) {
      for (final e in statsJson.entries) {
        final t = ItemStatType.values.firstWhere(
          (x) => x.name == e.key,
          orElse: () => ItemStatType.attack,
        );
        stats[t] = (e.value as num).toDouble();
      }
    }
    return Item(
      id: json['id'] as String,
      type: ItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ItemType.weapon,
      ),
      name: json['name'] as String,
      power: (json['power'] as num).toInt(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      rarity: rarityStr == null
          ? ItemRarity.normal
          : ItemRarity.values.firstWhere(
              (r) => r.name == rarityStr,
              orElse: () => ItemRarity.normal,
            ),
      stats: stats,
      imageAsset: json['image'] as String?,
    );
  }

  static Item randomDrop({required int runScore, required String Function() idGen}) {
    final rnd = Random();
    final roll = rnd.nextInt(4);
    final type = ItemType.values[roll];
    final level = (runScore ~/ 10) + 1; // scale slowly with score

    // Determine rarity
    final rarity = _rollRarity(rnd);

    // Base values by type
    int basePower;
    String baseName;
    switch (type) {
      case ItemType.weapon:
        basePower = 4 + rnd.nextInt(4) + level; // attack
        baseName = 'Trail Blade';
        break;
      case ItemType.armor:
        basePower = 3 + rnd.nextInt(3) + level; // defense
        baseName = 'Scout Armor';
        break;
      case ItemType.ring:
        basePower = 3 + rnd.nextInt(3) + (level ~/ 2); // accuracy points
        baseName = 'Seeker Ring';
        break;
      case ItemType.boots:
        basePower = 2 + rnd.nextInt(3) + level; // defense
        baseName = 'Runner Boots';
        break;
    }

    final stats = _rollAdditionalStats(type, rarity, level, rnd);
    final name = _rarityPrefix(rarity) + baseName + ' +' + level.toString();
    return Item(
      id: idGen(),
      type: type,
      name: name,
      power: basePower,
      level: level,
      rarity: rarity,
      stats: stats,
    );
  }

  static ItemRarity _rollRarity(Random rnd) {
    final p = rnd.nextDouble();
    if (p < 0.60) return ItemRarity.normal;
    if (p < 0.85) return ItemRarity.uncommon;
    if (p < 0.96) return ItemRarity.rare;
    if (p < 0.995) return ItemRarity.legendary;
    return ItemRarity.mystic;
  }

  static Map<ItemStatType, double> _rollAdditionalStats(
      ItemType type, ItemRarity rarity, int level, Random rnd) {
    int extra = switch (rarity) {
      ItemRarity.normal => 0,
      ItemRarity.uncommon => 1,
      ItemRarity.rare => 2,
      ItemRarity.legendary => 3,
      ItemRarity.mystic => 4,
    };
    final pool = _statPoolFor(type);
    final stats = <ItemStatType, double>{};
    for (int i = 0; i < extra && pool.isNotEmpty; i++) {
      final idx = rnd.nextInt(pool.length);
      final stat = pool.removeAt(idx);
      stats[stat] = _rollStatValue(stat, level, rnd, rarity);
    }
    return stats;
  }

  static List<ItemStatType> _statPoolFor(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return [
          ItemStatType.accuracy,
          ItemStatType.agility,
          ItemStatType.critChance,
          ItemStatType.critDamage,
        ];
      case ItemType.armor:
        return [
          ItemStatType.defense,
          ItemStatType.health,
          ItemStatType.evasion,
        ];
      case ItemType.ring:
        return [
          ItemStatType.accuracy,
          ItemStatType.critChance,
          ItemStatType.critDamage,
          ItemStatType.agility,
        ];
      case ItemType.boots:
        return [
          ItemStatType.agility,
          ItemStatType.evasion,
          ItemStatType.defense,
          ItemStatType.stamina,
        ];
    }
  }

  static double _rollStatValue(
      ItemStatType t, int level, Random rnd, ItemRarity rarity) {
    final scale = 1 + level * 0.2;
    double baseMin, baseMax;
    switch (t) {
      case ItemStatType.attack:
        baseMin = 1; baseMax = 3;
        break;
      case ItemStatType.defense:
        baseMin = 1; baseMax = 3;
        break;
      case ItemStatType.accuracy:
        baseMin = 0.02; baseMax = 0.05; // +2%..+5%
        break;
      case ItemStatType.agility:
        baseMin = 1; baseMax = 4; // points -> ms reduction later
        break;
      case ItemStatType.critChance:
        baseMin = 0.02; baseMax = 0.06; // 2%..6%
        break;
      case ItemStatType.critDamage:
        baseMin = 0.10; baseMax = 0.25; // +10%..+25%
        break;
      case ItemStatType.health:
        baseMin = 5; baseMax = 15;
        break;
      case ItemStatType.evasion:
        baseMin = 0.01; baseMax = 0.04; // 1%..4%
        break;
      case ItemStatType.stamina:
        baseMin = 5; baseMax = 10;
        break;
    }
    // Rarity scaling
    final rarityMul = switch (rarity) {
      ItemRarity.normal => 1.0,
      ItemRarity.uncommon => 1.1,
      ItemRarity.rare => 1.25,
      ItemRarity.legendary => 1.5,
      ItemRarity.mystic => 1.8,
    };
    final v = baseMin + rnd.nextDouble() * (baseMax - baseMin);
    return double.parse((v * rarityMul * scale).toStringAsFixed(2));
  }

  static String _rarityPrefix(ItemRarity r) {
    switch (r) {
      case ItemRarity.normal:
        return '';
      case ItemRarity.uncommon:
        return 'Uncommon ';
      case ItemRarity.rare:
        return 'Rare ';
      case ItemRarity.legendary:
        return 'Legendary ';
      case ItemRarity.mystic:
        return 'Mystic ';
    }
  }

  static String _nameFor(ItemType type, int level) {
    switch (type) {
      case ItemType.weapon:
        return 'Rusty Blade +$level';
      case ItemType.armor:
        return 'Worn Plate +$level';
      case ItemType.ring:
        return 'Traveler Ring +$level';
      case ItemType.boots:
        return 'Road Boots +$level';
    }
  }
}
