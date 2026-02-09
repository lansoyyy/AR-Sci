import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  final String role;

  const SettingsScreen({super.key, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoPlayAR = true;
  String _selectedLanguage = 'English';
  String? _profilePhotoUrl;
  String? _userName;
  bool _isLoading = true;

  final List<String> _languages = ['English', 'Filipino', 'Cebuano'];

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
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final data = snapshot.data();
      if (data != null && mounted) {
        setState(() {
          _notificationsEnabled = (data['notificationsEnabled'] as bool?) ?? true;
          _autoPlayAR = (data['autoPlayAR'] as bool?) ?? true;
          _selectedLanguage = (data['language'] as String?) ?? 'English';
          _profilePhotoUrl = data['profilePhotoUrl'] as String?;
          _userName = data['name'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
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

  Future<void> _showLanguageDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (result != null && result != _selectedLanguage) {
      setState(() => _selectedLanguage = result);
      await _saveSetting('language', result);
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
                  icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  title: 'Theme',
                  subtitle: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
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
                
                // Language Section
                _SectionHeader(title: 'Language & Region', color: _roleColor),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: _selectedLanguage,
                  onTap: _showLanguageDialog,
                ),
                
                const SizedBox(height: AppConstants.paddingL),
                
                // Account Section
                _SectionHeader(title: 'Account', color: _roleColor),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.pushNamed(context, '/forgot-password');
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
