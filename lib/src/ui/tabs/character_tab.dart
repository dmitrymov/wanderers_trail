import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/models/item_display_helpers.dart';
import '../../data/models/player_profile.dart';
import '../../state/game_state.dart';
import '../widgets/panel.dart';

class CharacterTab extends StatelessWidget {
  const CharacterTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.profile;
    final scheme = Theme.of(context).colorScheme;

    if (!gs.assetsReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'Hero',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        _HeroHeader(p: p),
        const SizedBox(height: 20),
        
        _SectionHeader(title: 'VITALS & GROWTH', color: scheme.primary),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            children: [
              _UpgradeRow(
                label: 'Health',
                value: '${p.health} / ${p.maxHealth}',
                progress: p.health / p.maxHealth,
                buttonLabel: gs.healthUpgradeCost.toString(),
                enabled: p.coins >= gs.healthUpgradeCost,
                onPressed: () => gs.upgradeHealth(),
                icon: Icons.favorite_rounded,
                iconColor: Colors.redAccent,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Colors.black12),
              ),
              _UpgradeRow(
                label: 'Stamina',
                value: '${p.stamina} / ${p.maxStamina}',
                progress: p.stamina / p.maxStamina,
                buttonLabel: gs.staminaUpgradeCost.toString(),
                enabled: p.coins >= gs.staminaUpgradeCost,
                onPressed: () => gs.upgradeStamina(),
                icon: Icons.bolt_rounded,
                iconColor: Colors.amberAccent,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Colors.black12),
              ),
              _UpgradeRow(
                label: 'Combat Speed',
                value: '${p.speedMultiplier.toStringAsFixed(1)}x',
                progress: p.speedMultiplier / 2.0,
                buttonLabel: gs.speedUpgradeCost.toString(),
                enabled: p.coins >= gs.speedUpgradeCost && gs.maxSpeedMultiplier < 2.0,
                onPressed: () => gs.upgradeSpeed(),
                icon: Icons.speed_rounded,
                iconColor: Colors.cyanAccent,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        _SectionHeader(title: 'EQUIPMENT', color: scheme.primary),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _EquipmentSlot(label: 'Weapon', item: p.weapon, icon: Icons.sports_martial_arts_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _EquipmentSlot(label: 'Armor', item: p.armor, icon: Icons.shield_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _EquipmentSlot(label: 'Ring', item: p.ring, icon: Icons.blur_circular_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _EquipmentSlot(label: 'Boots', item: p.boots, icon: Icons.directions_run_rounded)),
          ],
        ),

        const SizedBox(height: 24),
        _SectionHeader(title: 'COMBAT STATS', color: scheme.primary),
        const SizedBox(height: 12),
        _StatGrid(gs: gs),
        
        const SizedBox(height: 24),
        _SectionHeader(title: 'PREFERENCES', color: scheme.primary),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_fix_high_rounded, size: 18, color: Colors.black45),
                  const SizedBox(width: 8),
                  Text(
                    'Speed Multiplier: ${p.speedMultiplier.toStringAsFixed(1)}x',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1C1E)),
                  ),
                ],
              ),
              Slider(
                value: p.speedMultiplier,
                min: 0.1,
                max: gs.maxSpeedMultiplier,
                activeColor: scheme.primary,
                divisions: (gs.maxSpeedMultiplier * 10 - 1).round().clamp(1, 100),
                onChanged: (val) => context.read<GameState>().setSpeedMultiplier(val),
              ),
              const Text(
                'Adjust game pace. Higher limits unlocked in Shop.',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final PlayerProfile p;
  const _HeroHeader({required this.p});

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [Colors.cyanAccent.withValues(alpha: 0.2), Colors.transparent, Colors.cyanAccent.withValues(alpha: 0.2)],
              ),
              border: Border.all(color: Colors.black12, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.person_rounded, size: 40, color: Colors.black38),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE WANDERER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.cyanAccent.withValues(alpha: 0.7),
                  ),
                ),
                const Text(
                  'Survivor',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 6),
                      Text(
                        '${p.coins}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: color ?? const Color(0xFF44474E),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Colors.black12)),
      ],
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData icon;
  final Color iconColor;

  const _UpgradeRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.buttonLabel,
    required this.enabled,
    required this.onPressed,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1C1E))),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF42474E))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation(iconColor.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 32,
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: iconColor.withValues(alpha: 0.2),
              foregroundColor: iconColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.monetization_on_rounded, size: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EquipmentSlot extends StatelessWidget {
  final String label;
  final Item? item;
  final IconData icon;

  const _EquipmentSlot({required this.label, required this.item, required this.icon});

  @override
  Widget build(BuildContext context) {
    final hasItem = item != null;
    final color = hasItem ? Color(rarityColorValue(item!.rarity)) : Colors.white10;

    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.black38),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: hasItem 
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(item!.effectiveAssetPath, fit: BoxFit.contain,
                        errorBuilder: (c,e,s) => Icon(icon, color: color, size: 20),
                      ),
                    )
                  : Icon(icon, color: Colors.black12, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasItem ? item!.name : 'Empty',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: hasItem ? color : Colors.black26,
                      ),
                    ),
                    if (hasItem)
                      Text(
                        itemBaseStat(item!),
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final GameState gs;
  const _StatGrid({required this.gs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatBox(label: 'Attack', value: gs.statsSummary.attack.toString(), icon: Icons.flash_on_rounded, color: Colors.orangeAccent)),
            const SizedBox(width: 12),
            Expanded(child: _StatBox(label: 'Defense', value: gs.statsSummary.defense.toString(), icon: Icons.shield_rounded, color: Colors.blueAccent)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatBox(label: 'Interval', value: '${gs.statsSummary.attackMs}ms', icon: Icons.timer_rounded, color: Colors.greenAccent)),
            const SizedBox(width: 12),
            Expanded(child: _StatBox(label: 'DPS', value: gs.statsSummary.dps.toString(), icon: Icons.query_stats_rounded, color: Colors.purpleAccent)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatBox(label: 'Accuracy', value: '${(gs.statsSummary.accuracy * 100).round()}%', icon: Icons.center_focus_strong_rounded, color: Colors.tealAccent)),
            const SizedBox(width: 12),
            Expanded(child: _StatBox(label: 'Evasion', value: '${(gs.statsSummary.evasion * 100).round()}%', icon: Icons.waves_rounded, color: Colors.indigoAccent)),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w700)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
            ],
          ),
        ],
      ),
    );
  }
}
