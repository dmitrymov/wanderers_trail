import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/models/item_display_helpers.dart';
import '../../data/models/player_profile.dart';
import '../../state/game_state.dart';
import '../../data/models/hero_class.dart';
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
        InkWell(
          onTap: () => _showClassSelector(context, gs),
          borderRadius: BorderRadius.circular(24),
          child: _HeroHeader(p: p, heroClass: gs.selectedClass),
        ),
        const SizedBox(height: 20),
        
        _SectionHeader(title: 'VITALS & GROWTH', color: scheme.primary),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            children: [
              _UpgradeRow(
                label: 'Health',
                value: '${p.health} / ${gs.totalMaxHealth}',
                progress: (p.health / gs.totalMaxHealth).clamp(0.0, 1.0),
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
                value: '${p.stamina} / ${gs.totalMaxStamina}',
                progress: (p.stamina / gs.totalMaxStamina).clamp(0.0, 1.0),
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
            Expanded(
              child: _EquipmentSlot(
                label: 'Weapon',
                item: p.weapon,
                icon: Icons.sports_martial_arts_rounded,
                onTap: () => _showRelicPicker(context, gs, ItemType.weapon),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EquipmentSlot(
                label: 'Armor',
                item: p.armor,
                icon: Icons.shield_rounded,
                onTap: () => _showRelicPicker(context, gs, ItemType.armor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EquipmentSlot(
                label: 'Ring',
                item: p.ring,
                icon: Icons.blur_circular_rounded,
                onTap: () => _showRelicPicker(context, gs, ItemType.ring),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EquipmentSlot(
                label: 'Boots',
                item: p.boots,
                icon: Icons.directions_run_rounded,
                onTap: () => _showRelicPicker(context, gs, ItemType.boots),
              ),
            ),
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
  void _showClassSelector(BuildContext context, GameState gs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ClassSelectorSheet(gs: gs),
    );
  }

  void _showRelicPicker(BuildContext context, GameState gs, ItemType type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RelicPickerSheet(gs: gs, type: type),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final PlayerProfile p;
  final HeroClass heroClass;
  const _HeroHeader({required this.p, required this.heroClass});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary.withValues(alpha: 0.1), width: 2),
              boxShadow: [
                BoxShadow(color: scheme.primary.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: ClipOval(
              child: Image.asset(heroClass.imageAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEGENDARY HERO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: scheme.primary.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  heroClass.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.stars_rounded, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'UNLOCKED CLASSES: ${p.unlockedClassIds.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: scheme.primary),
        ],
      ),
    );
  }
}

class _ClassSelectorSheet extends StatelessWidget {
  final GameState gs;
  const _ClassSelectorSheet({required this.gs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final classes = HeroClass.allClasses();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose Your Path',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each class grants permanent stat bonuses.',
            style: TextStyle(color: Colors.black45),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = classes[i];
                final isUnlocked = gs.profile.unlockedClassIds.contains(c.id);
                final isSelected = gs.profile.selectedClassId == c.id;

                return InkWell(
                  onTap: isUnlocked ? () {
                    gs.selectClass(c.id);
                    Navigator.pop(context);
                  } : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? scheme.primary : (isUnlocked ? Colors.black12 : Colors.black.withValues(alpha: 0.05)),
                        width: 2,
                      ),
                      color: isSelected ? scheme.primary.withValues(alpha: 0.05) : (isUnlocked ? Colors.transparent : Colors.black.withValues(alpha: 0.02)),
                    ),
                    child: Row(
                      children: [
                        Opacity(
                          opacity: isUnlocked ? 1.0 : 0.4,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(c.imageAsset, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isUnlocked ? const Color(0xFF1A1C1E) : Colors.black38,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isUnlocked)
                                    Icon(Icons.lock_rounded, size: 14, color: Colors.black26),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _ClassBonusesRow(heroClass: c, isUnlocked: isUnlocked),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: scheme.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          if (classes.any((c) => !gs.profile.unlockedClassIds.contains(c.id)))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // In a real app we might switch tabs, but here we just prompt them
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visit the Shop to unlock more classes!')),
                );
              },
              child: Text('How to unlock more?', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _ClassBonusesRow extends StatelessWidget {
  final HeroClass heroClass;
  final bool isUnlocked;
  const _ClassBonusesRow({required this.heroClass, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [];
    final color = isUnlocked ? const Color(0xFF1D1B20) : Colors.black26;

    if (heroClass.healthBonus != 0) chips.add(_bonusText('HP', heroClass.healthBonus, color));
    if (heroClass.staminaBonus != 0) chips.add(_bonusText('STM', heroClass.staminaBonus, color));
    if (heroClass.attackBonus != 0) chips.add(_bonusText('ATK', heroClass.attackBonus, color));
    if (heroClass.defenseBonus != 0) chips.add(_bonusText('DEF', heroClass.defenseBonus, color));
    if (heroClass.speedBonus != 0) chips.add(_bonusText('SPD', heroClass.speedBonus, color, isMultiplier: true));
    if (heroClass.critChanceBonus != 0) chips.add(_bonusText('CRT', heroClass.critChanceBonus, color, isPercent: true));

    if (chips.isEmpty) {
      return const Text('Standard adventurer stats.', style: TextStyle(fontSize: 12, color: Colors.black45));
    }

    return Wrap(
      spacing: 8,
      children: chips,
    );
  }

  Widget _bonusText(String label, num value, Color color, {bool isMultiplier = false, bool isPercent = false}) {
    final sign = value > 0 ? '+' : '';
    final valStr = isMultiplier ? '${value.toStringAsFixed(1)}x' : (isPercent ? '${(value * 100).toInt()}%' : value.toString());
    return Text(
      '$label: $sign$valStr',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
  final VoidCallback? onTap;

  const _EquipmentSlot({required this.label, required this.item, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasItem = item != null;
    final color = hasItem ? Color(rarityColorValue(item!.rarity)) : Colors.black12;

    return Panel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: Colors.black38),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45)),
                  const Spacer(),
                  const Icon(Icons.swap_horiz_rounded, size: 12, color: Colors.black12),
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
        ),
      ),
    );
  }
}

class _RelicPickerSheet extends StatelessWidget {
  final GameState gs;
  final ItemType type;
  const _RelicPickerSheet({required this.gs, required this.type});

  @override
  Widget build(BuildContext context) {
    final relics = gs.profile.relics.where((r) => r.type == type).toList()
      ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
    
    final typeName = switch (type) {
      ItemType.weapon => 'Weapon',
      ItemType.armor => 'Armor',
      ItemType.ring => 'Ring',
      ItemType.boots => 'Boots',
    };

    final currentSlot = switch (type) {
      ItemType.weapon => gs.profile.weapon,
      ItemType.armor => gs.profile.armor,
      ItemType.ring => gs.profile.ring,
      ItemType.boots => gs.profile.boots,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SELECT ${typeName.toUpperCase()} RELIC',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.black38,
            ),
          ),
          const SizedBox(height: 16),
          if (relics.isEmpty)
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 40),
               child: Text('No relics found. Open chests in the Shop!', style: TextStyle(color: Colors.black26)),
             )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: relics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = relics[index];
                  final isEquipped = currentSlot?.id == r.id;
                  final rColor = Color(rarityColorValue(r.rarity));

                  return Panel(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () {
                        gs.equipRelic(r);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: isEquipped ? Border.all(color: rColor, width: 2) : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: rColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(r.effectiveAssetPath, fit: BoxFit.contain,
                                  errorBuilder: (c,e,s) => Icon(Icons.help_outline, color: rColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: rColor)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${itemBaseStat(r)} • ${r.rarity.name.toUpperCase()}',
                                    style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            if (isEquipped)
                              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back'),
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
