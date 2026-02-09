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
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleController.forward();
    _rotationController.repeat();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _fadeController.forward();
    });
    
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/role-selection');
      return;
    }

    String role = 'student';
    bool isVerified = true;
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
        if (data != null && data['verified'] is bool) {
          isVerified = data['verified'] as bool;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    if (!isVerified) {
      Navigator.pushReplacementNamed(
        context,
        '/pending-verification',
        arguments: role,
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
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.textWhite,
                          borderRadius: BorderRadius.circular(AppConstants.radiusL),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.radiusL),
                          child: Image.asset(
                            'assets/images/school_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.school_outlined,
                                size: 50,
                                color: AppColors.primary,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXL),
                    
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Welcome to',
                            style: TextStyle(
                              fontSize: AppConstants.fontXXL,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingS),
                          const Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.paddingM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingL,
                              vertical: AppConstants.paddingS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textWhite.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                            ),
                            child: const Text(
                              'Step into the future of science learning',
                              style: TextStyle(
                                fontSize: AppConstants.fontM,
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXXL),
                    
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.textWhite,
                          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.view_in_ar,
                                size: 40,
                                color: AppColors.primary,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXXL),
                    
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                          ),
                          SizedBox(height: AppConstants.paddingL),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: AppConstants.fontM,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
