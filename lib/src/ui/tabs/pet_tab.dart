import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/pet.dart';
import '../../state/game_state.dart';

class PetTab extends StatelessWidget {
  const PetTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final pets = Pet.starterPets();
    final selected = gs.profile.selectedPetId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Pet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        for (final pet in pets)
          Card(
            child: ListTile(
              title: Text(pet.name),
              subtitle: Text(pet.description),
              trailing: selected == pet.id
                  ? const Icon(Icons.check, color: Colors.green)
                  : ElevatedButton(
                      onPressed: () => gs.selectPet(pet.id),
                      child: const Text('Select'),
                    ),
            ),
          ),
      ],
    );
  }
}
