import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/password_policy.dart';
import '../../utils/text_utils.dart';
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
  final _subjectController = TextEditingController(text: '');
  final _currentPasswordController = TextEditingController(text: '');
  final _newPasswordController = TextEditingController(text: '');
  final _confirmPasswordController = TextEditingController(text: '');

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _notificationsEnabled = true;
  String? _roleFromDb;
  String? _gradeLevel;
  String? _section;
  List<String> _subjects = <String>[];
  List<String> _sectionsHandled = <String>[];
  String? _profilePhotoUrl;

  final ImagePicker _imagePicker = ImagePicker();

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
        _nameController.text = (data['name'] as String?) ?? '';
        _emailController.text = (data['email'] as String?) ?? '';
        _roleFromDb = data['role'] as String?;
        _gradeLevel = data['gradeLevel'] as String?;
        _section = data['section'] as String?;
        _subjects = data['subjects'] != null
            ? normalizeTextList(List<String>.from(data['subjects']))
            : normalizeTextList([
                if ((data['subject'] as String?)?.trim().isNotEmpty ?? false)
                  (data['subject'] as String?)!,
              ]);
        _sectionsHandled = data['sectionsHandled'] != null
            ? normalizeTextList(List<String>.from(data['sectionsHandled']))
            : <String>[];
        _profilePhotoUrl = data['profilePhotoUrl'] as String?;
        _notificationsEnabled = (data['notificationsEnabled'] as bool?) ?? true;
        _subjectController.text = _subjects.join(', ');
      });
    } catch (_) {}
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final file = File(pickedFile.path);
      final fileName =
          'profile_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(currentUser.uid)
          .child(fileName);

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'profilePhotoUrl': downloadUrl});

      if (!mounted) return;

      setState(() {
        _profilePhotoUrl = downloadUrl;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: ${e.toString()}')),
      );
    }
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

      final newName = normalizePersonName(_nameController.text);
      final newEmail = _emailController.text.trim().toLowerCase();

      if (newName.isEmpty) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name is required')),
        );
        return;
      }

      String? gradeLevel = _gradeLevel;
      String? section = _section;
      String? subject;
      List<String> subjects = <String>[];

      if (widget.role == 'student' &&
          (gradeLevel == null ||
              gradeLevel.trim().isEmpty ||
              section == null ||
              section.trim().isEmpty)) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade level and section are required')),
        );
        return;
      }

      if (widget.role == 'teacher') {
        subjects = normalizeTextList(
          _subjectController.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty),
        );
        subject = subjects.isNotEmpty ? subjects.first : null;
      }

      if (newEmail.isNotEmpty && newEmail != currentUser.email) {
        await currentUser.verifyBeforeUpdateEmail(newEmail);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'A verification email has been sent to your new email address. Please verify it to complete the change.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      final updates = <String, dynamic>{
        'name': newName,
        'email': newEmail,
        'notificationsEnabled': _notificationsEnabled,
      };

      if (widget.role == 'student') {
        updates['gradeLevel'] = gradeLevel;
        updates['section'] = section;
      }

      if (subject != null && subject.isNotEmpty) {
        updates['subject'] = subject;
      }

      if (widget.role == 'teacher') {
        updates['subjects'] = subjects;
        updates['sectionsHandled'] = _sectionsHandled;
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
        _section = section ?? _section;
        _subjects = subjects.isNotEmpty ? subjects : _subjects;
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

  Future<void> _showChangePasswordDialog() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: PasswordPolicy.helperText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = _currentPasswordController.text.trim();
              final newPassword = _newPasswordController.text.trim();
              final confirmPassword = _confirmPasswordController.text.trim();

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All fields are required')),
                );
                return;
              }

              final passwordValidation = PasswordPolicy.validate(newPassword);
              if (passwordValidation != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(passwordValidation)),
                );
                return;
              }

              if (newPassword == currentPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'New password must be different from current password'),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No logged in user')),
                  );
                  return;
                }

                final credential = EmailAuthProvider.credential(
                  email: currentUser.email!,
                  password: currentPassword,
                );

                await currentUser.reauthenticateWithCredential(credential);
                await currentUser.updatePassword(newPassword);

                if (!mounted) return;
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password changed successfully')),
                );
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(e.message ?? 'Failed to change password')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
                        child: _profilePhotoUrl != null &&
                                _profilePhotoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  _profilePhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const CircleAvatar(
                                      backgroundColor: AppColors.surfaceLight,
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const CircleAvatar(
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
                            child: _isUploadingPhoto
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _roleColor,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.camera_alt,
                                        color: _roleColor),
                                    onPressed: _pickAndUploadPhoto,
                                  ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  Text(
                    normalizePersonName(_nameController.text),
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),

                    TextFormField(
                      controller: _emailController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),

                    if (widget.role == 'student') ...[
                      DropdownButtonFormField<String>(
                        value: _gradeLevel,
                        decoration: const InputDecoration(
                          labelText: 'Grade Level',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: AppConstants.gradeLevels
                            .map(
                              (grade) => DropdownMenuItem<String>(
                                value: grade,
                                child: Text(grade),
                              ),
                            )
                            .toList(),
                        onChanged: _isEditing
                            ? (value) => setState(() => _gradeLevel = value)
                            : null,
                      ),
                      const SizedBox(height: AppConstants.paddingL),
                      DropdownButtonFormField<String>(
                        value: _section,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        items: AppConstants.studentSections
                            .map(
                              (section) => DropdownMenuItem<String>(
                                value: section,
                                child: Text(section),
                              ),
                            )
                            .toList(),
                        onChanged: _isEditing
                            ? (value) => setState(() => _section = value)
                            : null,
                      ),
                    ],

                    if (widget.role == 'teacher')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _subjectController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Subject(s)',
                              prefixIcon: Icon(Icons.book_outlined),
                              helperText:
                                  'Enter one or more subjects separated by commas',
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingL),

                          // Sections Handled (Optional for teachers)
                          if (_isEditing)
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
                                  children: AppConstants.studentSections
                                      .map((section) {
                                    final isSelected =
                                        _sectionsHandled.contains(section);
                                    return FilterChip(
                                      label: Text(section),
                                      selected: isSelected,
                                      onSelected: _isEditing
                                          ? (selected) {
                                              setState(() {
                                                if (selected) {
                                                  if (!_sectionsHandled
                                                      .contains(section)) {
                                                    _sectionsHandled
                                                        .add(section);
                                                  }
                                                } else {
                                                  _sectionsHandled
                                                      .remove(section);
                                                }
                                              });
                                            }
                                          : null,
                                      selectedColor:
                                          _roleColor.withOpacity(0.2),
                                      checkmarkColor: _roleColor,
                                    );
                                  }).toList(),
                                ),
                              ],
                            )
                          else if (_sectionsHandled.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: AppConstants.paddingM),
                              child: Wrap(
                                spacing: AppConstants.paddingS,
                                runSpacing: AppConstants.paddingS,
                                children: _sectionsHandled.map((section) {
                                  return Chip(
                                    label: Text(section),
                                    backgroundColor:
                                        _roleColor.withOpacity(0.1),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
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
                        value: _notificationsEnabled,
                        onChanged: (value) async {
                          setState(() => _notificationsEnabled = value);
                          await _saveProfile();
                        },
                        activeColor: _roleColor,
                      ),
                    ),

                    _SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: _showChangePasswordDialog,
                    ),

                    _SettingsTile(
                      icon: Icons.settings_outlined,
                      title: 'App Settings',
                      subtitle: 'Theme, notifications, AR',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/settings',
                          arguments: widget.role,
                        );
                      },
                    ),

                    _SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Need Help?',
                      subtitle: 'Get support',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/help',
                          arguments: widget.role,
                        );
                      },
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
