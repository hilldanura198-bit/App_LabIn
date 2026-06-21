import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _themeModeKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.light);

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey);
    emit(saved == 'dark' ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, enabled ? 'dark' : 'light');
  }

  Future<void> toggle() {
    return setDarkMode(state != ThemeMode.dark);
  }

  Future<void> resetToSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey);
    emit(ThemeMode.system);
  }

  bool get isDark => state == ThemeMode.dark;
}
