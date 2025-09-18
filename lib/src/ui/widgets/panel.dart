import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(AppTokens.gap12), this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        // Dark scrim-style background for reliable contrast on bright scenes
        color: Colors.black.withOpacity(AppTokens.panelOpacity),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
