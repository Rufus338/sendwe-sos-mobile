/// Thème de l'application (design system UI/UX Pro Max — Emergency SOS & Safety).
/// Palette : alert red #DC2626 + safety blue #2563EB + high contrast (section 11).

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFDC2626); // alert red
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFEF4444);
  static const accent = Color(0xFF2563EB); // safety blue
  static const onAccent = Color(0xFFFFFFFF);
  static const background = Color(0xFFFFF1F2);
  static const foreground = Color(0xFF0F172A);
  static const muted = Color(0xFFFCF1F1);
  static const mutedForeground = Color(0xFF64748B);
  static const border = Color(0xFFFAE4E4);

  // Couleurs fonctionnelles (section 11)
  static const success = Color(0xFF16A34A); // vert
  static const active = Color(0xFF2563EB); // bleu
  static const pending = Color(0xFFD97706); // orange/ambre
  static const danger = Color(0xFFDC2626); // rouge
  static const offline = Color(0xFF6B7280); // gris
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    surface: AppColors.background,
    onSurface: AppColors.foreground,
    error: AppColors.danger,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Fira Sans',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: AppColors.foreground,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Fira Sans',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.muted,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Fira Sans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
