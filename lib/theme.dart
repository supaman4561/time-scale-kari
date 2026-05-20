import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F172A);
  static const card = Color(0xFF1E293B);
  static const border = Color(0xFF334155);
  static const textMain = Color(0xFFF1F5F9);
  static const textSub = Color(0xFF64748B);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.blue,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.blue,
      unselectedItemColor: AppColors.textSub,
    ),
  );
}
