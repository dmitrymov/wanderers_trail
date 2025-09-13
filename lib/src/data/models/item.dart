import 'dart:math';

enum ItemType { weapon, armor, ring, boots }

class Item {
  final String id;
  final ItemType type;
  final String name;
  final int power; // generic power/bonus applied depending on type
  final int level;

  const Item({
    required this.id,
    required this.type,
    required this.name,
    required this.power,
    required this.level,
  });

  Item copyWith({
    String? id,
    ItemType? type,
    String? name,
    int? power,
    int? level,
  }) => Item(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        power: power ?? this.power,
        level: level ?? this.level,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'power': power,
        'level': level,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        type: ItemType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ItemType.weapon,
        ),
        name: json['name'] as String,
        power: (json['power'] as num).toInt(),
        level: (json['level'] as num?)?.toInt() ?? 1,
      );

  static Item randomDrop({required int runScore, required String Function() idGen}) {
    final rnd = Random();
    final roll = rnd.nextInt(4);
    final type = ItemType.values[roll];
    final level = (runScore ~/ 10) + 1; // scale slowly with score
    final basePower = 3 + rnd.nextInt(4) + level; // 4..something
    final name = _nameFor(type, level);
    return Item(
      id: idGen(),
      type: type,
      name: name,
      power: basePower,
      level: level,
    );
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
