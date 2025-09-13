import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Shop', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Coins: ${gs.profile.coins}'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () {
              // Simple coin sink: buy random coins bundle (for demo only)
              gs.addCoins(10);
            },
            child: const Text('Buy Coins (+10)'),
          ),
        ),
      ],
    );
  }
}
