import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isAccountLocked = false;
  DateTime? _lockoutEndTime;
  int _remainingLockoutSeconds = 0;
  static const int _maxFailedAttempts = 3;

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

  IconData get _roleIcon {
    switch (widget.role) {
      case 'student':
        return Icons.school_outlined;
      case 'teacher':
        return Icons.person_outline;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person;
    }
  }

  // Generate a unique key for storing failed attempts based on email and role
  String _getFailedAttemptsKey(String email) {
    return 'failed_attempts_${email}_${widget.role}';
  }

  // Generate a unique key for storing lockout end time
  String _getLockoutEndTimeKey(String email) {
    return 'lockout_end_time_${email}_${widget.role}';
  }

  // Check if the account is currently locked out
  Future<bool> _isLockedOut(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEndTimeMs = prefs.getInt(_getLockoutEndTimeKey(email));
    if (lockoutEndTimeMs == null) return false;

    final lockoutEndTime =
        DateTime.fromMillisecondsSinceEpoch(lockoutEndTimeMs);
    final now = DateTime.now();

    if (now.isBefore(lockoutEndTime)) {
      setState(() {
        _isAccountLocked = true;
        _lockoutEndTime = lockoutEndTime;
        _remainingLockoutSeconds = lockoutEndTime.difference(now).inSeconds;
      });
      _startLockoutTimer();
      return true;
    } else {
      // Lockout period has expired, clear the lockout data
      await _clearLockoutData(email);
      return false;
    }
  }

  // Increment failed attempts and check if account should be locked
  Future<void> _handleFailedAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getFailedAttemptsKey(email);
    final currentAttempts = prefs.getInt(key) ?? 0;
    final newAttempts = currentAttempts + 1;

    await prefs.setInt(key, newAttempts);

    if (newAttempts >= _maxFailedAttempts) {
      // Lock the account for 1-5 minutes (random duration for security)
      final random = DateTime.now().millisecond;
      final lockoutMinutes = 1 + (random % 5); // 1 to 5 minutes
      final lockoutEndTime =
          DateTime.now().add(Duration(minutes: lockoutMinutes));

      await prefs.setInt(
          _getLockoutEndTimeKey(email), lockoutEndTime.millisecondsSinceEpoch);

      setState(() {
        _isAccountLocked = true;
        _lockoutEndTime = lockoutEndTime;
        _remainingLockoutSeconds = lockoutMinutes * 60;
      });

      _startLockoutTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account locked for $lockoutMinutes minute${lockoutMinutes > 1 ? 's' : ''} due to too many failed attempts.',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      final remainingAttempts = _maxFailedAttempts - newAttempts;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Incorrect password. $remainingAttempts attempt${remainingAttempts > 1 ? 's' : ''} remaining before account lockout.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Clear all lockout data for an email
  Future<void> _clearLockoutData(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getFailedAttemptsKey(email));
    await prefs.remove(_getLockoutEndTimeKey(email));
    setState(() {
      _isAccountLocked = false;
      _lockoutEndTime = null;
      _remainingLockoutSeconds = 0;
    });
  }

  // Start the countdown timer for lockout
  void _startLockoutTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      final now = DateTime.now();
      if (_lockoutEndTime == null || now.isAfter(_lockoutEndTime!)) {
        final email = _emailController.text.trim();
        await _clearLockoutData(email);
        return false;
      }

      setState(() {
        _remainingLockoutSeconds = _lockoutEndTime!.difference(now).inSeconds;
      });
      return true;
    });
  }

  // Format seconds to MM:SS format
  String _formatLockoutTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Check if account is locked out
      if (await _isLockedOut(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account is locked. Please try again in ${_formatLockoutTime(_remainingLockoutSeconds)}.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Hardcoded admin account check
      if (widget.role == 'admin' &&
          email == 'admin@lcct.edu.ph' &&
          password == 'Admin1234!') {
        // Simulate admin login without Firebase Auth
        if (!mounted) return;
        setState(() => _isLoading = false);
        // Clear failed attempts on successful login
        await _clearLockoutData(email);
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
        return;
      }

      try {
        // Firebase Auth for all roles (students, teachers, and admins)
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          );
        }

        String role = widget.role;
        bool isVerified = true;
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
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
        setState(() => _isLoading = false);

        // Clear failed attempts on successful login
        await _clearLockoutData(email);

        // Verify that the logged-in user's role matches the selected role
        if (role != widget.role) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This account is registered as a $role, not ${widget.role}.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          await FirebaseAuth.instance.signOut();
          return;
        }

        // Admins bypass verification check
        if (role != 'admin' && !isVerified) {
          Navigator.pushReplacementNamed(
            context,
            '/pending-verification',
            arguments: role,
          );
          return;
        }

        switch (role) {
          case 'student':
            Navigator.pushReplacementNamed(context, '/student-dashboard');
            break;
          case 'teacher':
            Navigator.pushReplacementNamed(context, '/teacher-dashboard');
            break;
          case 'admin':
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
            break;
          default:
            Navigator.pushReplacementNamed(context, '/student-dashboard');
            break;
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        // Handle failed attempt for wrong password
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          await _handleFailedAttempt(email);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Failed to login. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.softGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppConstants.paddingXL),

                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Role Icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _roleColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _roleIcon,
                        size: 50,
                        color: _roleColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Title
                  Text(
                    '${widget.role.toUpperCase()} LOGIN',
                    style: TextStyle(
                      fontSize: AppConstants.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: _roleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: AppConstants.fontL,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppConstants.paddingM),

                  // Forgot Password - enabled for students and teachers
                  if (widget.role != 'admin')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, AppRoutes.otpForgotPassword);
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: _roleColor),
                        ),
                      ),
                    ),

                  // const SizedBox(height: AppConstants.paddingL),

                  // Lockout Warning Card
                  if (_isAccountLocked)
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock_clock,
                                color: AppColors.error,
                                size: 24,
                              ),
                              const SizedBox(width: AppConstants.paddingS),
                              Expanded(
                                child: Text(
                                  'Account Temporarily Locked',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppConstants.fontM,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.paddingS),
                          Text(
                            'Too many failed login attempts. Please wait before trying again.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppConstants.fontS,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingM,
                              vertical: AppConstants.paddingS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusS),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: AppConstants.paddingXS),
                                Text(
                                  'Try again in: ${_formatLockoutTime(_remainingLockoutSeconds)}',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                    fontSize: AppConstants.fontM,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_isAccountLocked)
                    const SizedBox(height: AppConstants.paddingL),

                  // Login Button
                  CustomButton(
                    text: 'Login',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    fullWidth: true,
                    backgroundColor: _roleColor,
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Register Link - only for students and teachers
                  if (widget.role != 'admin')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register',
                                arguments: widget.role);
                          },
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: _roleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
