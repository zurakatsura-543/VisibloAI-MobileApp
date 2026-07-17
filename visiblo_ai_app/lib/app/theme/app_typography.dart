import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static final String? fontFamily = GoogleFonts.poppins().fontFamily;
  static const double heroHeading = 52;
  static const double sectionHeading = 32;
  static const double cardTitle = 22;
  static const double bodyText = 17;
  static const double bodyTextCompact = 16;
  static const double chatMessage = 17;
  static const double buttonText = 16;
  static const double smallLabel = 13.5;
  static const double microLabel = 13;

  static TextTheme buildTextTheme(TextTheme base) {
    return base
        .apply(fontFamily: fontFamily)
        .copyWith(
          displayLarge: hero(),
          displayMedium: hero(fontSize: 44, letterSpacing: -0.8),
          headlineLarge: section(fontSize: 36, height: 1.12),
          headlineMedium: section(),
          headlineSmall: section(fontSize: 28, height: 1.18),
          titleLarge: card(fontSize: 24),
          titleMedium: card(),
          titleSmall: card(fontSize: 20),
          bodyLarge: body(),
          bodyMedium: body(
            fontSize: bodyTextCompact,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w500,
          ),
          bodySmall: body(
            fontSize: 14,
            color: AppColors.mutedText,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
          labelLarge: button(),
          labelMedium: label(),
          labelSmall: label(fontSize: microLabel),
        );
  }

  static TextStyle hero({
    Color color = AppColors.text,
    double fontSize = heroHeading,
    double height = 1.02,
    double letterSpacing = -1.1,
    FontWeight fontWeight = FontWeight.w800,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle section({
    Color color = AppColors.text,
    double fontSize = sectionHeading,
    double height = 1.14,
    double letterSpacing = -0.35,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle card({
    Color color = AppColors.text,
    double fontSize = cardTitle,
    double height = 1.24,
    double letterSpacing = -0.2,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle body({
    Color color = AppColors.text,
    double fontSize = bodyText,
    double height = 1.55,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle button({
    Color color = AppColors.text,
    double fontSize = buttonText,
    double height = 1.2,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle label({
    Color color = AppColors.text,
    double fontSize = smallLabel,
    double height = 1.3,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
