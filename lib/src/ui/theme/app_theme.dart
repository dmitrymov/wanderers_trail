import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final baseScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00BFA5), // Vibrant Teal
    brightness: brightness,
  );

  final scheme = baseScheme.copyWith(
    primary: const Color(0xFF00897B), // Deeper Teal for light contrast
    surface: isDark ? const Color(0xFF080A0D) : const Color(0xFFFBFDFB),
    surfaceContainerHighest:
        isDark ? const Color(0xFF12161B) : const Color(0xFFF1F4F1),
    onSurface: isDark ? Colors.white : const Color(0xFF1D1B20),
    onSurfaceVariant: isDark ? Colors.white70 : const Color(0xFF49454F),
  );

  final onMuted = scheme.onSurface.withValues(alpha: 0.85);
  final onSubtle = scheme.onSurface.withValues(alpha: 0.65);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: 16, height: 1.35, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: scheme.onSurface),
      bodySmall: TextStyle(fontSize: 12, height: 1.3, color: onMuted),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: scheme.onPrimaryContainer,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.65),
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: scheme.onSecondaryContainer,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 12,
        color: onMuted,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      textColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(color: onMuted, fontSize: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, AppTokens.minButtonHeight),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.gap16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppTokens.minButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.gap16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppTokens.minButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.gap16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      indicatorColor: scheme.primary.withValues(alpha: 0.12),
      backgroundColor: scheme.surface.withValues(alpha: 0.85),
      surfaceTintColor: scheme.surface,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          letterSpacing: 0.4,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected ? scheme.primary : onSubtle,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 26,
          color: selected ? scheme.primary : onSubtle,
        );
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor:
          scheme.surfaceContainerHighest.withValues(alpha: 0.98),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
    ),
  );
}
