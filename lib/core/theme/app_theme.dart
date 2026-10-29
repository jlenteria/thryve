import 'package:flutter/material.dart';

import '../motion/page_transitions.dart';
import 'app_colors.dart';

/// Builds Material 3 themes from [AppColorSchemes]. Both themes share one
/// builder so component styling can't drift between light and dark.
abstract final class AppTheme {
  /// Bundled in `assets/fonts/Geist` so the app renders correctly offline.
  static const String fontFamily = 'Geist';

  static ThemeData get light => _build(AppColorSchemes.light);

  static ThemeData get dark => _build(AppColorSchemes.dark);

  static ThemeData _build(ColorScheme colors) {
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: colors.outlineVariant.withValues(alpha: 0.6),
      ),
    );
    final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const TextStyle buttonText = TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      brightness: colors.brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: colors.surface,
      textTheme: _textTheme(colors),
      pageTransitionsTheme: thryvePageTransitions,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.primary,
        ),
        iconTheme: IconThemeData(color: colors.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.all(16),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colors) {
    TextStyle style(
      double size,
      FontWeight weight, {
      double? height,
      double letterSpacing = 0,
      Color? color,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? colors.onSurface,
    );

    return TextTheme(
      displayLarge: style(
        32,
        FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.64,
      ),
      displayMedium: style(
        26,
        FontWeight.w700,
        height: 1.23,
        letterSpacing: -0.52,
      ),
      displaySmall: style(
        24,
        FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      ),
      headlineLarge: style(26, FontWeight.w700, height: 1.25),
      headlineMedium: style(
        22,
        FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.22,
      ),
      headlineSmall: style(20, FontWeight.w600, height: 1.3),
      titleLarge: style(18, FontWeight.w600, height: 1.35),
      titleMedium: style(16, FontWeight.w600, height: 1.4),
      titleSmall: style(14, FontWeight.w600, height: 1.4),
      bodyLarge: style(18, FontWeight.w400, height: 1.55),
      bodyMedium: style(16, FontWeight.w400, height: 1.5),
      bodySmall: style(
        14,
        FontWeight.w400,
        height: 1.43,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: style(14, FontWeight.w600, letterSpacing: 0.1),
      labelMedium: style(
        12,
        FontWeight.w600,
        height: 1.33,
        letterSpacing: 0.6,
        color: colors.onSurfaceVariant,
      ),
      labelSmall: style(
        10,
        FontWeight.w600,
        letterSpacing: 0.5,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
