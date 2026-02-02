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
  String? _selectedSection;
  String? _selectedSubject;
  List<String> _selectedSectionsHandled = [];

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

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        // Check if email already exists in Firestore (prevent duplicates)
        final existingUser = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingUser.docs.isNotEmpty) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'This email is already registered. Please use a different email or login.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        // Create user in Firebase Auth
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
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

        String? gradeLevel;
        String? section;
        String? subject;
        List<String>? subjects;
        List<String>? sectionsHandled;

        if (widget.role == 'student') {
          gradeLevel = _selectedGrade ?? 'Grade 9';
          section = _selectedSection;
        } else if (widget.role == 'teacher') {
          // Teachers must select at least one subject
          if (_selectedSubject == null) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a subject'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
          subject = _selectedSubject;
          subjects = _selectedSubject != null ? [_selectedSubject!] : null;
          
          // Teachers can optionally select sections they handle
          if (_selectedSectionsHandled.isNotEmpty) {
            sectionsHandled = _selectedSectionsHandled;
          }
        }

        final userModel = UserModel(
          id: user.uid,
          name: _nameController.text.trim(),
          email: email,
          role: widget.role,
          gradeLevel: gradeLevel,
          section: section,
          subject: subject,
          subjects: subjects,
          sectionsHandled: sectionsHandled,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          ...userModel.toJson(),
          'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
          'verified': false, // All new accounts require verification
        });

        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(
          context,
          '/pending-verification',
          arguments: widget.role,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        String errorMessage = 'Failed to register. Please try again.';
        if (e.code == 'email-already-in-use') {
          errorMessage =
              'This email is already in use. Please use a different email.';
        } else if (e.code == 'weak-password') {
          errorMessage =
              'The password is too weak. Please use a stronger password.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        } else if (e.message != null) {
          errorMessage = e.message!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'An unexpected error occurred. Please try again. Error: $e'),
            backgroundColor: AppColors.error,
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
                      labelText: 'ICCT Email',
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

                    DropdownButtonFormField<String>(
                      value: _selectedSection,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      items: AppConstants.studentSections.map((section) {
                        return DropdownMenuItem(
                          value: section,
                          child: Text(section),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSection = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your section';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                  ],

                  // Teacher-specific fields
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
                          return 'Please select a subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),

                    // Sections handled (optional for teachers)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sections Handled (Optional)',
                          style: TextStyle(
                            fontSize: AppConstants.fontM,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        Wrap(
                          spacing: AppConstants.paddingS,
                          runSpacing: AppConstants.paddingS,
                          children: AppConstants.studentSections.map((section) {
                            final isSelected = _selectedSectionsHandled.contains(section);
                            return FilterChip(
                              label: Text(section),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSectionsHandled.add(section);
                                  } else {
                                    _selectedSectionsHandled.remove(section);
                                  }
                                });
                              },
                              selectedColor: _roleColor.withOpacity(0.2),
                              checkmarkColor: _roleColor,
                            );
                          }).toList(),
                        ),
                      ],
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
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(r'(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
                        return 'Password must contain both letters and numbers';
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
