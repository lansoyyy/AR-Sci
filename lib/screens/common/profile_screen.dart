import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  final String role;

  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: '');
  final _emailController = TextEditingController(text: '');
  final _gradeController = TextEditingController(text: 'Grade 9');
  final _subjectController = TextEditingController(text: 'Physics');
  bool _isEditing = false;
  bool _isSaving = false;
  String? _roleFromDb;
  String? _gradeLevel;
  String? _subject;

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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final data = snapshot.data();
      if (data == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _nameController.text =
            (data['name'] as String?) ?? _nameController.text;
        _emailController.text =
            (data['email'] as String?) ?? _emailController.text;
        _roleFromDb = data['role'] as String?;
        _gradeLevel = data['gradeLevel'] as String?;
        _subject = data['subject'] as String?;

        if (_gradeLevel != null && _gradeLevel!.isNotEmpty) {
          _gradeController.text = _gradeLevel!;
        }
        if (_subject != null && _subject!.isNotEmpty) {
          _subjectController.text = _subject!;
        }
      });
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isSaving = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No logged in user. Please login again.'),
          ),
        );
        return;
      }

      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();

      String? gradeLevel;
      String? subject;

      if (widget.role == 'student') {
        gradeLevel = _gradeController.text.trim();
      }

      if (widget.role == 'teacher') {
        subject = _subjectController.text.trim();
      }

      if (newEmail.isNotEmpty && newEmail != currentUser.email) {
        await currentUser.updateEmail(newEmail);
      }

      final updates = <String, dynamic>{
        'name': newName,
        'email': newEmail,
      };

      if (gradeLevel != null && gradeLevel.isNotEmpty) {
        updates['gradeLevel'] = gradeLevel;
      }

      if (subject != null && subject.isNotEmpty) {
        updates['subject'] = subject;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(updates);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isEditing = false;
        _gradeLevel = gradeLevel ?? _gradeLevel;
        _subject = subject ?? _subject;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Failed to update profile. Please try again.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gradeController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: _roleColor,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_roleColor, _roleColor.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Profile Photo
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textWhite,
                          border: Border.all(
                            color: AppColors.textWhite,
                            width: 4,
                          ),
                        ),
                        child: const CircleAvatar(
                          backgroundColor: AppColors.surfaceLight,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.textWhite,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, color: _roleColor),
                              onPressed: () {
                                // Handle photo upload
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: AppConstants.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                      vertical: AppConstants.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textWhite.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusRound),
                    ),
                    child: Text(
                      (_roleFromDb ?? widget.role).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Personal Information
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingL),

                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingL),

                    TextFormField(
                      controller: _emailController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingL),

                    if (widget.role == 'student')
                      TextFormField(
                        controller: _gradeController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Grade Level',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),

                    if (widget.role == 'teacher')
                      TextFormField(
                        controller: _subjectController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                      ),

                    const SizedBox(height: AppConstants.paddingXL),

                    // Settings Section
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingL),

                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {},
                        activeColor: _roleColor,
                      ),
                    ),

                    _SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {},
                    ),

                    _SettingsTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),

                    const SizedBox(height: AppConstants.paddingXL),

                    // Save Button (shown when editing)
                    if (_isEditing)
                      CustomButton(
                        text: 'Save Changes',
                        onPressed: _isSaving
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _saveProfile();
                                }
                              },
                        isLoading: _isSaving,
                        fullWidth: true,
                        backgroundColor: _roleColor,
                      ),

                    const SizedBox(height: AppConstants.paddingL),

                    // Logout Button
                    CustomButton(
                      text: 'Logout',
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/role-selection',
                          (route) => false,
                        );
                      },
                      type: ButtonType.outlined,
                      fullWidth: true,
                      textColor: AppColors.error,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
