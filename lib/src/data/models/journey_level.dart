import 'package:flutter/material.dart';

enum MonsterType { slime, wolf, bandit, spider, skeleton, orc, ghost, demon }

class JourneyLevelConfig {
  final int levelId;
  final String name;
  final String description;
  final String backgroundAsset;
  final List<MonsterType> allowedMonsters;
  final Color themeColor;

  const JourneyLevelConfig({
    required this.levelId,
    required this.name,
    required this.description,
    required this.backgroundAsset,
    required this.allowedMonsters,
    required this.themeColor,
  });

  static const List<JourneyLevelConfig> allLevels = [
    JourneyLevelConfig(
      levelId: 1,
      name: 'Slime Meadows',
      description: 'A vibrant albeit slimy trail teeming with basic threats. Perfect for beginners.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg.png',
      allowedMonsters: [MonsterType.slime, MonsterType.wolf],
      themeColor: Colors.lightGreen,
    ),
    JourneyLevelConfig(
      levelId: 2,
      name: 'Bandit Woods',
      description: 'The dense canopy hides thieves and creeping things. Watch your pouches.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg1.png',
      allowedMonsters: [MonsterType.bandit, MonsterType.spider],
      themeColor: Colors.orange,
    ),
    JourneyLevelConfig(
      levelId: 3,
      name: 'The Cursed Crypts',
      description: 'Ancient stones housing restless souls and hulking beasts.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg.png',
      allowedMonsters: [MonsterType.skeleton, MonsterType.orc, MonsterType.ghost],
      themeColor: Colors.deepPurple,
    ),
    JourneyLevelConfig(
      levelId: 4,
      name: 'The Demon Spire',
      description: 'A crimson ascension leading to pure evil.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg1.png',
      allowedMonsters: [MonsterType.demon, MonsterType.skeleton, MonsterType.ghost],
      themeColor: Colors.redAccent,
    ),
  ];

  static JourneyLevelConfig getLevel(int id) {
    return allLevels.firstWhere(
      (l) => l.levelId == id,
      orElse: () => allLevels.last,
    );
  }
}
