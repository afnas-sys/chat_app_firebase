import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

ThemeData theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
  //  scaffoldBackgroundColor: Colors.transparent,
  iconTheme: IconThemeData(
    color: AppColors.primaryColor,
    size: 20,
    //    weight:
  ),
);

extension CustomTextStyle on TextTheme {
  /*
  !Use it for reference for Naming
   static const displayLarge = TextStyle(fontSize: 57, fontWeight: FontWeight.bold);
  static const displayMedium = TextStyle(fontSize: 45, fontWeight: FontWeight.w600);
  static const displaySmall = TextStyle(fontSize: 36, fontWeight: FontWeight.w600);

  static const headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w600);
  static const headlineMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.w500);
  static const headlineSmall = TextStyle(fontSize: 24, fontWeight: FontWeight.w500);

   // Titles
  static const titleLarge = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
  static const titleMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const titleSmall = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

  // Body
  static const bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static const bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
  static const bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);

  // Special
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  */

  TextStyle get displayMediumPrimary => GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  TextStyle get titleLargePrimary => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  TextStyle get titleMediumPrimary => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );
  TextStyle get titleSmallPrimary => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryColor,
  );
  TextStyle get titleSmallSecondary => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.thirteenthColor,
  );

  TextStyle get bodyMediumPrimary => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
  );
  TextStyle get bodyMediumSecondary => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.eighthColor,
  );

  TextStyle get bodySmallPrimary => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
  );
  TextStyle get bodySmallSecondary => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.tertiaryColor,
  );
  TextStyle get bodySmallTertiary => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.sixthColor,
  );
  TextStyle get bodySmallFourth => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.seventhColor,
  );
  TextStyle get bodySmallFifth => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.twelfthColor,
  );
}
