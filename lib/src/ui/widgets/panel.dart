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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        // Frosted Glass: White tint at tokens.panelOpacity
        color: Colors.white.withValues(alpha: AppTokens.panelOpacity),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.24) 
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppTokens.glassBlur, sigmaY: AppTokens.glassBlur),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
