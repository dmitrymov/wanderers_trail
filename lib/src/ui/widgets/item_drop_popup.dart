import 'package:flutter/material.dart';

import '../../data/models/item.dart';

class ItemDropPopup extends StatelessWidget {
  final Item item;
  final VoidCallback onEquip;
  const ItemDropPopup({super.key, required this.item, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Item Found!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name),
          const SizedBox(height: 8),
          Text('Type: ${item.type.name}')
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Discard'),
        ),
        ElevatedButton(
          onPressed: () {
            onEquip();
            Navigator.of(context).pop();
          },
          child: const Text('Equip'),
        )
      ],
    );
  }
}
