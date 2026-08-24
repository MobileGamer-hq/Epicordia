import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _prefKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_prefKey);
    if (savedMode == 'light') {
      state = ThemeMode.light;
    } else if (savedMode == 'dark') {
      state = ThemeMode.dark;
    } else if (savedMode == 'system') {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(String modeString) async {
    ThemeMode mode;
    final normalized = modeString.toLowerCase();
    if (normalized == 'light') {
      mode = ThemeMode.light;
    } else if (normalized == 'dark') {
      mode = ThemeMode.dark;
    } else {
      mode = ThemeMode.system;
    }

    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, normalized);
  }

  String get currentModeString {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class AppPrimaryColorNotifier extends Notifier<AppPrimaryColor> {
  static const String _prefKey = 'primary_color_option';

  @override
  AppPrimaryColor build() {
    _loadPrimaryColor();
    return EpicordiaColors.currentPrimaryColor;
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_prefKey);
    if (savedKey != null) {
      final match = AppPrimaryColor.values.firstWhere(
        (e) => e.name.toLowerCase() == savedKey.toLowerCase(),
        orElse: () => AppPrimaryColor.blue,
      );
      EpicordiaColors.currentPrimaryColor = match;
      state = match;
    }
  }

  Future<void> setPrimaryColor(AppPrimaryColor color) async {
    EpicordiaColors.currentPrimaryColor = color;
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, color.name);
  }
}

final appPrimaryColorProvider = NotifierProvider<AppPrimaryColorNotifier, AppPrimaryColor>(AppPrimaryColorNotifier.new);

