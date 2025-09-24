import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  Widget _upgradeTile({required String title, required String subtitle, required int cost, required VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onPressed,
            child: Text('Buy ($cost 💎)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    final healthLevel = gs.permHealthLevel;
    final staminaLevel = gs.permStaminaLevel;
    final attackLevel = gs.permAttackLevel;
    final defenseLevel = gs.permDefenseLevel;

    final healthBonus = healthLevel * GameState.permHealthStep;
    final staminaBonus = staminaLevel * GameState.permStaminaStep;

    final healthCost = gs.permanentUpgradeCost(PermanentUpgrade.health);
    final staminaCost = gs.permanentUpgradeCost(PermanentUpgrade.stamina);
    final attackCost = gs.permanentUpgradeCost(PermanentUpgrade.attack);
    final defenseCost = gs.permanentUpgradeCost(PermanentUpgrade.defense);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text('Shop', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const Text('💎', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text('${gs.diamonds}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Coins: ${gs.profile.coins}'),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton(
            onPressed: () => gs.addDiamonds(50),
            child: const Text('Add 50 Diamonds (test) 💎'),
          ),
        ),
        const Divider(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Permanent Upgrades (persist across runs)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        _upgradeTile(
          title: 'Max Health +${GameState.permHealthStep}',
          subtitle: 'Level $healthLevel • Permanent bonus: +$healthBonus',
          cost: healthCost,
          onPressed: gs.diamonds >= healthCost ? () => gs.purchasePermanent(PermanentUpgrade.health) : null,
        ),
        _upgradeTile(
          title: 'Max Stamina +${GameState.permStaminaStep}',
          subtitle: 'Level $staminaLevel • Permanent bonus: +$staminaBonus',
          cost: staminaCost,
          onPressed: gs.diamonds >= staminaCost ? () => gs.purchasePermanent(PermanentUpgrade.stamina) : null,
        ),
        _upgradeTile(
          title: 'Attack +${GameState.permAttackStep}',
          subtitle: 'Level $attackLevel • Applies to base attack',
          cost: attackCost,
          onPressed: gs.diamonds >= attackCost ? () => gs.purchasePermanent(PermanentUpgrade.attack) : null,
        ),
        _upgradeTile(
          title: 'Defense +${GameState.permDefenseStep}',
          subtitle: 'Level $defenseLevel • Applies to base defense',
          cost: defenseCost,
          onPressed: gs.diamonds >= defenseCost ? () => gs.purchasePermanent(PermanentUpgrade.defense) : null,
        ),
      ],
    );
  }
}
