import 'package:flutter/material.dart';

/// All colors used in the app.
/// Change values here to update the entire app's color scheme.
class AppColors {
  AppColors._(); // prevents instantiation

  // Brand
  static const Color primary = Color(0xFF6C63FF);       // purple-blue
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color accent = Color(0xFFFF6584);        // coral pink

  // Backgrounds
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F8);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B7C3);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Misc
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x1A000000);
}
