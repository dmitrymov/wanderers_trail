import 'package:flutter/material.dart';

enum HeroClassRarity {
  simple,
  rare,
  epic,
  legendary;

  String get label {
    switch (this) {
      case HeroClassRarity.simple: return 'Simple';
      case HeroClassRarity.rare: return 'Rare';
      case HeroClassRarity.epic: return 'Epic';
      case HeroClassRarity.legendary: return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case HeroClassRarity.simple: return const Color(0xFF78909C); // Slate Blue-Grey
      case HeroClassRarity.rare: return const Color(0xFF1E88E5);   // Material Blue
      case HeroClassRarity.epic: return const Color(0xFF8E24AA);   // Material Purple
      case HeroClassRarity.legendary: return const Color(0xFFFFD700); // Gold
    }
  }
}

class ClassSkill {
  final String id;
  final String name;
  final String description;
  final int cooldownSec;
  final IconData icon;

  const ClassSkill({
    required this.id,
    required this.name,
    required this.description,
    this.cooldownSec = 10,
    required this.icon,
  });
}

class HeroClass {
  final String id;
  final String name;
  final String description;
  final String imageAsset;
  final HeroClassRarity rarity;
  final ClassSkill? skill;
  
  // Stat bonuses
  final int healthBonus;
  final int staminaBonus;
  final int attackBonus;
  final int defenseBonus;
  final double speedBonus; // Add-on to base multiplier
  final double critChanceBonus;
  final double critDamageBonus;
  
  // Unlocking
  final int coinCost;
  final int diamondCost;

  const HeroClass({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    this.rarity = HeroClassRarity.simple,
    this.skill,
    this.healthBonus = 0,
    this.staminaBonus = 0,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.speedBonus = 0.0,
    this.critChanceBonus = 0.0,
    this.critDamageBonus = 0.0,
    this.coinCost = 0,
    this.diamondCost = 0,
  });

  Color get rarityColor => rarity.color;
  String get icon => skill != null ? String.fromCharCode(skill!.icon.codePoint) : '❓';

