import 'package:flutter/material.dart';

/// App color palette with custom purple and warm beige shades
class AppColors {
  // Primary Colors - Custom warm beige and purple combination
  static const Color primary = Color(0xFFC4799A); // Custom Purple
  static const Color primaryLight = Color(0xFFD8A8C0); // Lighter Purple
  static const Color primaryDark = Color(0xFFA55A7A); // Darker Purple

  // Secondary Colors - Complementary shades
  static const Color secondary = Color(0xFFFAEDE5); // Warm Beige
  static const Color secondaryLight = Color(0xFFFFF3ED); // Lighter Beige
  static const Color secondaryDark = Color(0xFFF0DCC7); // Darker Beige

  // Accent Colors - Additional purple and beige variations
  static const Color accent = Color(0xFFD8A8C0); // Light Purple
  static const Color accentLight = Color(0xFFD1B8C1); // Soft Purple-Beige

  // Background Colors - Warm and soft backgrounds
  static const Color background = Color(0xFFFAEDE5); // Primary background
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFFFF8F3); // Light surface

  // Text Colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textWhite = Colors.white;

  // Status Colors - Purple and beige-tinted status colors
  static const Color success = Color(0xFFA8D8A8); // Soft Green
  static const Color warning = Color(0xFFD8B86B); // Warm Yellow
  static const Color error = Color(0xFFD87070); // Soft Red
  static const Color info = Color(0xFF8A9BC8); // Soft Blue

  // Medication Status Colors
  static const Color taken = Color(0xFFA8D8A8); // Soft Green
  static const Color missed = Color(0xFFD87070); // Soft Red
  static const Color pending = Color(0xFFD8B86B); // Warm Yellow
  static const Color skipped = Color(0xFF9E9E9E);

  // Feature-specific Colors - Various purple and beige shades
  static const Color aiAssistant = Color(0xFFC4799A); // Primary Purple
  static const Color consultation = Color(0xFFA890B8); // Soft Purple
  static const Color emergency = Color(0xFFD87070); // Soft Red
  static const Color reward = Color(0xFFD8B86B); // Warm Yellow

  // Gradient Colors - Purple and beige gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFC4799A), Color(0xFFD8A8C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFAEDE5), Color(0xFFF0DCC7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFFAEDE5), Color(0xFFFFF8F3)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadow Colors - Purple-tinted shadows
  static const Color shadowLight = Color(0x1AC4799A);
  static const Color shadowMedium = Color(0x33C4799A);

  // Divider and Border Colors
  static const Color divider = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF5F5F5);
}
