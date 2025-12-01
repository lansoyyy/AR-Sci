import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _selectedGrade;
  String? _selectedSubject;

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

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate registration
      try {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
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

        String? gradeLevel;
        String? subject;

        if (widget.role == 'student') {
          gradeLevel = _selectedGrade ?? 'Grade 9';
        } else if (widget.role == 'teacher') {
          subject = _selectedSubject;
        }

        final userModel = UserModel(
          id: user.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: widget.role,
          gradeLevel: gradeLevel,
          subject: subject,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());

        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(
          context,
          '/login',
          arguments: widget.role,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Failed to register. Please try again.',
            ),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  const SizedBox(height: AppConstants.paddingL),

                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Title
                  Text(
                    'Create ${widget.role.toUpperCase()} Account',
                    style: TextStyle(
                      fontSize: AppConstants.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: _roleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppConstants.paddingL),

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

                  // Role-specific fields
                  if (widget.role == 'student') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: const InputDecoration(
                        labelText: 'Grade Level',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: AppConstants.gradeLevels.map((grade) {
                        return DropdownMenuItem(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedGrade = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your grade level';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                  ],

                  if (widget.role == 'teacher') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.book_outlined),
                      ),
                      items: AppConstants.subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSubject = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                  ],

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
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Register Button
                  CustomButton(
                    text: 'Register',
                    onPressed: _handleRegister,
                    isLoading: _isLoading,
                    fullWidth: true,
                    backgroundColor: _roleColor,
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Login',
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