  static List<HeroClass> allClasses() => [
    const HeroClass(
      id: 'survivor',
      name: 'Survivor',
      rarity: HeroClassRarity.simple,
      description: 'A resilient wanderer balanced in all paths. Finds extra survival supplies on the trail.',
      imageAsset: 'assets/images/classes/survivor.png',
      skill: ClassSkill(
        id: 'lucky_find',
        name: 'Scavenge',
        description: 'Passive: 15% chance to find bonus coins after every battle.',
        icon: Icons.auto_fix_high,
      ),
      healthBonus: 0,
    ),
    const HeroClass(
      id: 'warrior',
      name: 'Warrior',
      rarity: HeroClassRarity.simple,
      description: 'The Brawler. A rugged frontline fighter with boosted health and striking power.',
      imageAsset: 'assets/images/classes/warrior_v2.png',
      skill: ClassSkill(
        id: 'power_strike',
        name: 'Power Strike',
        description: 'Active: Deal 1.5x damage on your next hit.',
        cooldownSec: 10,
        icon: Icons.flash_on,
      ),
      healthBonus: 30,
      attackBonus: 3,
      defenseBonus: 2,
      coinCost: 200,
    ),
    const HeroClass(
      id: 'knight',
      name: 'Knight',
      rarity: HeroClassRarity.rare,
      description: 'The Noble Aegis. A plate-bound protector with ultimate defense and endurance.',
      imageAsset: 'assets/images/classes/warrior.png',
      skill: ClassSkill(
        id: 'iron_wall',
        name: 'Iron Wall',
        description: 'Active: Reduce all incoming damage by 75% for 5 seconds.',
        cooldownSec: 25,
        icon: Icons.shield,
      ),
      healthBonus: 60,
      defenseBonus: 8,
      coinCost: 500,
    ),
    const HeroClass(
      id: 'rogue',
      name: 'Rogue',
      rarity: HeroClassRarity.rare,
      description: 'The Shadow. Strike fast and strike true with boosted speed and critical chance.',
      imageAsset: 'assets/images/classes/rogue.png',
      skill: ClassSkill(
        id: 'shadow_strike',
        name: 'Shadow Strike',
        description: 'Active: Your next 3 hits are guaranteed critical strikes.',
        cooldownSec: 20,
        icon: Icons.visibility_off,
      ),
      speedBonus: 0.25,
      critChanceBonus: 0.15,
      coinCost: 800,
      diamondCost: 10,
    ),
    const HeroClass(
      id: 'mage',
      name: 'Mage',
      rarity: HeroClassRarity.rare,
      description: 'The Pyro. Use elemental fire to burn enemies over time.',
      imageAsset: 'assets/images/classes/mage.png',
      skill: ClassSkill(
        id: 'fireball',
        name: 'Fireball',
        description: 'Active: Deal 2x damage and Burn the enemy for 5 seconds.',
        cooldownSec: 15,
        icon: Icons.local_fire_department,
      ),
      attackBonus: 10,
      staminaBonus: 20,
      coinCost: 1200,
      diamondCost: 15,
    ),
    const HeroClass(
      id: 'archmage',
      name: 'Archmage',
      rarity: HeroClassRarity.epic,
      description: 'The Celestial. Unleash massive arcane bursts that shatter enemy defenses.',
      imageAsset: 'assets/images/classes/archmage.png',
      skill: ClassSkill(
        id: 'arcane_burst',
        name: 'Arcane Burst',
        description: 'Active: Deal 5x weapon damage and apply Shatter (50% bonus damage) for 5s.',
        cooldownSec: 35,
        icon: Icons.auto_awesome,
      ),
      attackBonus: 25,
      staminaBonus: 50,
      coinCost: 5000,
      diamondCost: 50,
    ),
    const HeroClass(
      id: 'berserker',
      name: 'Berserker',
      rarity: HeroClassRarity.epic,
      description: 'The Untamed. Trading defense for raw destructive power and brutal crits.',
      imageAsset: 'assets/images/classes/berserker.png',
      skill: ClassSkill(
        id: 'bloodlust',
        name: 'Bloodlust',
        description: 'Active: Gain 50% Attack Speed and 25% Lifesteal for 8 seconds.',
        cooldownSec: 45,
        icon: Icons.favorite,
      ),
      attackBonus: 15,
      defenseBonus: -8,
      critDamageBonus: 0.4,
      diamondCost: 60,
    ),
    const HeroClass(
      id: 'paladin',
      name: 'Paladin',
      rarity: HeroClassRarity.legendary,
      description: 'The Divine Shield. A beacon of light with impenetrable defense and holy healing.',
      imageAsset: 'assets/images/classes/paladin.png',
      skill: ClassSkill(
        id: 'holy_aegis',
        name: 'Holy Aegis',
        description: 'Active: Grant 5s Invulnerability and heal 30% of Max HP.',
        cooldownSec: 50,
        icon: Icons.health_and_safety,
      ),
      healthBonus: 150,
      defenseBonus: 20,
      diamondCost: 150,
    ),
    const HeroClass(
      id: 'assassin',
      name: 'Assassin',
      rarity: HeroClassRarity.legendary,
      description: 'The Executioner. Perfectly lethal strikes that end battles instantly.',
      imageAsset: 'assets/images/classes/assassin.png',
      skill: ClassSkill(
        id: 'execution',
        name: 'Execution',
        description: 'Active: Hit for 8x damage and apply massive Bleed. Kills if health is below 25%.',
        cooldownSec: 40,
        icon: Icons.gps_fixed,
      ),
      speedBonus: 0.5,
      critChanceBonus: 0.3,
      critDamageBonus: 1.0,
      diamondCost: 200,
    ),
  ];

  static HeroClass get(String id) {
    return allClasses().firstWhere((c) => c.id == id, orElse: () => allClasses().first);
  }
}
