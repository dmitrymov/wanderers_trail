import '../data/models/item.dart';

class StatsSummary {
  final int attack; // total base + weapon power + attack stat
  final int defense; // armor + boots + defense stat
  final double accuracy; // additional hit chance; final hit chance ~ 0.8 + accuracy
  final double evasion; // chance to evade enemy attacks
  final double critChance; // 0..1
  final double critDamage; // 0..inf, extra multiplier
  final int attackMs; // attack interval in ms
  final double dps; // expected DPS vs neutral target

  const StatsSummary({
    required this.attack,
    required this.defense,
    required this.accuracy,
    required this.evasion,
    required this.critChance,
    required this.critDamage,
    required this.attackMs,
    required this.dps,
  });

  static const int baseDamage = 5;

  static StatsSummary fromItems({Item? weapon, Item? armor, Item? ring, Item? boots}) {
    final items = [weapon, armor, ring, boots];
    double sum(ItemStatType t) {
      double acc = 0;
      for (final it in items) {
        if (it == null) continue;
        final v = it.stats[t];
        if (v != null) acc += v;
      }
      return acc;
    }

    final attack = baseDamage + (weapon?.power ?? 0) + sum(ItemStatType.attack).round();
    final defense = (armor?.power ?? 0) + (boots?.power ?? 0) + sum(ItemStatType.defense).round();

    final accuracy = sum(ItemStatType.accuracy); // add-on to base 0.8
    final evasion = sum(ItemStatType.evasion);
    final critChance = sum(ItemStatType.critChance);
    final critDamage = sum(ItemStatType.critDamage);

    final baseMs = 1000;
    final weaponMsBonus = (weapon == null ? 0 : weapon.power * 20);
    final agilityMsBonus = (sum(ItemStatType.agility) * 10).round();
    final int attackMs = ((baseMs - weaponMsBonus - agilityMsBonus).clamp(400, 2000)).toInt();

    // Expected hit chance and damage per hit
    final hitChance = (0.8 + accuracy).clamp(0.1, 0.98);
    final expectedPerHit = attack * (1 + critChance.clamp(0, 0.95) * critDamage);
    final hitsPerSecond = 1000.0 / attackMs;
    final dps = expectedPerHit * hitChance * hitsPerSecond;

    return StatsSummary(
      attack: attack,
      defense: defense,
      accuracy: accuracy,
      evasion: evasion,
      critChance: critChance,
      critDamage: critDamage,
      attackMs: attackMs,
      dps: double.parse(dps.toStringAsFixed(1)),
    );
  }
}
