import 'package:flutter/material.dart';

class AppColors {
  static const primary    = Color(0xFF1A1A2E);
  static const secondary  = Color(0xFF16213E);
  static const accent     = Color(0xFF0F3460);
  static const gold       = Color(0xFFE94560);
  static const lightSquare = Color(0xFFF0D9B5);
  static const darkSquare  = Color(0xFFB58863);
  static const white      = Colors.white;
  static const grey       = Color(0xFF9E9E9E);
}

class AppConstants {
  static const baseUrl    = 'http://10.205.58.1:3000'; // Android emulator → localhost
  static const socketUrl  = 'http://10.205.58.1:3000';
  static const tokenKey   = 'chess_token';
  static const userKey    = 'chess_user';
}

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary:   AppColors.gold,
    secondary: AppColors.accent,
    surface:   AppColors.secondary,
    background: AppColors.primary,
  ),
  scaffoldBackgroundColor: AppColors.primary,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.secondary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.accent.withOpacity(0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.gold),
    ),
    labelStyle: const TextStyle(color: AppColors.grey),
  ),
  cardTheme: CardThemeData(
    color: AppColors.secondary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
  ),
);
