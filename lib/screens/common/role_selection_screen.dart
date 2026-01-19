import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.softGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              children: [
                const SizedBox(height: AppConstants.paddingXL),

                // Header
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: AppConstants.fontXL,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: AppConstants.fontDisplay,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                const Text(
                  'Select your role to continue',
                  style: TextStyle(
                    fontSize: AppConstants.fontL,
                    color: AppColors.textSecondary,
                  ),
                ),

                const Spacer(),

                // Role Cards
                _RoleCard(
                  title: 'Student',
                  description:
                      'Access lessons, take quizzes, and track your progress',
                  icon: Icons.school_outlined,
                  color: AppColors.studentPrimary,
                  onTap: () => Navigator.pushNamed(context, '/login',
                      arguments: 'student'),
                ),
                const SizedBox(height: AppConstants.paddingL),

                _RoleCard(
                  title: 'Teacher',
                  description:
                      'Create lessons, manage quizzes, and monitor students',
                  icon: Icons.person_outline,
                  color: AppColors.teacherPrimary,
                  onTap: () => Navigator.pushNamed(context, '/login',
                      arguments: 'teacher'),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  icon,
                  size: AppConstants.iconXL,
                  color: color,
                ),
              ),
              const SizedBox(width: AppConstants.paddingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppConstants.fontXL,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: AppConstants.iconM,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
