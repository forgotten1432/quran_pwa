import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryGold = Color(0xFFD4A853);
  static const Color _deepGreen = Color(0xFF1B5E20);
  static const Color _darkBg = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF2A2A2A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _deepGreen,
        secondary: _primaryGold,
        surface: const Color(0xFFF8F5F0),
        onSurface: const Color(0xFF1A1A1A),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F5F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // iOS-style thin separator instead of shadow
        scrolledUnderElevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFFF8F5F0),
        // iOS: Drawer with rounded corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
        ),
      ),
      dividerColor: Colors.grey.shade300,
      iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
      ),
      // iOS-style smooth page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      // iOS-style snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _primaryGold,
        secondary: _deepGreen,
        surface: _darkSurface,
        onSurface: const Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: _darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _primaryGold,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: _darkCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
        ),
      ),
      dividerColor: Colors.grey.shade800,
      iconTheme: IconThemeData(color: _primaryGold),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
