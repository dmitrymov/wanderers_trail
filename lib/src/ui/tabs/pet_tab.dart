import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/pet.dart';
import '../../state/game_state.dart';
import '../theme/tokens.dart';

class PetTab extends StatelessWidget {
  const PetTab({super.key});

  String _petEmoji(Pet pet) {
    final name = pet.name.toLowerCase();
    if (name.contains('fox')) return '🦊';
    if (name.contains('wolf')) return '🐺';
    if (name.contains('cat')) return '🐱';
    if (name.contains('dragon')) return '🐉';
    if (name.contains('bear')) return '🐻';
    if (name.contains('owl')) return '🦉';
    if (name.contains('rabbit') || name.contains('bunny')) return '🐰';
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
    final regenPct = (pet.staminaRegenBonus * 100).toStringAsFixed(0);

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
                      Row(
                        children: [
                          Icon(Icons.bolt, size: 16, color: scheme.tertiary),
                          const SizedBox(width: 6),
                          Text(
                            'Stamina regen +$regenPct%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.tertiary,
                            ),
                          ),
                        ],
                      ),
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
