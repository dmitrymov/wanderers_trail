import 'dart:math';
import 'package:flutter/material.dart';

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
  staminaCostReduction, // 0..1 percentage reducing stamina cost per step
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

  Color get rarityColor {
    switch (rarity) {
      case ItemRarity.normal:
        return Color(0xFF9E9E9E); // Grey
      case ItemRarity.uncommon:
        return Color(0xFF4CAF50); // Green
      case ItemRarity.rare:
        return Color(0xFF2196F3); // Blue
      case ItemRarity.legendary:
        return Color(0xFFFFD700); // Gold
      case ItemRarity.mystic:
        return Color(0xFFFF5252); // Red
    }
  }

  String get effectiveAssetPath {
    // Priority 0: Explicit full paths (e.g. from heroicDrop)
    if (imageAsset != null && imageAsset!.startsWith('assets/')) {
      return imageAsset!;
    }

    final t = type.toString().split('.').last;
    String folder;
    if (t == 'weapon') {
      folder = 'weapons';
    } else if (t == 'ring') {
      folder = 'rings';
    } else {
      folder = t; // armor, boots
    }

    final ext = 'png';
    final code = _rarityDigit(rarity);

    // Use a stable seed based on the item ID so the graphics don't "flicker" on every rebuild.
    final Random seededRnd = Random(id.hashCode);

    // For weapons, if we don't have a specific imageAsset assigned at creation time,
    // or if the saved one is old, re-roll a valid path STABLY.
    if (t == 'weapon') {
      return _weaponImagePath(rarity, seededRnd);
    }

    // New armor_41 is PNG, others are webp
    if (t == 'armor' && code == '4') return 'assets/images/armor/armor_41.png';

    // Everyone else uses Digit1 (e.g. boots_41.png, ring_01.png)
    return 'assets/images/$folder/${t}_${code}1.$ext';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString().split('.').last,
    'name': name,
    'power': power,
    'level': level,
    'rarity': rarity.toString().split('.').last,
    'stats': stats.map((k, v) => MapEntry(k.toString().split('.').last, v)),
    // No longer saving 'image' here as it's computed dynamically
  };

  factory Item.fromJson(Map<String, dynamic> json) {
    final rarityStr = json['rarity'] as String?;
    final statsJson = json['stats'] as Map<String, dynamic>?;
    final stats = <ItemStatType, double>{};
    if (statsJson != null) {
      for (final e in statsJson.entries) {
        final t = ItemStatType.values.firstWhere(
          (x) => x.toString().split('.').last == e.key,
          orElse: () => ItemStatType.attack,
        );
        stats[t] = (e.value as num).toDouble();
      }
    }
    return Item(
      id: json['id'] as String,
      type: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ItemType.weapon,
      ),
      name: json['name'] as String,
      power: (json['power'] as num).toInt(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      rarity:
          rarityStr == null
              ? ItemRarity.normal
              : ItemRarity.values.firstWhere(
                (r) => r.toString().split('.').last == rarityStr,
                orElse: () => ItemRarity.normal,
              ),
      stats: stats,
      // We still read the field if it exists for backward compatibility during transitions,
      // but effectiveAssetPath will now ignore invalid ones.
      imageAsset: json['image'] as String?,
    );
  }

  static Item randomDrop({
    required int runScore,
    required String Function() idGen,
  }) {
    final rnd = Random();
    final roll = rnd.nextInt(4);
    final type = ItemType.values[roll];
    final level = (runScore ~/ 10) + 1; // scale slowly with score

    // Determine rarity
    final rarity = _rollRarity(rnd);

    // Base values by type
    int basePower;
    String baseName;
    String? category;
    switch (type) {
      case ItemType.weapon:
        basePower = 4 + rnd.nextInt(4) + level; // attack
        final cats = ['dagger', 'sword', 'axe', 'mace', 'bow', 'staff'];
        category = cats[rnd.nextInt(cats.length)];
        baseName = switch (category) {
          'dagger' => 'Trail Dirk',
          'sword' => 'Shortsword',
          'axe' => 'Hand Axe',
          'mace' => 'Heavy Mace',
          'bow' => 'Short Bow',
          'staff' => 'Old Staff',
          _ => 'Trail Blade',
        };
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
    final rarityPrefix = _rarityPrefix(rarity);

    // If it's a weapon, maybe vary the base name slightly by rarity for flavor
    if (type == ItemType.weapon && category != null) {
      if (rarity == ItemRarity.rare) {
        baseName = switch (category) {
          'dagger' => 'Stiletto',
          'sword' => 'Longsword',
          'axe' => 'Battle Axe',
          'mace' => 'War Hammer',
          'bow' => 'Longbow',
          'staff' => 'Magic Staff',
          _ => baseName,
        };
      } else if (rarity == ItemRarity.legendary) {
        baseName = switch (category) {
          'dagger' => 'Shadow Edge',
          'sword' => 'Excalibur',
          'axe' => 'Executioner',
          'mace' => 'Dragon Smasher',
          'bow' => 'Heartseeker',
          'staff' => 'Archmage Pillar',
          _ => baseName,
        };
      } else if (rarity == ItemRarity.mystic) {
        baseName = switch (category) {
          'dagger' => 'Astral Shard',
          'sword' => 'Celestial Blade',
          'axe' => 'Eternal Edge',
          'mace' => 'Grand Smasher',
          'bow' => 'Ethereal String',
          'staff' => 'Cosmic Pillar',
          _ => baseName,
        };
      }
    } else {
      // Non-weapon Mystic names
      if (rarity == ItemRarity.mystic) {
        baseName = switch (type) {
          ItemType.armor => 'Aegis of Light',
          ItemType.ring => 'Omega Band',
          ItemType.boots => 'Seven-League Steps',
          _ => baseName,
        };
      } else if (rarity == ItemRarity.legendary) {
        baseName = switch (type) {
          ItemType.armor => 'Dragon Plate',
          ItemType.ring => 'Sovereign Signet',
          ItemType.boots => 'Winged Greaves',
          _ => baseName,
        };
      }
    }

    final name = '$rarityPrefix$baseName +$level';
    final image = _itemImagePath(type, rarity, rnd, weaponCategory: category);

    return Item(
      id: idGen(),
      type: type,
      name: name,
      power: basePower,
      level: level,
      rarity: rarity,
      stats: stats,
      imageAsset: image,
    );
  }

  /// Generate a permanent "Heroic Relic" for the Shop chests.
  /// These are visually distinct from Journey gear.
  static Item heroicDrop({
    required ItemRarity rarity,
    required String Function() idGen,
  }) {
    final rnd = Random();
    final typeRoll = rnd.nextInt(4);
    final type = ItemType.values[typeRoll];

    // Heroic items start at a higher baseline baseline
    // Level is fixed at 1 for new purchases, but rarity provides core power.
    final level = 1;
    final powerBoost = switch (rarity) {
      ItemRarity.normal => 5,
      ItemRarity.uncommon => 8,
      ItemRarity.rare => 12,
      ItemRarity.legendary => 20,
      ItemRarity.mystic => 35,
    };

    String name;
    String image;
    int power;

    switch (type) {
      case ItemType.weapon:
        power = 10 + powerBoost;
        final weapons = [
          ('Celestial Blade', 'celestial_blade.png'),
          ('Void Shard', 'void_shard.png'),
          ('Archon Staff', 'archon_staff.png'),
          ('Dragon Smasher', 'dragon_smasher.png'),
        ];
        final w = weapons[rnd.nextInt(weapons.length)];
        name = w.$1;
        image = 'assets/images/relics/${w.$2}';
        break;
      case ItemType.armor:
        power = 8 + powerBoost;
        final armors = [
          ('Paladin Soul-Plate', 'soulplate.png'),
          ('Elder\'s Weave', 'elders_weave.png'),
        ];
        final a = armors[rnd.nextInt(armors.length)];
        name = a.$1;
        image = 'assets/images/relics/${a.$2}';
        break;
      case ItemType.ring:
        power = 5 + powerBoost;
        name = 'Eye of Ra';
        image = 'assets/images/relics/eye_of_ra.png';
        break;
      case ItemType.boots:
        power = 6 + powerBoost;
        name = 'Hermes\' Swift-Steps';
        image = 'assets/images/relics/hermes_steps.png';
        break;
    }

    // Add high-end heroic prefixes
    final prefix = switch (rarity) {
      ItemRarity.normal => 'Imperial ',
      ItemRarity.uncommon => 'Ancient ',
      ItemRarity.rare => 'Sovereign ',
      ItemRarity.legendary => 'Eternal ',
      ItemRarity.mystic => 'Ancestral ',
    };

    final stats = _rollAdditionalStats(
      type,
      rarity,
      5,
      rnd,
    ); // Roll as if level 5 for better stats

    return Item(
      id: idGen(),
      type: type,
      name: '$prefix$name',
      power: power,
      level: level,
      rarity: rarity,
      stats: stats,
      imageAsset: image,
    );
  }

  static String _rarityDigit(ItemRarity r) {
    switch (r) {
      case ItemRarity.normal:
        return '0';
      case ItemRarity.uncommon:
        return '1';
      case ItemRarity.rare:
        return '2';
      case ItemRarity.legendary:
        return '3';
      case ItemRarity.mystic:
        return '4';
    }
  }

  static String? _itemImagePath(
    ItemType type,
    ItemRarity rarity,
    Random rnd, {
    String? weaponCategory,
  }) {
    switch (type) {
      case ItemType.weapon:
        return _weaponImagePath(rarity, rnd, weaponCategory: weaponCategory);
      case ItemType.armor:
        return _armorImagePath(rarity, rnd);
      case ItemType.ring:
        return _ringImagePath(rarity, rnd);
      case ItemType.boots:
        return _bootsImagePath(rarity, rnd);
    }
  }

  // Choose a weapon sprite path like assets/images/weapons/dagger_21.png
  static String _weaponImagePath(
    ItemRarity rarity,
    Random rnd, {
    String? weaponCategory,
  }) {
    final cat = weaponCategory ?? 'sword';
    final rarityCode = switch (rarity) {
      ItemRarity.normal => '0',
      ItemRarity.uncommon => '1',
      ItemRarity.rare => '2',
      ItemRarity.legendary => '3',
      ItemRarity.mystic => '3', // Fallback to 3 since 4 doesn't exist yet
    };

    // For non-dagger weapons, safe-guard them based on known assets
    if (cat == 'axe' || cat == 'bow') {
      return 'assets/images/weapons/${cat}_31.png';
    } else if (cat == 'staff') {
      if (rarityCode == '0' || rarityCode == '1')
        return 'assets/images/weapons/staff_01.png';
      return 'assets/images/weapons/staff_31.png';
    } else if (cat == 'mace' || cat == 'sword') {
      return 'assets/images/weapons/${cat}_${rarityCode}1.png';
    }

    // Default: dagger logic
    int variantId = 1;
    if (cat == 'dagger') {
      if (rarityCode == '0') {
        variantId = 1 + rnd.nextInt(6);
      } else if (rarityCode == '1') {
        variantId = 1 + rnd.nextInt(2);
      } else if (rarityCode == '2') {
        variantId = 1 + rnd.nextInt(3);
      } else if (rarityCode == '3') {
        variantId = 1 + rnd.nextInt(2);
      }
    }

    return 'assets/images/weapons/${cat}_$rarityCode$variantId.png';
  }

  static String _armorImagePath(ItemRarity rarity, Random rnd) {
    final rarityCode = _rarityDigit(rarity);
    if (rarityCode == '4') return 'assets/images/armor/armor_41.png';
    return 'assets/images/armor/armor_${rarityCode}1.png';
  }

  static String _ringImagePath(ItemRarity rarity, Random rnd) {
    final rarityCode = _rarityDigit(rarity);
    return 'assets/images/rings/ring_${rarityCode}1.png';
  }

  static String _bootsImagePath(ItemRarity rarity, Random rnd) {
    final rarityCode = _rarityDigit(rarity);
    return 'assets/images/boots/boots_${rarityCode}1.png';
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
    ItemType type,
    ItemRarity rarity,
    int level,
    Random rnd,
  ) {
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
          ItemStatType.staminaCostReduction,
        ];
    }
  }

  static double _rollStatValue(
    ItemStatType t,
    int level,
    Random rnd,
    ItemRarity rarity,
  ) {
    final scale = 1 + level * 0.2;
    double baseMin, baseMax;
    switch (t) {
      case ItemStatType.attack:
        baseMin = 1;
        baseMax = 3;
        break;
      case ItemStatType.defense:
        baseMin = 1;
        baseMax = 3;
        break;
      case ItemStatType.accuracy:
        baseMin = 0.02;
        baseMax = 0.05; // +2%..+5%
        break;
      case ItemStatType.agility:
        baseMin = 1;
        baseMax = 4; // points -> ms reduction later
        break;
      case ItemStatType.critChance:
        baseMin = 0.02;
        baseMax = 0.06; // 2%..6%
        break;
      case ItemStatType.critDamage:
        baseMin = 0.10;
        baseMax = 0.25; // +10%..+25%
        break;
      case ItemStatType.health:
        baseMin = 5;
        baseMax = 15;
        break;
      case ItemStatType.evasion:
        baseMin = 0.01;
        baseMax = 0.04; // 1%..4%
        break;
      case ItemStatType.stamina:
        baseMin = 5;
        baseMax = 10;
        break;
      case ItemStatType.staminaCostReduction:
        baseMin = 0.03;
        baseMax = 0.10; // 3%..10% base, scales with rarity/level
        break;
    }
    // Rarity scaling
    final rarityMul = switch (rarity) {
      ItemRarity.normal => 1.0,
      ItemRarity.uncommon => 1.15,
      ItemRarity.rare => 1.35,
      ItemRarity.legendary => 1.65,
      ItemRarity.mystic => 2.25,
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

  // Adds specific flavor text for high-rarity items
  static String? flavorText(ItemRarity r, Random rnd) {
    if (r == ItemRarity.mystic) {
      final flavors = [
        'A shimmering artifact from beyond the stars.',
        'It hums with a power that bends the very air around it.',
        'Forged in the heart of a dying sun.',
        'Once held by the First Wanderer.',
        'It feels weightless, yet strikes with infinite force.',
      ];
      return flavors[rnd.nextInt(flavors.length)];
    }
    return null;
  }
}
