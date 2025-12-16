import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class PendingVerificationScreen extends StatefulWidget {
  final String role;

  const PendingVerificationScreen({super.key, required this.role});

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  bool _isRefreshing = false;

  Color get _roleColor {
    switch (widget.role) {
      case 'student':
        return AppColors.studentPrimary;
      case 'teacher':
        return AppColors.teacherPrimary;
      case 'admin':
        return AppColors.adminPrimary;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() => _isRefreshing = false);
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/role-selection',
          (route) => false,
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final data = userDoc.data();
      final role = (data != null && data['role'] is String)
          ? data['role'] as String
          : widget.role;
      final isVerified = (data != null && data['verified'] is bool)
          ? (data['verified'] as bool)
          : true;

      if (!mounted) return;
      setState(() => _isRefreshing = false);

      if (!isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is still pending verification.'),
          ),
        );
        return;
      }

      switch (role) {
        case 'teacher':
          Navigator.pushReplacementNamed(context, '/teacher-dashboard');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
          break;
        case 'student':
        default:
          Navigator.pushReplacementNamed(context, '/student-dashboard');
          break;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh. Please try again.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/role-selection',
      (route) => false,
    );
  }

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.paddingXL),
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: _roleColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_outlined,
                      size: 56,
                      color: _roleColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXL),
                Text(
                  'Account Pending Verification',
                  style: TextStyle(
                    fontSize: AppConstants.fontXXL,
                    fontWeight: FontWeight.bold,
                    color: _roleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingM),
                const Text(
                  'Your account was created successfully, but an administrator must verify it before you can access the app.',
                  style: TextStyle(
                    fontSize: AppConstants.fontL,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingXL),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What happens next?',
                          style: TextStyle(
                            fontSize: AppConstants.fontL,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        _StepRow(
                          index: '1',
                          title: 'Wait for admin approval',
                          description:
                              'An admin will review your account details.',
                          color: _roleColor,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        _StepRow(
                          index: '2',
                          title: 'Refresh your status',
                          description:
                              'Tap the refresh button to check if you are verified.',
                          color: _roleColor,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        _StepRow(
                          index: '3',
                          title: 'Login after verification',
                          description:
                              'Once verified, you will be redirected automatically.',
                          color: _roleColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                CustomButton(
                  text: 'Refresh Status',
                  onPressed: _isRefreshing ? null : _refreshStatus,
                  isLoading: _isRefreshing,
                  fullWidth: true,
                  backgroundColor: _roleColor,
                ),
                const SizedBox(height: AppConstants.paddingM),
                CustomButton(
                  text: 'Logout',
                  onPressed: _logout,
                  type: ButtonType.outlined,
                  fullWidth: true,
                  textColor: AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String index;
  final String title;
  final String description;
  final Color color;

  const _StepRow({
    required this.index,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            index,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppConstants.fontM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                description,
                style: const TextStyle(
                  fontSize: AppConstants.fontM,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
