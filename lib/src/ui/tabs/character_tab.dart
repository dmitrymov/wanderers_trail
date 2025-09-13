import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';

class CharacterTab extends StatelessWidget {
  const CharacterTab({super.key});

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
        Text('Weapon: ${p.weapon?.name ?? '-'} (+${p.weapon?.power ?? 0})'),
        Text('Armor: ${p.armor?.name ?? '-'} (+${p.armor?.power ?? 0})'),
        Text('Ring: ${p.ring?.name ?? '-'} (+${p.ring?.power ?? 0})'),
        Text('Boots: ${p.boots?.name ?? '-'} (+${p.boots?.power ?? 0})'),
        const SizedBox(height: 16),
        const Divider(),
        Text('High Score: ${p.highScore}'),
      ],
    );
  }
}
