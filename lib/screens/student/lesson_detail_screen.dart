import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get lesson arguments passed from navigation
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? lessonData;

    if (args is Map<String, dynamic>) {
      lessonData = args;
    } else if (args is String) {
      // Find lesson by ID if only ID was passed
      lessonData = AppConstants.allLessons.firstWhere(
        (lesson) => lesson['id'] == args,
        orElse: () => AppConstants.allLessons.first,
      );
    } else {
      // Default to first lesson
      lessonData = AppConstants.allLessons.first;
    }

    final lesson = lessonData ?? AppConstants.allLessons.first;
    final Color subjectColor = _getSubjectColor(lesson['color']);
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson['title']),
        backgroundColor: subjectColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Video Placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    subjectColor,
                    subjectColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: AppColors.textWhite,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingM,
                          vertical: AppConstants.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: subjectColor,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusRound),
                        ),
                        child: Text(
                          lesson['subject'],
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: AppConstants.fontS,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingM,
                          vertical: AppConstants.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusRound),
                        ),
                        child: Text(
                          lesson['grade'],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppConstants.fontS,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Title
                  Text(
                    lesson['title'],
                    style: const TextStyle(
                      fontSize: AppConstants.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingM),

                  // Description
                  Text(
                    lesson['description'],
                    style: const TextStyle(
                      fontSize: AppConstants.fontL,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Progress
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: AppConstants.fontL,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusRound),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    '65% Complete',
                    style: const TextStyle(
                      fontSize: AppConstants.fontM,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Content Sections
                  const Text(
                    'Lesson Content',
                    style: TextStyle(
                      fontSize: AppConstants.fontXL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),

                  // Dynamic content sections based on lesson
                  ..._getContentSections(lesson)
                      .map((section) => _ContentSection(
                            title: section['title'],
                            duration: section['duration'],
                            isCompleted: section['isCompleted'],
                            isActive: section['isActive'],
                            onTap: () {},
                            subjectColor: subjectColor,
                          )),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Download Materials
                  Card(
                    child: ListTile(
                      leading:
                          Icon(Icons.download_outlined, color: subjectColor),
                      title: const Text('Download Study Materials'),
                      subtitle: const Text('PDF • 2.5 MB'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // AR View Button
                  CustomButton(
                    text: 'View in AR',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/ar-view',
                        arguments: lesson,
                      );
                    },
                    fullWidth: true,
                    backgroundColor: subjectColor,
                    icon: Icons.view_in_ar,
                  ),

                  const SizedBox(height: AppConstants.paddingM),

                  // Continue Button
                  CustomButton(
                    text: 'Continue Learning',
                    onPressed: () {},
                    fullWidth: true,
                    type: ButtonType.outlined,
                    textColor: subjectColor,
                    icon: Icons.play_arrow,
                  ),

                  const SizedBox(height: AppConstants.paddingL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final String title;
  final String duration;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onTap;
  final Color subjectColor;

  const _ContentSection({
    required this.title,
    required this.duration,
    this.isCompleted = false,
    this.isActive = false,
    required this.onTap,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      color: isActive ? subjectColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : isActive
                    ? AppColors.studentPrimary
                    : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.play_arrow,
            color: isCompleted || isActive
                ? AppColors.textWhite
                : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(duration),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

Color _getSubjectColor(String? colorName) {
  switch (colorName) {
    case 'physics':
      return AppColors.physics;
    case 'chemistry':
      return AppColors.chemistry;
    case 'biology':
      return AppColors.biology;
    case 'earthScience':
      return AppColors.primary;
    default:
      return AppColors.studentPrimary;
  }
}

List<Map<String, dynamic>> _getContentSections(Map<String, dynamic> lesson) {
  switch (lesson['id']) {
    case 'g9_volcanoes':
      return [
        {
          'title': 'Introduction to Volcanoes',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Types of Volcanoes',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Causes of Eruptions',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Volcanic Hazards & Risks',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Volcano Exploration',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_earthquakes':
      return [
        {
          'title': 'Earth’s Plates and Faults',
          'duration': '8 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'How Earthquakes Happen',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Seismic Waves',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Measuring Earthquakes',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'Preparedness and Safety',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_climate':
      return [
        {
          'title': 'Weather vs Climate',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Factors Affecting Climate',
          'duration': '12 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Climate Zones',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Climate Change Impacts',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Climate Visualizations',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_constellations':
      return [
        {
          'title': 'Patterns in the Night Sky',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Major Constellations',
          'duration': '12 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Seasonal Sky Changes',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Constellations and Navigation',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Star Map Exploration',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_energy':
      return [
        {
          'title': 'Forms of Energy',
          'duration': '8 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Work and Power',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Energy Transformations',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Conservation of Energy',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'Energy in Everyday Life',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_forces':
      return [
        {
          'title': 'Introduction to Forces',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Types of Forces',
          'duration': '12 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Net Force and Equilibrium',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Friction and Air Resistance',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Force Simulations',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_motion':
      return [
        {
          'title': 'Describing Motion',
          'duration': '6 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Speed and Velocity',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Acceleration',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Graphs of Motion',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'Motion in Real Life',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_electricity':
      return [
        {
          'title': 'Basic Electric Quantities',
          'duration': '8 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Simple Circuits',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Series and Parallel Circuits',
          'duration': '12 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Safety with Electricity',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'AR Circuit Builder',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    case 'g9_waves':
      return [
        {
          'title': 'What Are Waves?',
          'duration': '8 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Wave Properties',
          'duration': '10 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Sound Waves',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Light Waves',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
        {
          'title': 'Wave Applications',
          'duration': '8 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
    default:
      return [
        {
          'title': 'Introduction',
          'duration': '5 min',
          'isCompleted': true,
          'isActive': false
        },
        {
          'title': 'Main Content',
          'duration': '15 min',
          'isCompleted': false,
          'isActive': true
        },
        {
          'title': 'Practice',
          'duration': '10 min',
          'isCompleted': false,
          'isActive': false
        },
      ];
  }
}
