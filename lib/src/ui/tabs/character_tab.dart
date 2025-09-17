import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../state/game_state.dart';

class CharacterTab extends StatelessWidget {
  const CharacterTab({super.key});



  Color _rarityColor(ItemRarity? r) {
    switch (r) {
      case ItemRarity.uncommon:
        return Colors.green;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.legendary:
        return const Color(0xFFFFD700);
      case ItemRarity.mystic:
        return Colors.redAccent;
      case ItemRarity.normal:
      default:
        return Colors.white70;
    }
  }

  Widget _equipLine(String label, Item? item) {
    if (item == null) {
      return Text('$label: -');
    }
    final color = _rarityColor(item.rarity);
    // Build additional stat lines
    final extras = item.stats.entries.map((e) {
      final t = e.key;
      final v = e.value;
      String name;
      bool percent = false;
      switch (t) {
        case ItemStatType.attack:
          name = 'Attack';
          break;
        case ItemStatType.defense:
          name = 'Defense';
          break;
        case ItemStatType.accuracy:
          name = 'Accuracy';
          percent = true;
          break;
        case ItemStatType.agility:
          name = 'Agility';
          break;
        case ItemStatType.critChance:
          name = 'Crit Chance';
          percent = true;
          break;
        case ItemStatType.critDamage:
          name = 'Crit Damage';
          percent = true;
          break;
        case ItemStatType.health:
          name = 'Health';
          break;
        case ItemStatType.evasion:
          name = 'Evasion';
          percent = true;
          break;
        case ItemStatType.stamina:
          name = 'Stamina';
          break;
        case ItemStatType.staminaCostReduction:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
      final val = percent ? '+${(v * 100).toStringAsFixed(0)}%' : '+${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}';
      return '• $name $val';
    }).join('  ');

    final base = () {
      switch (item.type) {
        case ItemType.weapon:
          return 'Attack +${item.power}';
        case ItemType.armor:
          return 'Defense +${item.power}';
        case ItemType.ring:
          return 'Accuracy +${item.power}';
        case ItemType.boots:
          return 'Defense +${item.power}';
      }
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${item.name}', style: TextStyle(color: color)),
        Text(base, style: const TextStyle(fontSize: 12)),
        if (extras.isNotEmpty) Text(extras, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.profile;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Character', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Health: ${p.health}'),
            ElevatedButton(onPressed: gs.upgradeHealth, child: const Text('Upgrade')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Stamina: ${p.stamina}'),
            ElevatedButton(onPressed: gs.upgradeStamina, child: const Text('Upgrade')),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const Text('Equipment', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _equipLine('Weapon', p.weapon),
        _equipLine('Armor', p.armor),
        _equipLine('Ring', p.ring),
        _equipLine('Boots', p.boots),
        const SizedBox(height: 16),
        const Divider(),
        const Text('Computed Stats', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Attack: ${gs.statsSummary.attack}'),
        Text('Defense: ${gs.statsSummary.defense}'),
        Row(children: [
          const Icon(Icons.bolt, size: 16), const SizedBox(width: 6), Text('Attack Speed: ${gs.statsSummary.attackMs} ms')
        ]),
        Row(children: [
          const Icon(Icons.center_focus_weak, size: 16), const SizedBox(width: 6), Text('Accuracy: ${(gs.statsSummary.accuracy * 100).toStringAsFixed(0)}%')
        ]),
        Row(children: [
          const Icon(Icons.shield_moon, size: 16), const SizedBox(width: 6), Text('Evasion: ${(gs.statsSummary.evasion * 100).toStringAsFixed(0)}%')
        ]),
        Row(children: [
          const Icon(Icons.star, size: 16), const SizedBox(width: 6), Text('Crit Chance: ${(gs.statsSummary.critChance * 100).toStringAsFixed(1)}%')
        ]),
        Row(children: [
          const Icon(Icons.auto_graph, size: 16), const SizedBox(width: 6), Text('Crit Damage: +${(gs.statsSummary.critDamage * 100).toStringAsFixed(0)}%')
        ]),
        Text('DPS: ${gs.statsSummary.dps}'),
        const SizedBox(height: 16),
        const Divider(),
        Row(
          children: [
            const Text('High Score:'),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Highest step reached (best run)',
              child: Text('${p.highScore}'),
            ),
          ],
        ),
      ],
    );
  }
}
