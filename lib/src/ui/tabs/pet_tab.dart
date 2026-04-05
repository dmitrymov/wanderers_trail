import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/pet.dart';
import '../../state/game_state.dart';
import '../theme/tokens.dart';

class PetTab extends StatelessWidget {
  const PetTab({super.key});

  static List<Widget> _petBuffRows(BuildContext context, Pet pet) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.tertiary;
    TextStyle lineStyle() => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accent,
        );
    Widget line(IconData icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: lineStyle())),
          ],
        );
    final rows = <Widget>[];
    if (pet.staminaRegenBonus > 0) {
      rows.add(line(
        Icons.bolt,
        'Stamina regen +${(pet.staminaRegenBonus * 100).toStringAsFixed(0)}%',
      ));
    }
    if (pet.attackBonus > 0) {
      rows.add(line(Icons.flash_on, 'Attack +${pet.attackBonus}'));
    }
    if (pet.defenseBonus > 0) {
      rows.add(line(Icons.shield, 'Defense +${pet.defenseBonus}'));
    }
    if (pet.accuracyBonus > 0) {
      rows.add(line(
        Icons.center_focus_weak,
        'Accuracy +${(pet.accuracyBonus * 100).toStringAsFixed(0)}%',
      ));
    }
    if (pet.evasionBonus > 0) {
      rows.add(line(
        Icons.shuffle,
        'Evasion +${(pet.evasionBonus * 100).toStringAsFixed(0)}%',
      ));
    }
    if (pet.critChanceBonus > 0) {
      rows.add(line(
        Icons.star,
        'Crit chance +${(pet.critChanceBonus * 100).toStringAsFixed(0)}%',
      ));
    }
    if (pet.critDamageBonus > 0) {
      rows.add(line(
        Icons.auto_graph,
        'Crit damage +${(pet.critDamageBonus * 100).toStringAsFixed(0)}%',
      ));
    }
    return rows;
  }

  String _petEmoji(Pet pet) {
    final name = pet.name.toLowerCase();
    if (name.contains('fox')) return '🦊';
    if (name.contains('wolf')) return '🐺';
    if (name.contains('cat')) return '🐱';
    if (name.contains('dragon')) return '🐉';
    if (name.contains('bear')) return '🐻';
    if (name.contains('owl')) return '🦉';
    if (name.contains('rabbit') || name.contains('bunny')) return '🐰';
    if (name.contains('beetle')) return '🪲';
    if (name.contains('turtle')) return '🐢';
    const fallbacks = ['🐾', '🦎', '🐦', '🦋', '🐛'];
    return fallbacks[pet.id.codeUnitAt(0) % fallbacks.length];
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final pets = Pet.starterPets();
    final selected = gs.profile.selectedPetId;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Text('Companions', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            if (selected != null)
              Chip(
                avatar: Text(
                  _petEmoji(
                    pets.firstWhere((p) => p.id == selected,
                        orElse: () => pets.first),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                label: const Text('Active'),
                side: BorderSide(color: scheme.outlineVariant),
                backgroundColor: scheme.primaryContainer.withValues(alpha: 0.55),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Your companion grants passive bonuses during runs.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTokens.gap16),
        for (final pet in pets) ...[
          _PetCard(
            pet: pet,
            emoji: _petEmoji(pet),
            isSelected: selected == pet.id,
            onSelect: () => gs.selectPet(pet.id),
          ),
          const SizedBox(height: AppTokens.gap8),
        ],
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.emoji,
    required this.isSelected,
    required this.onSelect,
  });

  final Pet pet;
  final String emoji;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buffRows = PetTab._petBuffRows(context, pet);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSelected ? null : onSelect,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.gap16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: AppTokens.gap12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              pet.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle,
                                color: scheme.primary, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pet.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < buffRows.length; i++) ...[
                        buffRows[i],
                        if (i < buffRows.length - 1) const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.gap8),
                if (!isSelected)
                  FilledButton.tonal(
                    onPressed: onSelect,
                    child: const Text('Select'),
                  )
                else
                  Icon(Icons.pets, color: scheme.primary, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
