import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../core/stats.dart';
import '../../state/game_state.dart';

class ItemDropPopup extends StatelessWidget {
  final Item item;
  final VoidCallback onEquip;
  const ItemDropPopup({super.key, required this.item, required this.onEquip});

  Color _rarityColor(ItemRarity r) {
    switch (r) {
      case ItemRarity.normal:
        return Colors.grey;
      case ItemRarity.uncommon:
        return Colors.green;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.legendary:
        return const Color(0xFFFFD700); // gold
      case ItemRarity.mystic:
        return Colors.redAccent;
    }
  }

  String _baseLine(Item i) {
    switch (i.type) {
      case ItemType.weapon:
        return 'Attack +${i.power}';
      case ItemType.armor:
        return 'Defense +${i.power}';
      case ItemType.ring:
        return 'Accuracy +${i.power}';
      case ItemType.boots:
        return 'Defense +${i.power}';
    }
  }

  String _statLine(ItemStatType t, double v) {
    String label;
    bool percent = false;
    switch (t) {
      case ItemStatType.attack:
        label = 'Attack';
        break;
      case ItemStatType.defense:
        label = 'Defense';
        break;
      case ItemStatType.accuracy:
        label = 'Accuracy';
        percent = true;
        break;
      case ItemStatType.agility:
        label = 'Agility';
        break;
      case ItemStatType.critChance:
        label = 'Crit Chance';
        percent = true;
        break;
      case ItemStatType.critDamage:
        label = 'Crit Damage';
        percent = true;
        break;
      case ItemStatType.health:
        label = 'Health';
        break;
      case ItemStatType.evasion:
        label = 'Evasion';
        percent = true;
        break;
      case ItemStatType.stamina:
        label = 'Stamina';
        break;
      case ItemStatType.staminaCostReduction:
        label = 'Stamina Cost Reduction';
        percent = true;
        break;
    }
    return percent ? '$label +${(v * 100).toStringAsFixed(0)}%'
        : '$label +${v.toStringAsFixed((v % 1 == 0) ? 0 : 2)}';
  }
  Color _deltaColor(num delta, {bool higherIsBetter = true}) {
    final good = higherIsBetter ? delta > 0 : delta < 0;
    final bad = higherIsBetter ? delta < 0 : delta > 0;
    if (good) return Colors.green;
    if (bad) return Colors.redAccent;
    return Colors.white70;
  }

  Text _deltaText(String label, num before, num after, {bool percent = false, bool higherIsBetter = true}) {
    final delta = after - before;
    final unit = percent ? '%' : '';
    String fmt(num v) => percent ? v.toStringAsFixed(0) : v.toStringAsFixed((v % 1 == 0) ? 0 : 1);
    final color = _deltaColor(delta, higherIsBetter: higherIsBetter);
    return Text(
      '$label: ${fmt(before)}$unit → ${fmt(after)}$unit (${delta >= 0 ? '+' : ''}${fmt(delta)}$unit)',
      style: TextStyle(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(item.rarity);
    final statEntries = item.stats.entries.toList();

    final gs = context.read<GameState>();
    final p = gs.profile;

    // Current and candidate summaries
    final current = StatsSummary.fromItems(
      weapon: p.weapon,
      armor: p.armor,
      ring: p.ring,
      boots: p.boots,
    );
    final cand = StatsSummary.fromItems(
      weapon: item.type == ItemType.weapon ? item : p.weapon,
      armor: item.type == ItemType.armor ? item : p.armor,
      ring: item.type == ItemType.ring ? item : p.ring,
      boots: item.type == ItemType.boots ? item : p.boots,
    );

    return AlertDialog(
      title: const Text('Item Found!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Type: ${item.type.name}') ,
          const SizedBox(height: 8),
          Text(_baseLine(item)),
          if (statEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Additional Stats:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final e in statEntries)
              Text('• ${_statLine(e.key, e.value)}'),
          ],
          const SizedBox(height: 12),
          const Text('Before → After (Δ)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _deltaText('Attack', current.attack, cand.attack),
          _deltaText('Defense', current.defense, cand.defense),
          _deltaText('Accuracy', current.accuracy * 100, cand.accuracy * 100, percent: true),
          _deltaText('Evasion', current.evasion * 100, cand.evasion * 100, percent: true),
          _deltaText('Crit Chance', current.critChance * 100, cand.critChance * 100, percent: true),
          _deltaText('Crit Damage', current.critDamage * 100, cand.critDamage * 100, percent: true),
          _deltaText('Attack Speed (ms)', current.attackMs, cand.attackMs, higherIsBetter: false),
          _deltaText('DPS', current.dps, cand.dps),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Discard'),
        ),
        ElevatedButton(
          onPressed: () {
            onEquip();
            Navigator.of(context).pop();
          },
          child: const Text('Equip'),
        )
      ],
    );
  }
}
