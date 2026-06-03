import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primary = Color(0xFF6C63FF);
  static const _editorBgLight = Color(0xFFFAFAFA);
  static const _editorBgDark = Color(0xFF1E1E2E);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
          surface: _editorBgLight,
        ),
        scaffoldBackgroundColor: _editorBgLight,
        visualDensity: VisualDensity.compact,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
          surface: _editorBgDark,
        ),
        scaffoldBackgroundColor: _editorBgDark,
        visualDensity: VisualDensity.compact,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      );
}
