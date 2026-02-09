import 'package:flutter/material.dart';
import '../screens/common/splash_screen.dart';
import '../screens/common/role_selection_screen.dart';
import '../screens/common/login_screen.dart';
import '../screens/common/register_screen.dart';
import '../screens/common/profile_screen.dart';
import '../screens/common/notifications_screen.dart';
import '../screens/common/forgot_password_screen.dart';
import '../screens/common/pending_verification_screen.dart';
import '../screens/common/settings_screen.dart';
import '../screens/common/help_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/lesson_detail_screen.dart';
import '../screens/student/quiz_detail_screen.dart';
import '../screens/student/ar_view_screen.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/teacher/student_approval_screen.dart';
import '../screens/teacher/score_reports_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_create_lesson_screen.dart';
import '../screens/admin/admin_create_quiz_screen.dart';
import '../screens/admin/account_verification_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String pendingVerification = '/pending-verification';
  static const String appSettings = '/settings';
  static const String help = '/help';

  // Student Routes
  static const String studentDashboard = '/student-dashboard';
  static const String lessonDetail = '/lesson-detail';
  static const String quizDetail = '/quiz-detail';
  static const String arView = '/ar-view';

  // Teacher Routes
  static const String teacherDashboard = '/teacher-dashboard';
  static const String teacherScoreReports = '/teacher-score-reports';
  static const String teacherApproveStudents = '/teacher-approve-students';

  // Admin Routes
  static const String adminDashboard = '/admin-dashboard';
  static const String adminVerifyAccounts = '/admin-verify-accounts';
  static const String adminCreateLesson = '/admin-create-lesson';
  static const String adminCreateQuiz = '/admin-create-quiz';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      roleSelection: (context) => const RoleSelectionScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      studentDashboard: (context) => const StudentDashboard(),
      teacherDashboard: (context) => const TeacherDashboard(),
      adminDashboard: (context) => const AdminDashboard(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        final role = settings.arguments as String? ?? 'student';
        return MaterialPageRoute(
          builder: (context) => LoginScreen(role: role),
        );

      case register:
        final role = settings.arguments as String? ?? 'student';
        return MaterialPageRoute(
          builder: (context) => RegisterScreen(role: role),
        );

      case profile:
        final role = settings.arguments as String? ?? 'student';
        return MaterialPageRoute(
          builder: (context) => ProfileScreen(role: role),
        );

      case appSettings:
        final role = settings.arguments as String? ?? 'student';
        return MaterialPageRoute(
          builder: (context) => SettingsScreen(role: role),
        );

      case help:
        final role = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (context) => HelpScreen(role: role),
        );

      case notifications:
        final role = settings.arguments as String? ?? 'student';
        return MaterialPageRoute(
          builder: (context) => NotificationsScreen(role: role),
        );

      case pendingVerification:
        final role = settings.arguments as String? ?? 'student';
        return MaterialPageRoute(
          builder: (context) => PendingVerificationScreen(role: role),
        );

      case adminVerifyAccounts:
        return MaterialPageRoute(
          builder: (context) => const AccountVerificationScreen(),
        );

      case adminCreateLesson:
        return MaterialPageRoute(
          builder: (context) => const AdminCreateLessonScreen(),
        );

      case adminCreateQuiz:
        return MaterialPageRoute(
          builder: (context) => const AdminCreateQuizScreen(),
        );

      case teacherScoreReports:
        return MaterialPageRoute(
          builder: (context) => const TeacherScoreReportsScreen(),
        );

      case teacherApproveStudents:
        return MaterialPageRoute(
          builder: (context) => const TeacherStudentApprovalScreen(),
        );

      case lessonDetail:
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) {
            if (args is Map<String, dynamic>) {
              return LessonDetailScreen(lessonData: args);
            } else if (args is String) {
              return LessonDetailScreen(lessonId: args);
            } else {
              return const LessonDetailScreen();
            }
          },
        );

      case quizDetail:
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) {
            if (args is Map<String, dynamic>) {
              return QuizDetailScreen(quizData: args);
            } else if (args is String) {
              return QuizDetailScreen(quizId: args);
            } else {
              return const QuizDetailScreen();
            }
          },
        );

      case arView:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (context) => ARViewScreen(
            lessonId: args['id'] ?? args['lessonId'] ?? '',
            lessonTitle: args['title'] ?? args['lessonTitle'] ?? 'AR View',
            arItems: List<String>.from(args['arItems'] ?? []),
            color: args['color'] as String?,
          ),
        );

      default:
        return null;
    }
  }
}
