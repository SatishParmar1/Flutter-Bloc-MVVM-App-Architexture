import 'package:flutter/material.dart';

class ThemeState {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);

  bool get isDark => themeMode == ThemeMode.dark;
}
