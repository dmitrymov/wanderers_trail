import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';
import '../theme/tokens.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  Widget _upgradeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int cost,
    required VoidCallback? onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.gap16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Icon(Icons.trending_up, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: AppTokens.gap12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.gap8),
            FilledButton(
              onPressed: onPressed,
              child: Text('$cost 💎'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final scheme = Theme.of(context).colorScheme;

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('Shop', style: Theme.of(context).textTheme.titleLarge)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('💎', style: TextStyle(fontSize: 16, height: 1, color: scheme.onSecondaryContainer)),
                  const SizedBox(width: 6),
                  Text(
                    '${gs.diamonds}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Coins (this run): ${gs.profile.coins}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (kDebugMode) ...[
          const SizedBox(height: AppTokens.gap12),
          OutlinedButton.icon(
            onPressed: () => gs.addDiamonds(50),
            icon: const Icon(Icons.bug_report_outlined, size: 18),
            label: const Text('Add 50 diamonds (debug)'),
          ),
        ],
        const SizedBox(height: AppTokens.gap16),
        Text(
          'Permanent upgrades',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'These persist across new runs.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTokens.gap12),
        _upgradeCard(
          context,
          title: 'Max health +${GameState.permHealthStep}',
          subtitle: 'Level $healthLevel · bonus +$healthBonus',
          cost: healthCost,
          onPressed: gs.diamonds >= healthCost
              ? () => gs.purchasePermanent(PermanentUpgrade.health)
              : null,
        ),
        const SizedBox(height: AppTokens.gap8),
        _upgradeCard(
          context,
          title: 'Max stamina +${GameState.permStaminaStep}',
          subtitle: 'Level $staminaLevel · bonus +$staminaBonus',
          cost: staminaCost,
          onPressed: gs.diamonds >= staminaCost
              ? () => gs.purchasePermanent(PermanentUpgrade.stamina)
              : null,
        ),
        const SizedBox(height: AppTokens.gap8),
        _upgradeCard(
          context,
          title: 'Attack +${GameState.permAttackStep}',
          subtitle: 'Level $attackLevel · adds to base attack',
          cost: attackCost,
          onPressed: gs.diamonds >= attackCost
              ? () => gs.purchasePermanent(PermanentUpgrade.attack)
              : null,
        ),
        const SizedBox(height: AppTokens.gap8),
        _upgradeCard(
          context,
          title: 'Defense +${GameState.permDefenseStep}',
          subtitle: 'Level $defenseLevel · adds to base defense',
          cost: defenseCost,
          onPressed: gs.diamonds >= defenseCost
              ? () => gs.purchasePermanent(PermanentUpgrade.defense)
              : null,
        ),
        const SizedBox(height: AppTokens.gap8),
        _upgradeCard(
          context,
          title: 'Combat Speed +${GameState.permSpeedStep.toStringAsFixed(1)}x',
          subtitle: 'Level ${gs.profile.permSpeedLevel} · max speed limit',
          cost: gs.permanentUpgradeCost(PermanentUpgrade.speed),
          onPressed: gs.diamonds >= gs.permanentUpgradeCost(PermanentUpgrade.speed)
              ? () => gs.purchasePermanent(PermanentUpgrade.speed)
              : null,
        ),
      ],
    );
  }
}
