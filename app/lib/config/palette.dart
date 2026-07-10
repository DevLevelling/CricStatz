import 'package:flutter/material.dart';

enum AppColorTheme {
  cyberCyan('Cyber Cyan', Color(0xFF00C2FF), true),
  pitchModernLight('Pitch Modern Light', Color(0xFFAA1A20), false);

  final String label;
  final Color primaryAccent;
  final bool isDark;

  const AppColorTheme(this.label, this.primaryAccent, this.isDark);
}

class AppPalette {
  static Color bgPrimary = const Color(0xFF111721);
  static Color bgSecondary = const Color(0xFF0A1F43);
  static Color cardPrimary = const Color(0xFF0D1E3F);
  static Color cardOverlay = const Color(0x661E293B);
  static Color cardStroke = const Color(0xFF1E293B);

  static Color textPrimary = const Color(0xFFF1F5F9);
  static Color textMuted = const Color(0xFF94A3B8);
  static Color textSubtle = const Color(0xFF64748B);

  static Color live = const Color(0xFFEF4444);
  static Color success = const Color(0xFF4ADE80);
  static Color accent = const Color(0xFF00C2FF);
  static Color progress = const Color(0xFF3B82F6);

  static Color navActive = const Color(0xFF00D1FF);
  static Color navInactive = const Color(0xFF64748B);

  static LinearGradient surfaceGradient = const LinearGradient(
    colors: [Color(0xFF111721), Color(0xFF111721)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static AppColorTheme currentTheme = AppColorTheme.cyberCyan;

  static void applyTheme(AppColorTheme theme) {
    currentTheme = theme;
    if (theme.isDark) {
      bgPrimary = const Color(0xFF111721);
      bgSecondary = const Color(0xFF0A1F43);
      cardPrimary = const Color(0xFF0D1E3F);
      cardOverlay = const Color(0x661E293B);
      cardStroke = const Color(0xFF1E293B);

      textPrimary = const Color(0xFFF1F5F9);
      textMuted = const Color(0xFF94A3B8);
      textSubtle = const Color(0xFF64748B);

      live = const Color(0xFFEF4444);
      success = const Color(0xFF4ADE80);
      accent = const Color(0xFF00C2FF);
      progress = const Color(0xFF3B82F6);

      navActive = const Color(0xFF00D1FF);
      navInactive = const Color(0xFF64748B);

      surfaceGradient = const LinearGradient(
        colors: [Color(0xFF111721), Color(0xFF111721)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      // Reference Light Theme (Pitch Modern Light)
      bgPrimary = const Color(0xFFFFFFFF);
      bgSecondary = const Color(0xFFFAF2F3);
      cardPrimary = const Color(0xFFFFFFFF);
      cardOverlay = const Color(0xFFFCFAFA);
      cardStroke = const Color(0xFFE8C5C8);

      textPrimary = const Color(0xFF003366);
      textMuted = const Color(0xFF5A6B82);
      textSubtle = const Color(0xFF8C7375);

      live = const Color(0xFF85000F);
      success = const Color(0xFF15803D);
      accent = const Color(0xFF85000F);
      progress = const Color(0xFF85000F);

      navActive = const Color(0xFF85000F);
      navInactive = const Color(0xFF5A6B82);

      surfaceGradient = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFAF8F8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  const AppPalette._();
}
