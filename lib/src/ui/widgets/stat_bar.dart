import 'package:flutter/material.dart';

class StatBar extends StatefulWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final IconData? icon;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.icon,
  });

  @override
  State<StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<StatBar> with SingleTickerProviderStateMixin {
  late double _displayValue;
  late double _ghostValue;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value.toDouble();
    _ghostValue = widget.value.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _controller.addListener(() {
      setState(() {
        _ghostValue = widget.value + (1.0 - _controller.value) * (_displayValue - widget.value);
      });
    });
  }

  @override
  void didUpdateWidget(StatBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value < oldWidget.value) {
        // Decrease: Animate ghost
        _displayValue = oldWidget.value.toDouble();
        _controller.forward(from: 0.0);
      } else {
        // Increase: Snap ghost
        _displayValue = widget.value.toDouble();
        _ghostValue = widget.value.toDouble();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.value / widget.max).clamp(0.0, 1.0);
    final ghostPct = (_ghostValue / widget.max).clamp(0.0, 1.0);
    final bg = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          if (widget.icon != null)
            Icon(widget.icon, size: 14, color: widget.color),
          if (widget.icon != null) const SizedBox(width: 6),
          Text(
            '${widget.label}: ${widget.value}/${widget.max}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
        const SizedBox(height: 5),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Ghost bar (lagging behind)
            if (ghostPct > pct)
              FractionallySizedBox(
                widthFactor: ghostPct,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            // Primary bar
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
