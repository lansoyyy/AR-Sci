import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/quiz_model.dart';

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback? onTap;
  final QuizResult? result;
  final bool showResult;

  const QuizCard({
    super.key,
    required this.quiz,
    this.onTap,
    this.result,
    this.showResult = false,
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
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.studentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: AppColors.studentPrimary,
                  size: AppConstants.iconL,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      '${quiz.questions.length} questions • ${quiz.duration} min',
                      style: const TextStyle(
                        fontSize: AppConstants.fontS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (showResult && result != null) ...[
                      const SizedBox(height: AppConstants.paddingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingM,
                          vertical: AppConstants.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(result!.percentage).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                        ),
                        child: Text(
                          'Score: ${result!.score}/${result!.totalPoints} (${result!.percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: AppConstants.fontS,
                            fontWeight: FontWeight.w600,
                            color: _getScoreColor(result!.percentage),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                size: AppConstants.iconS,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }
}
