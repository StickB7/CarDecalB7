import 'package:flutter/material.dart';

/// Premium dark theme with gold accents for a secure, luxury feel.
class AppTheme {
  AppTheme._();

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF0D0D0F);
  static const Color surface        = Color(0xFF1A1A1F);
  static const Color surfaceVariant = Color(0xFF252530);
  static const Color border         = Color(0xFF2E2E3A);

  static const Color gold           = Color(0xFFD4AF37);
  static const Color goldLight      = Color(0xFFE8C84A);
  static const Color goldDim        = Color(0xFF8A7224);

  static const Color textPrimary    = Color(0xFFF0EFE9);
  static const Color textSecondary  = Color(0xFF9190A0);
  static const Color textTertiary   = Color(0xFF5C5B6A);

  static const Color success        = Color(0xFF4CAF82);
  static const Color error          = Color(0xFFCF6679);
  static const Color warning        = Color(0xFFF5A623);

  // ── Gradients ──────────────────────────────────────────────────────────────

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0D0F), Color(0xFF12121A)],
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
  );

  // ── ThemeData ──────────────────────────────────────────────────────────────

  static ThemeData get dark {
    return ThemeData(
      useMaterial3:     true,
      brightness:       Brightness.dark,
      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.dark(
        primary:           gold,
        onPrimary:         Color(0xFF1A1600),
        secondary:         goldLight,
        onSecondary:       Color(0xFF1A1600),
        surface:           surface,
        onSurface:         textPrimary,
        surfaceContainerHighest: surfaceVariant,
        error:             error,
        onError:           background,
      ),

      // Typography – system default, overridden per-widget where needed
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: textPrimary,   fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: TextStyle(color: textPrimary,   fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: textPrimary,   fontWeight: FontWeight.w700, fontSize: 28),
        headlineMedium:TextStyle(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 22),
        titleLarge:    TextStyle(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium:   TextStyle(color: textPrimary,   fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge:     TextStyle(color: textPrimary,   fontSize: 16),
        bodyMedium:    TextStyle(color: textSecondary, fontSize: 14),
        bodySmall:     TextStyle(color: textTertiary,  fontSize: 12),
        labelLarge:    TextStyle(color: gold,          fontWeight: FontWeight.w600, fontSize: 14),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color:      textPrimary,
          fontSize:   18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color:   surface,
        elevation: 0,
        shape:   RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Color(0xFF1A1600),
          elevation:       0,
          padding:         const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:           RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side:            const BorderSide(color: gold, width: 1.5),
          padding:         const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:           RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:          true,
        fillColor:       surfaceVariant,
        border:          OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: border),
        ),
        enabledBorder:   OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: border),
        ),
        focusedBorder:   OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: gold, width: 1.5),
        ),
        labelStyle:      const TextStyle(color: textSecondary),
        hintStyle:       const TextStyle(color: textTertiary),
      ),

      dividerTheme: const DividerThemeData(
        color:     border,
        thickness: 1,
        space:     1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior:         SnackBarBehavior.floating,
        shape:            RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      iconTheme: const IconThemeData(color: textSecondary),
    );
  }

  // ── Shared Decorations ─────────────────────────────────────────────────────

  static BoxDecoration get cardDecoration => BoxDecoration(
    color:        surface,
    borderRadius: BorderRadius.circular(16),
    border:       Border.all(color: border),
  );

  static BoxDecoration get goldBorderDecoration => BoxDecoration(
    color:        surface,
    borderRadius: BorderRadius.circular(16),
    border:       Border.all(color: gold.withOpacity(0.5), width: 1.5),
  );
}
