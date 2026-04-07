import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/pet.dart';
import '../../state/game_state.dart';
import '../widgets/panel.dart';

class PetTab extends StatelessWidget {
  const PetTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final pets = Pet.starterPets();
    final selectedId = gs.profile.selectedPetId;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'Pets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'YOUR COMPANIONS', color: scheme.primary),
        const SizedBox(height: 8),
        Text(
          'Choose a loyal companion to join your journey. Each grants unique passive blessings.',
          style: TextStyle(fontSize: 12, color: const Color(0xFF44474E), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        for (final pet in pets) ...[
          _PetSelectionCard(
            pet: pet,
            isSelected: selectedId == pet.id,
            onSelect: () => gs.selectPet(pet.id),
          ),
          const SizedBox(height: 12),
        ],
      ],
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

class _PetSelectionCard extends StatelessWidget {
  final Pet pet;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PetSelectionCard({
    required this.pet,
    required this.isSelected,
    required this.onSelect,
  });

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
    return '🐾';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final traits = _getPetTraits(pet);

    return AnimatedScale(
      scale: isSelected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: isSelected ? null : onSelect,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: Panel(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PetAvatar(emoji: _petEmoji(pet), isSelected: isSelected),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            pet.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            color: isSelected ? scheme.primary : const Color(0xFF191C1B),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF00897B)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pet.description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF44474E)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: traits.map((t) => _TraitTag(trait: t)).toList(),
                      ),
                    ],
                  ),
                ),
                if (!isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.radio_button_off_rounded, color: Colors.black12, size: 20),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.pets_rounded, color: scheme.primary, size: 24),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_PetTrait> _getPetTraits(Pet pet) {
    final list = <_PetTrait>[];
    if (pet.attackBonus > 0) list.add(_PetTrait('ATK +${pet.attackBonus}', Colors.orangeAccent, Icons.flash_on_rounded));
    if (pet.defenseBonus > 0) list.add(_PetTrait('DEF +${pet.defenseBonus}', Colors.blueAccent, Icons.shield_rounded));
    if (pet.staminaRegenBonus > 0) list.add(_PetTrait('STM +${(pet.staminaRegenBonus * 100).round()}%', Colors.amberAccent, Icons.bolt_rounded));
    if (pet.accuracyBonus > 0) list.add(_PetTrait('ACC +${(pet.accuracyBonus * 100).round()}%', Colors.tealAccent, Icons.center_focus_strong_rounded));
    if (pet.evasionBonus > 0) list.add(_PetTrait('EVA +${(pet.evasionBonus * 100).round()}%', Colors.indigoAccent, Icons.waves_rounded));
    if (pet.critChanceBonus > 0) list.add(_PetTrait('CRT ${(pet.critChanceBonus * 100).round()}%', Colors.redAccent, Icons.star_rounded));
    return list;
  }
}

class _PetAvatar extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  const _PetAvatar({required this.emoji, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF00897B).withValues(alpha: 0.5) : Colors.black12,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 32)),
    );
  }
}

class _PetTrait {
  final String label;
  final Color color;
  final IconData icon;
  _PetTrait(this.label, this.color, this.icon);
}

class _TraitTag extends StatelessWidget {
  final _PetTrait trait;
  const _TraitTag({required this.trait});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trait.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: trait.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trait.icon, size: 10, color: trait.color),
          const SizedBox(width: 4),
          Text(
            trait.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: trait.color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
