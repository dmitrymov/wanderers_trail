import 'package:flutter/material.dart';

enum MonsterType { slime, wolf, bandit, spider, skeleton, orc, ghost, demon }

class JourneyLevelConfig {
  final int levelId;
  final String name;
  final String description;
  final String backgroundAsset;
  /// Optional color tint applied in ColorFiltered to differentiate reused backgrounds
  final Color? backgroundTint;
  final List<MonsterType> allowedMonsters;
  final Color themeColor;
  /// Base difficulty offset applied to steps in this region
  final int difficultyOffset;

  const JourneyLevelConfig({
    required this.levelId,
    required this.name,
    required this.description,
    required this.backgroundAsset,
    this.backgroundTint,
    required this.allowedMonsters,
    required this.themeColor,
    required this.difficultyOffset,
  });

  // ── Curated levels ──────────────────────────────────────────────────────────

  static const List<JourneyLevelConfig> allLevels = [
    JourneyLevelConfig(
      levelId: 1,
      name: 'Slime Meadows',
      description:
          'A vibrant albeit slimy trail teeming with basic threats. Perfect for beginners.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg.png',
      allowedMonsters: [MonsterType.slime, MonsterType.wolf],
      themeColor: Colors.lightGreen,
      difficultyOffset: 0,
    ),
    JourneyLevelConfig(
      levelId: 2,
      name: 'Bandit Woods',
      description:
          'The dense canopy hides thieves and creeping things. Watch your pouches.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg1.png',
      allowedMonsters: [MonsterType.bandit, MonsterType.spider],
      themeColor: Colors.orange,
      difficultyOffset: 15,
    ),
    JourneyLevelConfig(
      levelId: 3,
      name: 'The Cursed Crypts',
      description: 'Ancient stones housing restless souls and hulking beasts.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg.png',
      backgroundTint: Color(0x4A6A0DAD), // purple tint
      allowedMonsters: [MonsterType.skeleton, MonsterType.orc, MonsterType.ghost],
      themeColor: Colors.deepPurple,
      difficultyOffset: 35,
    ),
    JourneyLevelConfig(
      levelId: 4,
      name: 'The Demon Spire',
      description: 'A crimson ascension leading to pure evil.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg1.png',
      backgroundTint: Color(0x55CC0000), // red tint
      allowedMonsters: [MonsterType.demon, MonsterType.skeleton, MonsterType.ghost],
      themeColor: Colors.redAccent,
      difficultyOffset: 60,
    ),
    JourneyLevelConfig(
      levelId: 5,
      name: 'Infernal Wastes',
      description:
          'Scorched lands where demons and spectres roam without mercy.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg.png',
      backgroundTint: Color(0x66FF4500), // deep orange tint
      allowedMonsters: [MonsterType.demon, MonsterType.ghost, MonsterType.orc],
      themeColor: Color(0xFFFF4500),
      difficultyOffset: 90,
    ),
    JourneyLevelConfig(
      levelId: 6,
      name: 'The Abyssal Hollow',
      description:
          'The air itself is poison. Only the most elite monsters thrive here.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg1.png',
      backgroundTint: Color(0x551A0030), // deep indigo tint
      allowedMonsters: [MonsterType.demon, MonsterType.ghost, MonsterType.skeleton, MonsterType.orc],
      themeColor: Color(0xFF4A148C),
      difficultyOffset: 125,
    ),
    JourneyLevelConfig(
      levelId: 7,
      name: 'Sovereign Ruins',
      description:
          'The crumbling throne of a fallen god, guarded by every nightmare you\'ve faced.',
      backgroundAsset: 'assets/images/backgrounds/battle_bg.png',
      backgroundTint: Color(0x440000CC), // blue-dark tint
      allowedMonsters: MonsterType.values, // all types
      themeColor: Color(0xFF0D47A1),
      difficultyOffset: 165,
    ),
    JourneyLevelConfig(
      levelId: 8,
      name: 'The Void Gate',
      description:
          'Nothing beyond this point has ever returned. This is the end — or is it?',
      backgroundAsset: 'assets/images/backgrounds/battle_bg1.png',
      backgroundTint: Color(0x77000000), // near-black tint
      allowedMonsters: MonsterType.values, // all types
      themeColor: Color(0xFF212121),
      difficultyOffset: 210,
    ),
  ];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the config for [id]. For levels beyond the curated list, auto-generates
  /// a config so the game never dead-ends after completing the last defined level.
  static JourneyLevelConfig getLevel(int id) {
    final found = allLevels.where((l) => l.levelId == id).firstOrNull;
    if (found != null) return found;

    // Auto-generate beyond the last curated level
    final cycle = (id - 1) % 2; // alternate the two backgrounds
    final bg = cycle == 0
        ? 'assets/images/backgrounds/battle_bg.png'
        : 'assets/images/backgrounds/battle_bg1.png';

    return JourneyLevelConfig(
      levelId: id,
      name: 'The Eternal Trial $id',
      description: 'Only legends survive Level $id. Every monster in existence roams here.',
      backgroundAsset: bg,
      backgroundTint: const Color(0x66000000),
      allowedMonsters: MonsterType.values,
      themeColor: Colors.blueGrey,
      difficultyOffset: 210 + (id - 8) * 50,
    );
  }

  static int get maxCuratedLevel => allLevels.last.levelId;
}
