import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Forest & clay" palette: warm parchment backgrounds, oxblood as the
/// primary accent, forest green as secondary, walnut brown as tertiary.
class AppColors {
  static const Color background = Color(0xFFF6F0E6); // parchment
  static const Color surface = Color(0xFFEDE3D3); // light tan
  static const Color surfaceHigh = Color(0xFFE4D7C3); // darker tan

  static const Color accent = Color(0xFF7B2D26); // oxblood
  static const Color accentLight = Color(0xFFF2DCD5); // oxblood tint
  static const Color forest = Color(0xFF3F5A43); // forest green
  static const Color forestLight = Color(0xFFDCE5D6); // forest tint
  static const Color walnut = Color(0xFF6B4F3A); // walnut brown

  static const Color textPrimary = Color(0xFF2B1D14); // espresso
  static const Color textSecondary = Color(0xFF6E5B4C);
  static const Color cardBorder = Color(0xFFD9CAB5);
  static const Color divider = Color(0xFFDDD0BD);
  static const Color error = Color(0xFFA33A2C);
  static const Color success = forest;
}

class AppTheme {
  /// Serif used for headings; body text stays in Nunito.
  static TextStyle display({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.lora(fontSize: fontSize, fontWeight: fontWeight, color: color);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
    ).copyWith(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accentLight,
      onPrimaryContainer: AppColors.accent,
      secondary: AppColors.forest,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.forestLight,
      onSecondaryContainer: AppColors.forest,
      tertiary: AppColors.walnut,
      onTertiary: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.background,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: AppColors.cardBorder,
      outlineVariant: AppColors.divider,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: display(fontSize: 30, fontWeight: FontWeight.w700),
        headlineSmall: display(fontSize: 24),
        titleLarge: display(fontSize: 20),
        titleMedium: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.nunito(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
        extendedTextStyle: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: display(fontSize: 22),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.walnut),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.walnut,
          side: const BorderSide(color: AppColors.walnut, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forest, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.forest),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.forest),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.forest,
        selectionColor: AppColors.forestLight,
        selectionHandleColor: AppColors.forest,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: display(fontSize: 20),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.nunito(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
