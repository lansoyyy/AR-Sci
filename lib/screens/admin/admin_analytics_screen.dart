import 'package:flutter/material.dart';

import '../teacher/teacher_analytics_screen.dart';
import '../../utils/colors.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeacherAnalyticsScreen(
      includeAllContent: true,
      screenTitle: 'Analytics Dashboard',
      accentColor: AppColors.adminPrimary,
    );
  }
}
