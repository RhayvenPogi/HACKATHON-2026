import 'package:flutter/material.dart';

/// FLOW palette. Text/background pairs meet WCAG AA (4.5:1) on white.
abstract final class AppColors {
  static const Color primary = Color(0xFF0F766E); // teal
  static const Color primaryDark = Color(0xFF115E59);
  static const Color secondary = Color(0xFF15803D); // green

  static const Color background = Color(0xFFF6FAF9);
  static const Color surface = Colors.white;
  static const Color infoBackground = Color(0xFFE6F4F1);
  static const Color border = Color(0xFFD9E2E1);

  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF52606D);

  static const Color error = Color(0xFFB42318);
}