import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/models/item_display_helpers.dart';
import '../../state/game_state.dart';
import '../theme/tokens.dart';

class CharacterTab extends StatelessWidget {
  const CharacterTab({super.key});

  Widget _equipLine(BuildContext context, String label, Item? item) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);
    final subtle = scheme.onSurface.withValues(alpha: 0.45);

    if (item == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text('$label: —', style: TextStyle(color: subtle, fontSize: 14)),
      );
    }
    final color = Color(rarityColorValue(item.rarity));
    final base = itemBaseStat(item);
    final extras = item.stats.entries
        .map((e) => '• ${formatStatEntry(e.key, e.value)}')
        .join('  ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${item.name}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(base, style: TextStyle(fontSize: 13, color: muted)),
          if (extras.isNotEmpty)
            Text(extras, style: TextStyle(fontSize: 12, color: subtle)),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.gap16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.profile;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.7);

    if (!gs.assetsReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Character', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _sectionCard(
          context,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 22, color: scheme.primary),
                const SizedBox(width: 10),
                Text('Wallet', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Icon(Icons.monetization_on, color: Colors.amber.shade600, size: 22),
                const SizedBox(width: 6),
                Text(
                  '${p.coins}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.gap16),
            _upgradeRow(
              context,
              label: 'Health',
              value: '${p.health}/${p.maxHealth}',
              buttonLabel:
                  'Upgrade +${GameState.healthUpgradeStep} (${gs.healthUpgradeCost}🪙)',
              enabled: p.coins >= gs.healthUpgradeCost,
              onPressed: () => gs.upgradeHealth(),
            ),
            const SizedBox(height: AppTokens.gap12),
            _upgradeRow(
              context,
              label: 'Stamina',
              value: '${p.stamina}/${p.maxStamina}',
              buttonLabel:
                  'Upgrade +${GameState.staminaUpgradeStep} (${gs.staminaUpgradeCost}🪙)',
              enabled: p.coins >= gs.staminaUpgradeCost,
              onPressed: () => gs.upgradeStamina(),
            ),
            const SizedBox(height: AppTokens.gap12),
            _upgradeRow(
              context,
              label: 'Combat Speed',
              value: '${p.speedMultiplier.toStringAsFixed(1)}x / ${gs.maxSpeedMultiplier.toStringAsFixed(1)}x',
              buttonLabel:
                  'Upgrade +${GameState.speedUpgradeStep} (${gs.speedUpgradeCost}🪙)',
              enabled: p.coins >= gs.speedUpgradeCost && gs.maxSpeedMultiplier < 2.0,
              onPressed: () => gs.upgradeSpeed(),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.gap12),
        _sectionCard(
          context,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 22, color: scheme.primary),
                const SizedBox(width: 10),
                Text('Equipment', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap items in battle to inspect stats.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const Divider(height: AppTokens.gap24),
            _equipLine(context, 'Weapon', p.weapon),
            _equipLine(context, 'Armor', p.armor),
            _equipLine(context, 'Ring', p.ring),
            _equipLine(context, 'Boots', p.boots),
          ],
        ),
        const SizedBox(height: AppTokens.gap12),
        if (gs.selectedPet != null) ...[
          _sectionCard(
            context,
            children: [
              Row(
                children: [
                  Icon(Icons.pets, size: 22, color: scheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Companion',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                gs.selectedPet!.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gs.selectedPet!.description,
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.gap12),
        ],
        _sectionCard(
          context,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, size: 22, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Combat summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.gap12),
            _statRow(context, Icons.flash_on, 'Attack', '${gs.statsSummary.attack}'),
            _statRow(context, Icons.shield, 'Defense', '${gs.statsSummary.defense}'),
            _statRow(
              context,
              Icons.speed,
              'Attack speed',
              '${gs.statsSummary.attackMs} ms',
            ),
            _statRow(
              context,
              Icons.center_focus_weak,
              'Accuracy',
              '${(gs.statsSummary.accuracy * 100).toStringAsFixed(0)}%',
            ),
            _statRow(
              context,
              Icons.shield_moon,
              'Evasion',
              '${(gs.statsSummary.evasion * 100).toStringAsFixed(0)}%',
            ),
            _statRow(
              context,
              Icons.star,
              'Crit chance',
              '${(gs.statsSummary.critChance * 100).toStringAsFixed(1)}%',
            ),
            _statRow(
              context,
              Icons.auto_graph,
              'Crit damage',
              '+${(gs.statsSummary.critDamage * 100).toStringAsFixed(0)}%',
            ),
            _statRow(context, Icons.bar_chart, 'DPS', '${gs.statsSummary.dps}'),
          ],
        ),
        const SizedBox(height: AppTokens.gap12),
        _sectionCard(
          context,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    color: Colors.amber.shade700, size: 22),
                const SizedBox(width: 10),
                Text('Progress', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTokens.gap8),
            Row(
              children: [
                Text('High score (best step)', style: TextStyle(color: muted)),
                const Spacer(),
                Tooltip(
                  message: 'Highest step reached on any run',
                  child: Text(
                    '${p.highScore}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTokens.gap12),
        _sectionCard(
          context,
          children: [
            Row(
              children: [
                Icon(Icons.speed, size: 22, color: scheme.primary),
                const SizedBox(width: 10),
                Text('Combat speed', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTokens.gap8),
            Row(
              children: [
                Text('Speed multiplier', style: TextStyle(color: muted)),
                const Spacer(),
                Text(
                  '${p.speedMultiplier.toStringAsFixed(1)}x',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Slider(
              value: p.speedMultiplier,
              min: 0.1,
              max: gs.maxSpeedMultiplier,
              divisions: (gs.maxSpeedMultiplier * 10 - 1).round(),
              label: '${p.speedMultiplier.toStringAsFixed(1)}x',
              onChanged: (val) {
                context.read<GameState>().setSpeedMultiplier(val);
              },
            ),
            Text(
              'Upgrade "Combat Speed" above to increase this limit.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _upgradeRow(
    BuildContext context, {
    required String label,
    required String value,
    required String buttonLabel,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.gap8),
        Flexible(
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            child: Text(buttonLabel, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  Widget _statRow(BuildContext context, IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
