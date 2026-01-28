import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';

class QuizDetailScreen extends StatelessWidget {
  const QuizDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final quiz = args is Map<String, dynamic> ? args : <String, dynamic>{};

    final title = (quiz['title'] ?? 'Quiz').toString();
    final description = (quiz['description'] ?? '').toString();
    final subject = (quiz['subject'] ?? '').toString();
    final grade = (quiz['gradeLevel'] ?? quiz['grade'] ?? '').toString();

    final rawQuestions = quiz['questions'] as List? ?? const [];
    final questionsCount = rawQuestions.length;

    final duration = quiz['duration'] is int
        ? quiz['duration'] as int
        : int.tryParse((quiz['duration'] ?? '').toString()) ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (subject.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM,
                      vertical: AppConstants.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.studentPrimary,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusRound),
                    ),
                    child: Text(
                      subject,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: AppConstants.fontS,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (grade.isNotEmpty) ...[
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
                      grade,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppConstants.fontS,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppConstants.fontXXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingM),
              Text(
                description,
                style: const TextStyle(
                  fontSize: AppConstants.fontL,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: AppConstants.paddingXL),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuizMeta(
                      label: 'Questions',
                      value: questionsCount.toString(),
                    ),
                    _QuizMeta(
                      label: 'Duration',
                      value: '$duration min',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),
            const Text(
              'Questions',
              style: TextStyle(
                fontSize: AppConstants.fontXL,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (rawQuestions.isEmpty)
              const Text(
                'No questions added yet.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...List.generate(rawQuestions.length, (index) {
                final q = rawQuestions[index];
                final map = q is Map
                    ? Map<String, dynamic>.from(q)
                    : <String, dynamic>{};
                final questionText = (map['question'] ?? 'Question').toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Text(
                      '${index + 1}. $questionText',
                      style: const TextStyle(
                        fontSize: AppConstants.fontL,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _QuizMeta extends StatelessWidget {
  final String label;
  final String value;

  const _QuizMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppConstants.fontS,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppConstants.fontL,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
