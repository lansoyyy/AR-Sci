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
      'id': 'g9_volcanoes',
      'title': 'Volcanoes',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Investigate types of volcanoes, eruption styles, and their effects on people and the environment.',
      'arItems': ['3D Volcano Model', 'Eruption Simulation', 'Lava Flow Paths'],
      'icon': Icons.terrain_outlined,
      'color': 'earthScience',
    },
    {
      'id': 'g9_earthquakes',
      'title': 'Earthquakes',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Understand how earthquakes happen, seismic waves, and how they are measured.',
      'arItems': [
        'Fault Line Models',
        'Seismic Wave Animation',
        'Earthquake Intensity Map'
      ],
      'icon': Icons.speed_outlined,
      'color': 'earthScience',
    },
    {
      'id': 'g9_climate',
      'title': 'Climate and Weather',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Explore factors that affect climate, weather patterns, and climate change impacts.',
      'arItems': [
        'Climate Graphs',
        'Atmospheric Layers',
        'Weather System Simulation'
      ],
      'icon': Icons.cloud,
      'color': 'earthScience',
    },
    {
      'id': 'g9_constellations',
      'title': 'Constellations',
      'subject': 'Earth Science',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Identify major constellations and learn how they are used for navigation and seasons.',
      'arItems': [
        'Night Sky Map',
        'Constellation Lines',
        'Star Information Cards'
      ],
      'icon': Icons.star,
      'color': 'earthScience',
    },
    {
      'id': 'g9_energy',
      'title': 'Energy and Work',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 3',
      'description':
          'Learn about different forms of energy, work, and the law of conservation of energy.',
      'arItems': [
        'Energy Transformations',
        'Work Done Simulations',
        'Energy Bar Charts'
      ],
      'icon': Icons.bolt,
      'color': 'physics',
    },
    {
      'id': 'g9_forces',
      'title': 'Forces',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 4',
      'description':
          'Understand different types of forces and how they affect the motion of objects.',
      'arItems': [
        'Force Diagrams',
        'Push and Pull Interactions',
        'Balanced vs Unbalanced Forces'
      ],
      'icon': Icons.arrow_upward,
      'color': 'physics',
    },
    {
      'id': 'g9_motion',
      'title': 'Motion',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 4',
      'description':
          'Describe motion using distance-time graphs, speed, velocity, and acceleration.',
      'arItems': [
        'Motion Graphs',
        'Moving Object Models',
        'Speed and Acceleration Sliders'
      ],
      'icon': Icons.directions_run,
      'color': 'physics',
    },
    {
      'id': 'g9_electricity',
      'title': 'Electricity',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 4',
      'description':
          'Explore electric circuits, current, voltage, and resistance using interactive models.',
      'arItems': [
        'Circuit Builder',
        'Current Flow Animation',
        'Series vs Parallel Circuits'
      ],
      'icon': Icons.bolt,
      'color': 'physics',
    },
    {
      'id': 'g9_waves',
      'title': 'Waves',
      'subject': 'Physics',
      'grade': 'Grade 9',
      'quarter': 'Quarter 4',
      'description':
          'Visualize mechanical and electromagnetic waves and how wavelength and frequency relate.',
      'arItems': [
        'Wave Interference',
        'Sound Wave Visualizer',
        'Light Spectrum'
      ],
      'icon': Icons.graphic_eq,
      'color': 'physics',
    },
  ];

  // Grade 10 Lessons with AR Items
  static const List<Map<String, dynamic>> grade10Lessons = [];

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
