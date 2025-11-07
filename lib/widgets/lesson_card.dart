import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/lesson_model.dart';

class LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback? onTap;
  final bool showProgress;
  final double? progress;

  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.showProgress = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      elevation: AppConstants.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with subject badge
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.studentPrimary.withOpacity(0.1),
                    AppColors.studentLight.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusM),
                  topRight: Radius.circular(AppConstants.radiusM),
                ),
              ),
              child: Row(
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
                    child: Text(
                      lesson.subject,
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
                      borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                    ),
                    child: Text(
                      lesson.gradeLevel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppConstants.fontS,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: AppConstants.fontL,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                      fontSize: AppConstants.fontM,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Progress bar if needed
                  if (showProgress && progress != null) ...[
                    const SizedBox(height: AppConstants.paddingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: AppConstants.fontS,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${(progress! * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: AppConstants.fontS,
                                fontWeight: FontWeight.w600,
                                color: AppColors.studentPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.divider,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.studentPrimary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
