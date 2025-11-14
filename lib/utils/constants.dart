import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // App Information
  static const String appName = 'AR SCI';
  static const String appFullName = 'AR SCI Mobile App';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Science Education Reimagined';

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;

  // Font Sizes
  static const double fontXS = 10.0;
  static const double fontS = 12.0;
  static const double fontM = 14.0;
  static const double fontL = 16.0;
  static const double fontXL = 20.0;
  static const double fontXXL = 24.0;
  static const double fontTitle = 28.0;
  static const double fontDisplay = 32.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Languages
  static const List<String> supportedLanguages = [
    'English',
    'Filipino',
    'Cebuano'
  ];

  // Adherence Thresholds
  static const double excellentAdherence = 90.0;
  static const double goodAdherence = 75.0;
  static const double fairAdherence = 60.0;

  // Reward Points
  static const int pointsPerDose = 10;
  static const int pointsPerStreak = 50;
  static const int pointsPerWeekPerfect = 100;

  // Reminder Settings
  static const int defaultReminderMinutes = 15;
  static const int maxReminders = 5;

  // Image Paths
  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';
  static const String animationPath = 'assets/animations/';

  // API Endpoints (placeholder)
  static const String baseUrl = 'https://api.mamaapp.com';

  // Google Places API
  static const String googlePlacesApiKey =
      'AIzaSyBwByaaKz7j4OGnwPDxeMdmQ4Pa50GA42o';
  static const String googlePlacesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // Davao City coordinates
  static const double davaoCityLatitude = 7.0731;
  static const double davaoCityLongitude = 125.6128;

  // Local Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserType = 'user_type';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotifications = 'notifications_enabled';
  static const String keyOfflineMode = 'offline_mode';

  // User Types
  static const String userTypeStudent = 'student';
  static const String userTypeTeacher = 'teacher';
  static const String userTypeAdmin = 'admin';

  // Grade Levels
  static const List<String> gradeLevels = [
    'Grade 9',
    'Grade 10',
  ];

  // Subjects
  static const List<String> subjects = [
    'Biology',
    'Chemistry',
    'Physics',
    'Earth Science',
  ];

  // Grade 9 Lessons with AR Items
  static const List<Map<String, dynamic>> grade9Lessons = [
    {
      'id': 'g9_periodic',
      'title': 'Periodic Table',
      'subject': 'Chemistry',
      'grade': 'Grade 9',
      'description':
          'Explore elements and their properties through interactive AR',
      'arItems': [
        '3D Element Models',
        'Atomic Structure',
        'Element Properties'
      ],
      'icon': Icons.science_outlined,
      'color': 'chemistry',
    },
    {
      'id': 'g9_volcano',
      'title': 'Volcano & Climate Change',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'description': 'Understand volcanic activity and its impact on climate',
      'arItems': ['3D Volcano Model', 'Eruption Simulation', 'Climate Effects'],
      'icon': Icons.terrain_outlined,
      'color': 'earthScience',
    },
    {
      'id': 'g9_respiratory',
      'title': 'Respiratory & Circulatory Systems',
      'subject': 'Biology',
      'grade': 'Grade 9',
      'description':
          'Learn how respiratory and circulatory systems work together',
      'arItems': ['3D Heart Model', 'Lung Structure', 'Blood Flow Animation'],
      'icon': Icons.favorite_outlined,
      'color': 'biology',
    },
  ];

  // Grade 10 Lessons with AR Items
  static const List<Map<String, dynamic>> grade10Lessons = [
    {
      'id': 'g10_physics',
      'title': 'Forces & Gravity',
      'subject': 'Physics',
      'grade': 'Grade 10',
      'description':
          'Explore fundamental forces and gravitational interactions',
      'arItems': ['Force Vectors', 'Gravity Simulation', 'Orbital Mechanics'],
      'icon': Icons.speed_outlined,
      'color': 'physics',
    },
  ];

  // All Lessons Combined
  static const List<Map<String, dynamic>> allLessons = [
    ...grade9Lessons,
    ...grade10Lessons,
  ];

  // Medication Status
  static const String statusTaken = 'taken';
  static const String statusMissed = 'missed';
  static const String statusPending = 'pending';
  static const String statusSkipped = 'skipped';

  // Severity Levels
  static const String severityMild = 'mild';
  static const String severityModerate = 'moderate';
  static const String severitySerious = 'serious';
  static const String severityUrgent = 'urgent';
}

/// Text Styles
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: AppConstants.fontDisplay,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: AppConstants.fontTitle,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: AppConstants.fontXXL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: AppConstants.fontXL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: AppConstants.fontL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppConstants.fontL,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppConstants.fontS,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: AppConstants.fontS,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: AppConstants.fontXS,
    fontWeight: FontWeight.w500,
  );
}
