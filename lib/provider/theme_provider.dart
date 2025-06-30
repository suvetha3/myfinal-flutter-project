import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Common styles
  ThemeData applyCommonStyles(ThemeData base) {
    return base.copyWith(

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: base.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      cardTheme: CardTheme(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: base.colorScheme.surface,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      dialogTheme: DialogTheme(
        backgroundColor: base.colorScheme.surface,
        titleTextStyle: TextStyle(
          color: base.colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: base.colorScheme.onSurface,
          fontSize: 15,
        ),
      ),

      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: base.colorScheme.onSurface,
        ),

        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: base.colorScheme.onSurface,
        ),
      ),
    );
  }

  // Light Theme
  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ).copyWith(
      primary: Colors.deepPurple,
      onPrimary: Colors.white,
      secondary: Colors.orange,
      tertiary: Colors.green,
      surface: Colors.white,
      onSurface: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
    );

    final base = ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: Colors.deepPurple.shade100,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );

    return applyCommonStyles(base);
  }

  // Dark Theme
  ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Colors.deepPurple.shade200,
      onPrimary: Colors.black,
      secondary: Colors.amber,
      tertiary: Colors.green.shade400,
      surface: Colors.grey.shade900,
      onSurface: Colors.white,
      error: Colors.red.shade300,
      onError: Colors.black,
    );

    final base = ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );

    return applyCommonStyles(base);
  }
}
