import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class HelpScreen extends StatelessWidget {
  final String? role;

  const HelpScreen({super.key, this.role});

  Color get _roleColor {
    switch (role) {
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

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@ar-fusion.edu',
      queryParameters: {
        'subject': 'AR Fusion Technical Support',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1234567890');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Need Help?'),
        backgroundColor: _roleColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 64,
                      color: _roleColor,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    const Text(
                      'Technical Support',
                      style: TextStyle(
                        fontSize: AppConstants.fontXXL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    const Text(
                      'We\'re here to help you with any technical difficulties',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // Common Issues Section
            _SectionHeader(title: 'Common Issues', color: _roleColor),
            
            _HelpTile(
              icon: Icons.login,
              title: 'Can\'t Log In?',
              content: '• Check your internet connection\n'
                  '• Verify your email and password\n'
                  '• Use "Forgot Password" if needed\n'
                  '• Contact admin if account is locked',
            ),
            
            _HelpTile(
              icon: Icons.view_in_ar,
              title: 'AR Not Working?',
              content: '• Ensure camera permissions are enabled\n'
                  '• Check if device supports AR (Android 7.0+)\n'
                  '• Update Google Play Services for AR\n'
                  '• Try in a well-lit environment',
            ),
            
            _HelpTile(
              icon: Icons.school_outlined,
              title: 'Lessons Not Loading?',
              content: '• Check your internet connection\n'
                  '• Refresh the page by pulling down\n'
                  '• Clear app cache in Settings\n'
                  '• Restart the app',
            ),
            
            _HelpTile(
              icon: Icons.quiz_outlined,
              title: 'Quiz Issues?',
              content: '• Ensure stable internet connection\n'
                  '• Don\'t switch apps during quiz\n'
                  '• Contact teacher if answers not saving\n'
                  '• Report any quiz errors immediately',
            ),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // Contact Section
            _SectionHeader(title: 'Contact Support', color: _roleColor),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email_outlined, color: _roleColor),
                    title: const Text('Email Support'),
                    subtitle: const Text('support@ar-fusion.edu'),
                    onTap: _launchEmail,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.phone_outlined, color: _roleColor),
                    title: const Text('Phone Support'),
                    subtitle: const Text('Mon-Fri, 8AM-5PM'),
                    onTap: _launchPhone,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // Quick Tips Section
            _SectionHeader(title: 'Quick Tips', color: _roleColor),
            
            const _HelpTile(
              icon: Icons.lightbulb_outline,
              title: 'App Running Slow?',
              content: '• Close other apps running in background\n'
                  '• Clear app cache periodically\n'
                  '• Ensure sufficient storage space\n'
                  '• Update to latest app version',
            ),
            
            const _HelpTile(
              icon: Icons.battery_alert,
              title: 'Battery Draining Fast?',
              content: '• AR features use more battery\n'
                  '• Lower screen brightness during lessons\n'
                  '• Close app when not in use\n'
                  '• Use power saving mode if needed',
            ),
            
            const SizedBox(height: AppConstants.paddingXL),
            
            // Emergency Support
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: _roleColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.emergency, color: _roleColor, size: 32),
                  const SizedBox(height: AppConstants.paddingM),
                  const Text(
                    'Emergency Support',
                    style: TextStyle(
                      fontSize: AppConstants.fontL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  const Text(
                    'For urgent technical issues during exams or important deadlines, contact your teacher or administrator immediately.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppConstants.fontM,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingXL),
            
            // Version Info
            const Center(
              child: Text(
                'AR Fusion v1.0.0',
                style: TextStyle(
                  fontSize: AppConstants.fontS,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
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
        top: AppConstants.paddingM,
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

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingL,
              0,
              AppConstants.paddingL,
              AppConstants.paddingL,
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: AppConstants.fontM,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
