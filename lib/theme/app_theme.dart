import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050B18),
      fontFamily: 'Roboto', // system font
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1DA1F2),
        secondary: Color(0xFF00E5FF),
      ),
    );
  }
}
