import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool isPurpleTheme = false;

  void togglePurpleTheme(bool value) {
    isPurpleTheme = value;
    notifyListeners();   // 🔥 Refresh entire app UI
  }

  ThemeMode get themeMode => ThemeMode.light;
}
