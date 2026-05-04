import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Primary colors
  static const Color primaryBlack = Color(0xFF0A0A0A);
  static const Color surfaceBlack = Color(0xFF141414);
  static const Color cardBlack = Color(0xFF1E1E1E);

  // Gray scale
  static const Color borderGray = Color(0xFF2C2C2C);
  static const Color silverMid = Color(0xFF8A8A8A);
  static const Color silverLight = Color(0xFFD0D0D0);

  // White variants
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color accentWhite = Color(0xFFF5F5F5);
  static const Color frostedOverlay = Color(0x33FFFFFF); // white 20% opacity

  // Semantic colors
  static const Color dangerRed = Color(0xFFE53E3E);
  static const Color successGreen = Color(0xFF38A169);
  static const Color warningAmber = Color(0xFFD69E2E);

  // Legacy aliases for backward compatibility
  static const Color background = primaryBlack;
  static const Color surface = surfaceBlack;
  static const Color textPrimary = pureWhite;
  static const Color textSecondary = silverLight;
  static const Color border = borderGray;
  static const Color accent = pureWhite;
  static const Color danger = dangerRed;
}
