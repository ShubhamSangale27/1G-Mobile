import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Poppins — widely used on Indian e-commerce apps (Flipkart, Meesho-style clarity).
abstract final class AppTheme {
  static TextTheme _poppins(TextTheme base, Brightness brightness) {
    final color = brightness == Brightness.light ? AppColors.textPrimary : AppColors.darkText;
    final muted = brightness == Brightness.light ? AppColors.textSecondary : AppColors.darkText;
    final poppins = GoogleFonts.poppinsTextTheme(base);
    return poppins.copyWith(
      displayLarge: poppins.displayLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
      displayMedium: poppins.displayMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      displaySmall: poppins.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      headlineLarge: poppins.headlineLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
      headlineMedium: poppins.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      headlineSmall: poppins.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      titleLarge: poppins.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
      titleMedium: poppins.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      titleSmall: poppins.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
      bodyLarge: poppins.bodyLarge?.copyWith(color: color),
      bodyMedium: poppins.bodyMedium?.copyWith(color: muted),
      bodySmall: poppins.bodySmall?.copyWith(color: AppColors.textMuted),
      labelLarge: poppins.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: poppins.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: poppins.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    final text = _poppins(base.textTheme, Brightness.light);
    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = text.labelSmall!;
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary);
          }
          return style.copyWith(color: AppColors.textMuted);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: text.labelLarge?.copyWith(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
    final text = _poppins(base.textTheme, Brightness.dark);
    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
