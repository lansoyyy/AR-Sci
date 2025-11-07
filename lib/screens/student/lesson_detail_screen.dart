import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Details'),
        backgroundColor: AppColors.studentPrimary,
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
                    AppColors.studentPrimary,
                    AppColors.studentLight,
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
                          color: AppColors.studentPrimary,
                          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                        ),
                        child: const Text(
                          'Physics',
                          style: TextStyle(
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
                          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                        ),
                        child: const Text(
                          'Grade 10',
                          style: TextStyle(
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
                  const Text(
                    'Laws of Motion',
                    style: TextStyle(
                      fontSize: AppConstants.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingM),
                  
                  // Description
                  const Text(
                    'Learn about Newton\'s three laws of motion and how they govern the movement of objects in our universe.',
                    style: TextStyle(
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
                    borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                    child: const LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.studentPrimary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  const Text(
                    '65% Complete',
                    style: TextStyle(
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
                  
                  _ContentSection(
                    title: 'Introduction',
                    duration: '5 min',
                    isCompleted: true,
                    onTap: () {},
                  ),
                  _ContentSection(
                    title: 'Newton\'s First Law',
                    duration: '10 min',
                    isCompleted: true,
                    onTap: () {},
                  ),
                  _ContentSection(
                    title: 'Newton\'s Second Law',
                    duration: '12 min',
                    isCompleted: false,
                    isActive: true,
                    onTap: () {},
                  ),
                  _ContentSection(
                    title: 'Newton\'s Third Law',
                    duration: '10 min',
                    isCompleted: false,
                    onTap: () {},
                  ),
                  _ContentSection(
                    title: 'Practice Problems',
                    duration: '15 min',
                    isCompleted: false,
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: AppConstants.paddingXL),
                  
                  // Download Materials
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.download_outlined, color: AppColors.studentPrimary),
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
                        arguments: {
                          'lessonId': '1',
                          'lessonTitle': 'Laws of Motion',
                        },
                      );
                    },
                    fullWidth: true,
                    backgroundColor: AppColors.studentPrimary,
                    icon: Icons.view_in_ar,
                  ),
                  
                  const SizedBox(height: AppConstants.paddingM),
                  
                  // Continue Button
                  CustomButton(
                    text: 'Continue Learning',
                    onPressed: () {},
                    fullWidth: true,
                    type: ButtonType.outlined,
                    textColor: AppColors.studentPrimary,
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

  const _ContentSection({
    required this.title,
    required this.duration,
    this.isCompleted = false,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      color: isActive ? AppColors.studentPrimary.withOpacity(0.1) : null,
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
            color: isCompleted || isActive ? AppColors.textWhite : AppColors.textSecondary,
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
