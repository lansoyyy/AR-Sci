import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/text_utils.dart';

class SettingsScreen extends StatefulWidget {
  final String role;

  const SettingsScreen({super.key, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoPlayAR = true;
  String? _profilePhotoUrl;
  String? _userName;
  bool _isLoading = true;
  bool _isSavingAcademicYear = false;
  String? _selectedAcademicYear;
  final List<String> _defaultYears = const <String>[
    '2025-2026',
    '2026-2027',
    '2027-2028',
    '2028-2029',
    '2029-2030',
  ];
  List<String> _availableYears = <String>[];

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
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      bool notificationsEnabled = true;
      bool autoPlayAR = true;
      String? profilePhotoUrl;
      String? userName;
      String? selectedAcademicYear;
      List<String> availableYears = <String>[];

      if (currentUser != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final data = snapshot.data();
        if (data != null) {
          notificationsEnabled =
              (data['notificationsEnabled'] as bool?) ?? true;
          autoPlayAR = (data['autoPlayAR'] as bool?) ?? true;
          profilePhotoUrl = data['profilePhotoUrl'] as String?;
          userName = normalizePersonName((data['name'] as String?) ?? '');
        }
      }

      if (widget.role == 'admin') {
        final configDoc = await FirebaseFirestore.instance
            .collection('app_config')
            .doc('current')
            .get();
        final configData = configDoc.data();
        selectedAcademicYear =
            (configData?['academicYear'] as String?) ?? '2025-2026';
        final customYears = configData?['customYears'] != null
            ? List<String>.from(configData!['customYears'])
            : <String>[];
        availableYears = {..._defaultYears, ...customYears}.toList();
        if (!availableYears.contains(selectedAcademicYear)) {
          availableYears.add(selectedAcademicYear);
        }
        availableYears.sort();
      }

      if (!mounted) return;
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _autoPlayAR = autoPlayAR;
        _profilePhotoUrl = profilePhotoUrl;
        _userName = userName;
        _selectedAcademicYear = selectedAcademicYear;
        _availableYears = availableYears;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({key: value});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save setting: ${e.toString()}')),
        );
      }
    }
  }

  void _showThemeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: const Row(
                children: [
                  Icon(Icons.light_mode),
                  SizedBox(width: 12),
                  Text('Light Mode'),
                ],
              ),
              value: false,
              groupValue: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setDarkMode(false);
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: const Row(
                children: [
                  Icon(Icons.dark_mode),
                  SizedBox(width: 12),
                  Text('Dark Mode'),
                ],
              ),
              value: true,
              groupValue: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setDarkMode(true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAcademicYearSettings() async {
    if (widget.role != 'admin' || _selectedAcademicYear == null) {
      return;
    }

    setState(() => _isSavingAcademicYear = true);
    try {
      final customYears = _availableYears
          .where((year) => !_defaultYears.contains(year))
          .toList();
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('current')
          .set({
        'academicYear': _selectedAcademicYear,
        'customYears': customYears,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Academic year updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update academic year: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAcademicYear = false);
      }
    }
  }

  Future<void> _showAcademicYearDialog() async {
    String? tempSelected = _selectedAcademicYear;
    final tempYears = List<String>.from(_availableYears);

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Select Academic Year'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView(
                    shrinkWrap: true,
                    children: tempYears
                        .map(
                          (year) => RadioListTile<String>(
                            title: Text(year),
                            value: year,
                            groupValue: tempSelected,
                            activeColor: _roleColor,
                            onChanged: (value) {
                              setStateDialog(() => tempSelected = value);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Year'),
                  onPressed: () async {
                    final controller = TextEditingController();
                    final newYear = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Academic Year'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 2030-2031',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final value = controller.text.trim();
                              if (value.isNotEmpty) {
                                Navigator.pop(context, value);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _roleColor,
                              foregroundColor: AppColors.textWhite,
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );

                    if (newYear != null && !tempYears.contains(newYear)) {
                      setStateDialog(() {
                        tempYears.add(newYear);
                        tempYears.sort();
                        tempSelected = newYear;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (tempSelected != _selectedAcademicYear ||
        tempYears.length != _availableYears.length) {
      setState(() {
        _selectedAcademicYear = tempSelected;
        _availableYears = tempYears;
      });
      await _saveAcademicYearSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _roleColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              children: [
                // User Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _profilePhotoUrl != null
                              ? NetworkImage(_profilePhotoUrl!)
                              : null,
                          child: _profilePhotoUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(width: AppConstants.paddingL),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName ?? 'User',
                                style: const TextStyle(
                                  fontSize: AppConstants.fontL,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingS),
                              Text(
                                widget.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: AppConstants.fontM,
                                  color: _roleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingL),

                // Appearance Section
                _SectionHeader(title: 'Appearance', color: _roleColor),
                _SettingsTile(
                  icon: themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  title: 'Theme',
                  subtitle:
                      themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  onTap: _showThemeDialog,
                ),

                const SizedBox(height: AppConstants.paddingL),

                // Notifications Section
                _SectionHeader(title: 'Notifications', color: _roleColor),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Receive updates and alerts',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      await _saveSetting('notificationsEnabled', value);
                    },
                    activeColor: _roleColor,
                  ),
                ),

                const SizedBox(height: AppConstants.paddingL),

                // AR Settings Section
                _SectionHeader(title: 'AR Experience', color: _roleColor),
                _SettingsTile(
                  icon: Icons.view_in_ar,
                  title: 'Auto-launch AR',
                  subtitle: 'Automatically start AR when available',
                  trailing: Switch(
                    value: _autoPlayAR,
                    onChanged: (value) async {
                      setState(() => _autoPlayAR = value);
                      await _saveSetting('autoPlayAR', value);
                    },
                    activeColor: _roleColor,
                  ),
                ),

                const SizedBox(height: AppConstants.paddingL),

                // Account Section
                _SectionHeader(title: 'Account', color: _roleColor),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.changePassword);
                  },
                ),
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Need Help?',
                  subtitle: 'Get support for technical issues',
                  onTap: () {
                    Navigator.pushNamed(context, '/help');
                  },
                ),

                if (widget.role == 'admin') ...[
                  const SizedBox(height: AppConstants.paddingL),
                  _SectionHeader(title: 'Administration', color: _roleColor),
                  _SettingsTile(
                    icon: Icons.school_outlined,
                    title: 'Academic Year',
                    subtitle: _selectedAcademicYear ?? 'Set active school year',
                    trailing: _isSavingAcademicYear
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _showAcademicYearDialog,
                  ),
                ],

                const SizedBox(height: AppConstants.paddingXL),

                // App Info
                Center(
                  child: Column(
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: AppConstants.fontL,
                          fontWeight: FontWeight.bold,
                          color: _roleColor,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      const Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: AppConstants.fontM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.paddingM,
        bottom: AppConstants.paddingS,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppConstants.fontM,
          fontWeight: FontWeight.w600,
          color: color,
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
