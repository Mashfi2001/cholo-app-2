import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  // Typography using Syne for headings, DM Sans for body

  // Headings - Syne font family
  static TextStyle headingXL = GoogleFonts.syne(
    fontSize: 28,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.pureWhite,
    letterSpacing: -0.5,
  );

  static TextStyle headingL = GoogleFonts.syne(
    fontSize: 22,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.pureWhite,
  );

  static TextStyle headingM = GoogleFonts.syne(
    fontSize: 18,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.pureWhite,
  );

  // Body text - DM Sans font family
  static TextStyle bodyL = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.silverLight,
  );

  static TextStyle bodyM = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.silverMid,
  );

  static TextStyle bodyS = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.silverMid,
  );

  static TextStyle labelBold = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.pureWhite,
    letterSpacing: 0.5,
  );

  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.silverMid,
  );

  // Legacy aliases for backward compatibility
  static TextStyle get heading => headingXL;
  static TextStyle get sectionTitle => headingL;
  static TextStyle get body => bodyL;
  static TextStyle get label => labelBold;
}
