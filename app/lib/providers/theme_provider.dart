import 'package:cricstatz/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_color_theme';

  AppColorTheme _currentTheme = AppColorTheme.cyberCyan;

  AppColorTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_prefKey);
      if (themeName != null && themeName != 'stadiumLight') {
        final loaded = AppColorTheme.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => AppColorTheme.cyberCyan,
        );
        _currentTheme = loaded;
        AppPalette.applyTheme(loaded);
        notifyListeners();
      } else {
        _currentTheme = AppColorTheme.cyberCyan;
        AppPalette.applyTheme(_currentTheme);
        await prefs.setString(_prefKey, _currentTheme.name);
        notifyListeners();
      }
    } catch (_) {
      _currentTheme = AppColorTheme.cyberCyan;
      AppPalette.applyTheme(_currentTheme);
      notifyListeners();
    }
  }

  Future<void> setTheme(AppColorTheme theme) async {
    if (_currentTheme == theme) return;
    _currentTheme = theme;
    AppPalette.applyTheme(theme);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, theme.name);
    } catch (_) {
      // Ignore storage error
    }
  }

  Future<void> toggleDarkLight() async {
    if (_currentTheme.isDark) {
      await setTheme(AppColorTheme.pitchModernLight);
    } else {
      await setTheme(AppColorTheme.cyberCyan);
    }
  }

  ThemeData get currentThemeData {
    final isDark = _currentTheme.isDark;
    final TextTheme textTheme = isDark
        ? GoogleFonts.lexendTextTheme()
        : GoogleFonts.hankenGroteskTextTheme();

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _currentTheme.primaryAccent,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: AppPalette.bgPrimary,
      ),
      scaffoldBackgroundColor: AppPalette.bgPrimary,
      textTheme: textTheme.apply(
        bodyColor: AppPalette.textPrimary,
        displayColor: AppPalette.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppPalette.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppPalette.textPrimary,
          fontWeight: FontWeight.w700,
      ),
    ),
    useMaterial3: true,
  );
}
}
