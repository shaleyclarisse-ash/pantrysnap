import 'package:flutter/material.dart';

/// Design system inspired by Alma (Nutrition Coach): warm, calm, and
/// "no ads or shame" rather than clinical. Soft cream backgrounds, a
/// sage-green primary (ties back to the PantrySnap logo), a warm
/// terracotta accent, generously rounded cards, and gentle shadows
/// instead of hard borders.
///
/// Because nearly every screen in this app already reads its colors and
/// text styles from Theme.of(context) rather than hardcoding them,
/// swapping this theme in restyles almost the whole app at once.
class AppTheme {
  AppTheme._();

  // --- Brand palette ---
  static const _sage = Color(0xFF5B8C5A);
  static const _sageLight = Color(0xFF8FC08D);
  static const _sageContainerLight = Color(0xFFDCEBD9);
  static const _sageContainerDark = Color(0xFF2C4A30);
  static const _terracotta = Color(0xFFE8A26B); // warm accent for highlights
  static const _terracottaContainerLight = Color(0xFFFBE3CC);
  static const _terracottaContainerDark = Color(0xFF5A3F26);

  static const _creamBackground = Color(0xFFFBF7F1);
  static const _creamSurfaceVariant = Color(0xFFF1EAE0);
  static const _warmCharcoal = Color(0xFF2B2A27);

  static const _darkBackground = Color(0xFF201F1C);
  static const _darkSurfaceVariant = Color(0xFF33312B);
  static const _warmCream = Color(0xFFEDE8DE);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _sage,
      brightness: Brightness.light,
    ).copyWith(
      primary: _sage,
      primaryContainer: _sageContainerLight,
      onPrimaryContainer: const Color(0xFF1E3620),
      secondary: _terracotta,
      secondaryContainer: _terracottaContainerLight,
      onSecondaryContainer: const Color(0xFF4A2F14),
      tertiary: _terracotta,
      surface: _creamBackground,
      surfaceContainerHighest: _creamSurfaceVariant,
      onSurface: _warmCharcoal,
      onSurfaceVariant: _warmCharcoal.withOpacity(0.65),
      outlineVariant: const Color(0xFFE3DCCF),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _sage,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _sageLight,
      primaryContainer: _sageContainerDark,
      onPrimaryContainer: const Color(0xFFCFE8CD),
      secondary: _terracotta,
      secondaryContainer: _terracottaContainerDark,
      onSecondaryContainer: const Color(0xFFFBE3CC),
      tertiary: _terracotta,
      surface: _darkBackground,
      surfaceContainerHighest: _darkSurfaceVariant,
      onSurface: _warmCream,
      onSurfaceVariant: _warmCream.withOpacity(0.65),
      outlineVariant: const Color(0xFF433F37),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          height: 1.4,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),

      // Soft, generously-rounded cards with a gentle shadow instead of a
      // hard outline - the "calm, no ads or shame" feel.
      cardTheme: CardThemeData(
        color: colorScheme.brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerHighest,
        elevation: 0,
        shadowColor: colorScheme.primary.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),

      // Pill-shaped filled buttons.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // Soft pill filter/choice chips, like Alma's meal-type/macro pills.
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.6),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),

      iconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }
}