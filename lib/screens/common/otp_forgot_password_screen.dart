import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class OTPForgotPasswordScreen extends StatefulWidget {
  const OTPForgotPasswordScreen({super.key});

  @override
  State<OTPForgotPasswordScreen> createState() =>
      _OTPForgotPasswordScreenState();
}

class _OTPForgotPasswordScreenState extends State<OTPForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();

      // Check if user exists (optional - Firebase will handle this)
      try {
        final methods =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (methods.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No account found with this email address.',
          );
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Email not found.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Send password reset email using Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
                  const SizedBox(height: AppConstants.paddingL),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  Icon(
                    _emailSent ? Icons.email_outlined : Icons.lock_reset,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  Text(
                    _emailSent ? 'Check Your Email' : 'Forgot Password',
                    style: const TextStyle(
                      fontSize: AppConstants.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    _emailSent
                        ? 'We\'ve sent a password reset link to your email. Please check your inbox and follow the instructions.'
                        : 'Enter your email address and we\'ll send you a link to reset your password.',
                    style: const TextStyle(
                      fontSize: AppConstants.fontM,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingXL),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_emailSent,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: _emailSent,
                      fillColor:
                          _emailSent ? Colors.grey.withOpacity(0.1) : null,
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
                  const SizedBox(height: AppConstants.paddingXL),

                  // Action Button
                  if (!_emailSent)
                    CustomButton(
                      text: 'Send Reset Link',
                      onPressed: _sendResetEmail,
                      isLoading: _isLoading,
                      fullWidth: true,
                      backgroundColor: AppColors.primary,
                    )
                  else
                    Column(
                      children: [
                        CustomButton(
                          text: 'Back to Login',
                          onPressed: () => Navigator.pop(context),
                          fullWidth: true,
                          backgroundColor: AppColors.primary,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _emailSent = false);
                            _emailController.clear();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Send again'),
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
