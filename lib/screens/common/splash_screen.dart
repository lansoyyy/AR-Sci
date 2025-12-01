import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Keep splash visible for a short time
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/role-selection');
      return;
    }

    String role = 'student';
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['role'] is String) {
          role = data['role'] as String;
        }
      }
    } catch (_) {}

    if (!mounted) return;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.textWhite,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXL),

                  // App Name
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: AppConstants.fontDisplay,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),

                  // Tagline
                  const Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      fontSize: AppConstants.fontL,
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXXL),

                  // Loading Indicator
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
