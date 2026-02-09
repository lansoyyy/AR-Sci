import 'package:flutter/material.dart';

/// App color palette with science-inspired blues and teals
class AppColors {
  // Primary Colors - Science and technology inspired blues
  static const Color primary = Color(0xFF0A84FF); // Vibrant Blue
  static const Color primaryLight = Color(0xFF5AC8FA); // Light Blue
  static const Color primaryDark = Color(0xFF0051D5); // Deep Blue

  // Secondary Colors - Teal and cyan for scientific innovation
  static const Color secondary = Color(0xFF32D74B); // Fresh Green
  static const Color secondaryLight = Color(0xFF63E380); // Light Green
  static const Color secondaryDark = Color(0xFF28A745); // Darker Green

  // Accent Colors - Teal and cyan for AR/tech feel
  static const Color accent = Color(0xFF5AC8FA); // Cyan Blue
  static const Color accentLight = Color(0xFF99E5FF); // Light Cyan

  // Background Colors - Clean, modern scientific backgrounds
  static const Color background =
      Color(0xFFF0F8FF); // Alice Blue (scientific white)
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFF8FAFC); // Light surface

  // Text Colors
  static const Color textPrimary = Color(0xFF1D1D1F); // Dark Gray
  static const Color textSecondary = Color(0xFF6E6E73); // Medium Gray
  static const Color textLight = Color(0xFF8E8E93); // Light Gray
  static const Color textWhite = Colors.white;

  // Status Colors - Clear, distinct status colors
  static const Color success = Color(0xFF34C759); // Bright Green
  static const Color warning = Color(0xFFFF9500); // Orange
  static const Color error = Color(0xFFFF3B30); // Red
  static const Color info = Color(0xFF007AFF); // Info Blue

  // Learning Status Colors
  static const Color completed = Color(0xFF34C759); // Bright Green
  static const Color inProgress = Color(0xFF007AFF); // Blue
  static const Color notStarted = Color(0xFF8E8E93); // Gray
  static const Color overdue = Color(0xFFFF3B30); // Red

  // Feature-specific Colors - Science and technology themed
  static const Color arFeature = Color(0xFFAF52DE); // Purple for AR
  static const Color simulation = Color(0xFF5AC8FA); // Cyan for simulations
  static const Color periodicTable = Color(0xFF32D74B); // Green for chemistry
  static const Color biology = Color(0xFFFF3B30); // Red for biology
  static const Color physics = Color(0xFF007AFF); // Blue for physics
  static const Color chemistry = Color(0xFF32D74B); // Green for chemistry
  static const Color earthScience =
      Color(0xFF8B4513); // Brown for earth science

  // Role-specific Colors - Enhanced science theme
  static const Color studentPrimary = Color(0xFF007AFF); // Bright Blue
  static const Color studentLight = Color(0xFF5AC8FA); // Light Blue
  static const Color studentDark = Color(0xFF0051D5); // Dark Blue

  static const Color teacherPrimary = Color(0xFF34C759); // Bright Green
  static const Color teacherLight = Color(0xFF63E380); // Light Green
  static const Color teacherDark = Color(0xFF28A745); // Dark Green

  static const Color adminPrimary = Color(0xFF636366); // Modern Gray
  static const Color adminLight = Color(0xFF8E8E93); // Light Gray
  static const Color adminDark = Color(0xFF48484A); // Dark Gray

  // Gradient Colors - Science-inspired gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF32D74B), Color(0xFF63E380)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient arGradient = LinearGradient(
    colors: [Color(0xFFAF52DE), Color(0xFF5AC8FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFF0F8FF), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadow Colors - Modern, subtle shadows
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);

  // Divider and Border Colors
  static const Color divider = Color(0xFFE5E5EA);
  static const Color border = Color(0xFFD1D1D6);
  static const Color borderLight = Color(0xFFF2F2F7);
}
