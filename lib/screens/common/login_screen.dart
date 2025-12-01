import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          );
        }

        String role = widget.role;
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
          }
        } catch (_) {}

        if (!mounted) return;
        setState(() => _isLoading = false);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Failed to login. Please try again.'),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
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

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: _roleColor),
                      ),
                    ),
                  ),

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

                  // Register Link
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
