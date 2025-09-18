import 'package:flutter/material.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final IconData? icon;

  const StatBar({super.key, required this.label, required this.value, required this.max, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);
    final bg = Theme.of(context).colorScheme.onSurface.withOpacity(0.12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          if (icon != null) const SizedBox(width: 6),
          Text('$label: $value/$max', style: const TextStyle(color: Colors.white)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            color: color,
            backgroundColor: bg,
          ),
        ),
      ],
    );
  }
}
