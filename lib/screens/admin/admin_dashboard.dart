import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/settings_screen.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../routes/app_routes.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';
import '../../models/user_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  Future<void> _handleBackPressed() async {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens = [
      _DashboardHome(
          onNavigate: (index) => setState(() => _selectedIndex = index)),
      const _UserManagement(),
      const _ContentManagement(),
      const SettingsScreen(role: 'admin'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.adminPrimary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'Content',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  final Function(int) onNavigate;

  const _DashboardHome({required this.onNavigate});

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  bool _isLessonArReady(Map<String, dynamic> lesson) {
    final arItems = (lesson['arItems'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final modelUrl = (lesson['arModelUrl'] ?? '').toString().trim();
    return arItems.isNotEmpty || modelUrl.isNotEmpty;
  }

  Future<void> _openAdminArExperience() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .where('isPublished', isEqualTo: true)
          .limit(50)
          .get();

      final arReadyLessons = snapshot.docs
          .map((doc) => <String, dynamic>{
                ...doc.data(),
                'id': doc.data()['id'] ?? doc.id,
              })
          .where(_isLessonArReady)
          .toList();

      if (arReadyLessons.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No AR-ready lessons are available right now.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.lessonDetail,
        arguments: arReadyLessons.first,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open AR experience. $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.adminPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.notifications,
                arguments: 'admin',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.profile,
                arguments: 'admin',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textWhite,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/role-selection',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.adminPrimary,
                    AppColors.adminLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: AppConstants.fontL,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingS),
                            const Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: AppConstants.fontXXL,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingM,
                                vertical: AppConstants.paddingS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textWhite.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusRound),
                              ),
                              child: const Text(
                                'System Administrator',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('app_config')
                            .doc('current')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final year = snapshot.data?.data()?['academicYear']
                                  as String? ??
                              '2025-2026';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                year,
                                style: const TextStyle(
                                  fontSize: AppConstants.fontXL,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite,
                                ),
                              ),
                              const Text(
                                'Academic Year',
                                style: TextStyle(
                                  fontSize: AppConstants.fontS,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingL),

            // System Stats - Real-time from Firestore
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final totalUsers = snapshot.data?.docs.length ?? 0;
                        return StatCard(
                          title: 'Total Users',
                          value: totalUsers.toString(),
                          icon: Icons.people_outline,
                          color: AppColors.adminPrimary,
                          onTap: () => widget.onNavigate(1),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final activeUsers =
                            (snapshot.data?.docs ?? []).where((doc) {
                          final data = doc.data();
                          return data['verified'] == true &&
                              data['deleted'] != true &&
                              data['deactivated'] != true;
                        }).length;
                        return StatCard(
                          title: 'Active',
                          value: activeUsers.toString(),
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                          subtitle: 'Verified',
                          onTap: () => widget.onNavigate(1),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingM),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('lessons')
                          .where('isPublished', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final lessons = snapshot.data?.docs.length ?? 0;
                        return StatCard(
                          title: 'Lessons',
                          value: lessons.toString(),
                          icon: Icons.book_outlined,
                          color: AppColors.studentPrimary,
                          subtitle: 'Published',
                          onTap: () => widget.onNavigate(2),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('quizzes')
                          .where('isPublished', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final quizzes = snapshot.data?.docs.length ?? 0;
                        return StatCard(
                          title: 'Quizzes',
                          value: quizzes.toString(),
                          icon: Icons.quiz_outlined,
                          color: AppColors.warning,
                          subtitle: 'Active',
                          onTap: () => widget.onNavigate(2),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // User Distribution - Real-time from Firestore
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: const Text(
                'User Distribution',
                style: TextStyle(
                  fontSize: AppConstants.fontXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    final totalUsers = docs.length;

                    int studentCount = 0;
                    int teacherCount = 0;
                    int adminCount = 0;

                    for (final doc in docs) {
                      final role = doc.data()['role'] as String? ?? '';
                      switch (role) {
                        case 'student':
                          studentCount++;
                          break;
                        case 'teacher':
                          teacherCount++;
                          break;
                        case 'admin':
                          adminCount++;
                          break;
                      }
                    }

                    return Column(
                      children: [
                        _UserDistributionRow(
                          role: 'Students',
                          count: studentCount,
                          total: totalUsers,
                          color: AppColors.studentPrimary,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        _UserDistributionRow(
                          role: 'Teachers',
                          count: teacherCount,
                          total: totalUsers,
                          color: AppColors.teacherPrimary,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        _UserDistributionRow(
                          role: 'Admins',
                          count: adminCount,
                          total: totalUsers,
                          color: AppColors.adminPrimary,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // Quick Actions
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: AppConstants.fontXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('verified', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final pending = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data();
                  return data['rejected'] != true &&
                      data['deleted'] != true &&
                      data['deactivated'] != true;
                }).length;
                final suffix = pending == 0
                    ? 'No pending accounts'
                    : '$pending pending accounts';
                return FeatureCard(
                  title: 'Verify Accounts',
                  description: suffix,
                  icon: Icons.verified_user_outlined,
                  iconColor: AppColors.adminPrimary,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin-verify-accounts');
                  },
                );
              },
            ),

            FeatureCard(
              title: 'Create Learning Materials',
              description: 'Add new learning materials with content',
              icon: Icons.add_box_outlined,
              iconColor: AppColors.studentPrimary,
              onTap: () {
                Navigator.pushNamed(context, '/admin-create-lesson');
              },
            ),

            FeatureCard(
              title: 'Create Quiz',
              description: 'Create a quiz for your students',
              icon: Icons.quiz_outlined,
              iconColor: AppColors.warning,
              onTap: () {
                Navigator.pushNamed(context, '/admin-create-quiz');
              },
            ),

            FeatureCard(
              title: 'AR Science Lab',
              description: 'Inspect published AR-ready lessons as admin',
              icon: Icons.view_in_ar_outlined,
              iconColor: AppColors.studentPrimary,
              onTap: _openAdminArExperience,
            ),

            FeatureCard(
              title: 'Analytics Dashboard',
              description: 'View user stats, engagement & performance trends',
              icon: Icons.analytics_outlined,
              iconColor: AppColors.info,
              onTap: () {
                Navigator.pushNamed(context, '/admin-analytics');
              },
            ),

            FeatureCard(
              title: 'Reports & PDF Export',
              description: 'Download lesson summaries and system reports',
              icon: Icons.picture_as_pdf_outlined,
              iconColor: AppColors.error,
              onTap: () {
                Navigator.pushNamed(context, '/admin-reports');
              },
            ),

            FeatureCard(
              title: 'Global Announcements',
              description: 'Broadcast announcements to active users by role',
              icon: Icons.campaign_outlined,
              iconColor: AppColors.secondary,
              onTap: () {
                Navigator.pushNamed(context, '/admin-announcements');
              },
            ),

            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }
}

class _UserManagement extends StatefulWidget {
  const _UserManagement();

  @override
  State<_UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<_UserManagement> {
  String _selectedFilter = 'all';
  String _accountStatusFilter = 'active';
  final TextEditingController _searchController = TextEditingController();

  Query<Map<String, dynamic>> _getUsersQuery() {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('users');

    // Filter by role if selected
    if (_selectedFilter == 'student') {
      query = query.where('role', isEqualTo: 'student');
    } else if (_selectedFilter == 'teacher') {
      query = query.where('role', isEqualTo: 'teacher');
    }

    return query.orderBy('createdAt', descending: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deactivateUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    final email = (userData['email'] ?? '').toString().trim();
    final name = (userData['name'] ?? email).toString().trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deactivate $name${email.isEmpty ? '' : ' ($email)'}?'),
            const SizedBox(height: AppConstants.paddingM),
            const Text(
              'This keeps the account record, quiz results, and progress, '
              'but removes the user from the active roster until restored.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userName = userData['name'] as String? ?? '';
      final userRole = userData['role'] as String? ?? '';

      await FirebaseFirestore.instance.collection('deletion_logs').add({
        'userId': userId,
        'userName': userName,
        'userEmail': email,
        'userRole': userRole,
        'deletedBy': currentUser?.uid,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedByRole': 'admin',
        'action': 'deactivated',
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'deleted': true,
        'deactivated': true,
        'accountStatus': 'deactivated',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': currentUser?.uid,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivatedBy': currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deactivated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to deactivate user: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _restoreUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    final email = (userData['email'] ?? '').toString().trim();
    final name = (userData['name'] ?? email).toString().trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore User?'),
        content: Text(
          'Restore $name${email.isEmpty ? '' : ' ($email)'} to the active roster?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'deleted': false,
        'deactivated': false,
        'accountStatus': 'active',
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': FieldValue.delete(),
        'deletedBy': FieldValue.delete(),
        'deactivatedAt': FieldValue.delete(),
        'deactivatedBy': FieldValue.delete(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account restored successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore user: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showUserDetails(
    Map<String, dynamic> userData, {
    required bool isDeactivated,
  }) async {
    final name = (userData['name'] ?? 'Unknown').toString().trim();
    final email = (userData['email'] ?? 'No email').toString().trim();
    final role = (userData['role'] ?? 'unknown').toString().trim();
    final gradeLevel = (userData['gradeLevel'] ?? '').toString().trim();
    final section = (userData['section'] ?? '').toString().trim();
    final subjects = (userData['subjects'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
    final sectionsHandled =
        (userData['sectionsHandled'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .join(', ');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: AppConstants.fontL,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              SelectableText('Email: $email'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Role: ${role.toUpperCase()}'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Status: ${isDeactivated ? 'Deactivated' : 'Active'}'),
              if (gradeLevel.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingS),
                Text('Grade Level: $gradeLevel'),
              ],
              if (section.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingS),
                Text('Section: $section'),
              ],
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingS),
                Text('Subjects: $subjects'),
              ],
              if (sectionsHandled.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingS),
                Text('Sections Handled: $sectionsHandled'),
              ],
              const SizedBox(height: AppConstants.paddingM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: const Text(
                  'Password: Not retrievable from Firebase Auth. Use the reset password action if the user needs a new password.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetUserPassword(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _editUser(
      String userId, Map<String, dynamic> currentData) async {
    final nameController =
        TextEditingController(text: currentData['name'] as String? ?? '');
    final gradeLevelController =
        TextEditingController(text: currentData['gradeLevel'] as String? ?? '');
    final sectionController =
        TextEditingController(text: currentData['section'] as String? ?? '');
    final role = currentData['role'] as String? ?? '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              if (role == 'student') ...[
                const SizedBox(height: AppConstants.paddingM),
                DropdownButtonFormField<String>(
                  value: AppConstants.gradeLevels
                          .contains(gradeLevelController.text)
                      ? gradeLevelController.text
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Grade Level',
                    prefixIcon: Icon(Icons.school_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.gradeLevels
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) gradeLevelController.text = val;
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                TextField(
                  controller: sectionController,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    prefixIcon: Icon(Icons.group_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final updates = <String, dynamic>{
                  'name': nameController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (role == 'student') {
                  updates['gradeLevel'] = gradeLevelController.text.trim();
                  updates['section'] = sectionController.text.trim();
                }
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update(updates);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User info updated successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update user: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetUserPassword(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Send a password reset email to $email?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email.trim().toLowerCase());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: 'All',
                        isSelected: _selectedFilter == 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: _FilterButton(
                        label: 'Students',
                        isSelected: _selectedFilter == 'student',
                        onTap: () =>
                            setState(() => _selectedFilter = 'student'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: _FilterButton(
                        label: 'Teachers',
                        isSelected: _selectedFilter == 'teacher',
                        onTap: () =>
                            setState(() => _selectedFilter = 'teacher'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingM),
                Row(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: 'Active',
                        isSelected: _accountStatusFilter == 'active',
                        onTap: () =>
                            setState(() => _accountStatusFilter = 'active'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: _FilterButton(
                        label: 'Deactivated',
                        isSelected: _accountStatusFilter == 'deactivated',
                        onTap: () => setState(
                          () => _accountStatusFilter = 'deactivated',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getUsersQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint(snapshot.error.toString());
                  return Center(
                    child: Text(
                      'Error loading users: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                final searchTerm = _searchController.text.toLowerCase().trim();
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data();
                  final isDeactivated =
                      data['deleted'] == true || data['deactivated'] == true;
                  final matchesStatus = _accountStatusFilter == 'deactivated'
                      ? isDeactivated
                      : !isDeactivated;
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  return matchesStatus &&
                      (name.contains(searchTerm) || email.contains(searchTerm));
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.paddingL),
                      child: Text(
                        'No users found.',
                        style: TextStyle(
                          fontSize: AppConstants.fontL,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final isDeactivated =
                        data['deleted'] == true || data['deactivated'] == true;
                    final userModel = UserModel.fromJson({
                      ...data,
                      'id': doc.id,
                    });

                    return _UserCard(
                      userModel: userModel,
                      isDeactivated: isDeactivated,
                      onViewDetails: () => _showUserDetails(
                        data,
                        isDeactivated: isDeactivated,
                      ),
                      onDeactivate: () => _deactivateUser(doc.id, data),
                      onRestore: () => _restoreUser(doc.id, data),
                      onEdit: () => _editUser(doc.id, doc.data()),
                      onResetPassword: () =>
                          _resetUserPassword(userModel.email),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          null, // Remove Add User button - registration is handled by users
    );
  }
}

class _ContentManagement extends StatelessWidget {
  const _ContentManagement();

  int _countPending(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((d) => d.data()['isPublished'] != true).length;
  }

  Future<void> _confirmAndDelete(
    BuildContext context, {
    required String collection,
    required String id,
    required String title,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection(collection).doc(id).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e is FirebaseException
          ? '${e.code}: ${e.message ?? 'Unknown Firebase error'}'
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed. $message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Content Management'),
          backgroundColor: AppColors.adminPrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lessons'),
              Tab(text: 'Quizzes'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('lessons')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        return _ContentStatCard(
                          title: 'Lessons',
                          count: docs.length,
                          pending: _countPending(docs),
                          color: AppColors.studentPrimary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('quizzes')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        return _ContentStatCard(
                          title: 'Quizzes',
                          count: docs.length,
                          pending: _countPending(docs),
                          color: AppColors.warning,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('lessons')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No lessons yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingM,
                          vertical: AppConstants.paddingS,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final lesson = <String, dynamic>{
                            ...data,
                            'id': doc.data()['id'] ?? doc.id,
                          };
                          final title = (data['title'] ?? '').toString();
                          final subject = (data['subject'] ?? '').toString();
                          final grade =
                              (data['gradeLevel'] ?? data['grade'] ?? '')
                                  .toString();
                          final published = data['isPublished'] == true;

                          return Card(
                            margin: const EdgeInsets.only(
                                bottom: AppConstants.paddingM),
                            child: ListTile(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.lessonDetail,
                                  arguments: lesson,
                                );
                              },
                              title: Text(
                                title.isEmpty ? '(Untitled lesson)' : title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                [
                                  if (subject.isNotEmpty) subject,
                                  if (grade.isNotEmpty) grade,
                                  published ? 'Published' : 'Draft',
                                ].join(' • '),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.adminCreateLesson,
                                      arguments: <String, dynamic>{
                                        'role': 'admin',
                                        'lessonId': doc.id,
                                        'lessonData': lesson,
                                      },
                                    );
                                  }
                                  if (value == 'delete') {
                                    _confirmAndDelete(
                                      context,
                                      collection: 'lessons',
                                      id: doc.id,
                                      title: title.isEmpty ? 'Lesson' : title,
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('quizzes')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No quizzes yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingM,
                          vertical: AppConstants.paddingS,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final quiz = <String, dynamic>{
                            ...data,
                            'id': doc.data()['id'] ?? doc.id,
                          };
                          final title = (data['title'] ?? '').toString();
                          final subject = (data['subject'] ?? '').toString();
                          final grade =
                              (data['gradeLevel'] ?? data['grade'] ?? '')
                                  .toString();
                          final published = data['isPublished'] == true;
                          final duration = data['duration'] is int
                              ? data['duration'] as int
                              : int.tryParse(
                                      (data['duration'] ?? '').toString()) ??
                                  30;

                          return Card(
                            margin: const EdgeInsets.only(
                                bottom: AppConstants.paddingM),
                            child: ListTile(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.quizDetail,
                                  arguments: quiz,
                                );
                              },
                              title: Text(
                                title.isEmpty ? '(Untitled quiz)' : title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                [
                                  if (subject.isNotEmpty) subject,
                                  if (grade.isNotEmpty) grade,
                                  '$duration min',
                                  published ? 'Published' : 'Draft',
                                ].join(' • '),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.adminCreateQuiz,
                                      arguments: <String, dynamic>{
                                        'role': 'admin',
                                        'quizId': doc.id,
                                        'quizData': quiz,
                                      },
                                    );
                                  }
                                  if (value == 'delete') {
                                    _confirmAndDelete(
                                      context,
                                      collection: 'quizzes',
                                      id: doc.id,
                                      title: title.isEmpty ? 'Quiz' : title,
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage();

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  String? _selectedAcademicYear;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _defaultYears = [
    '2025-2026',
    '2026-2027',
    '2027-2028',
    '2028-2029',
    '2029-2030',
  ];

  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final academicYear = data?['academicYear'] as String? ?? '2025-2026';
        final customYears = data?['customYears'] != null
            ? List<String>.from(data!['customYears'])
            : <String>[];
        final allYears = {..._defaultYears, ...customYears}.toList();
        if (!allYears.contains(academicYear)) allYears.add(academicYear);
        allYears.sort();
        setState(() {
          _availableYears = allYears;
          _selectedAcademicYear = academicYear;
        });
      } else {
        await FirebaseFirestore.instance
            .collection('app_config')
            .doc('current')
            .set({
          'academicYear': '2025-2026',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _availableYears = List.from(_defaultYears);
          _selectedAcademicYear = '2025-2026';
        });
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (!mounted) return;
      setState(() {
        _availableYears = List.from(_defaultYears);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_selectedAcademicYear == null) return;
    setState(() => _isSaving = true);

    try {
      final customYears =
          _availableYears.where((y) => !_defaultYears.contains(y)).toList();
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('current')
          .set({
        'academicYear': _selectedAcademicYear,
        'customYears': customYears,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showYearPickerDialog() async {
    String? tempSelected = _selectedAcademicYear;
    List<String> tempYears = List.from(_availableYears);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
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
                            activeColor: AppColors.adminPrimary,
                            onChanged: (val) {
                              setStateDialog(() => tempSelected = val);
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
                      context: ctx,
                      builder: (ctx2) => AlertDialog(
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
                            onPressed: () => Navigator.pop(ctx2),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final val = controller.text.trim();
                              if (val.isNotEmpty) {
                                Navigator.pop(ctx2, val);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.adminPrimary,
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    // After dialog closes, update state with selection
    if (tempSelected != _selectedAcademicYear ||
        tempYears.length != _availableYears.length) {
      setState(() {
        _selectedAcademicYear = tempSelected;
        _availableYears = tempYears;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('System Settings'),
          backgroundColor: AppColors.adminPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: AppColors.adminPrimary,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(AppConstants.paddingM),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        children: [
          const Text(
            'General Settings',
            style: TextStyle(
              fontSize: AppConstants.fontL,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Academic Year',
                    style: TextStyle(
                      fontSize: AppConstants.fontM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  InkWell(
                    onTap: _showYearPickerDialog,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingM,
                        vertical: AppConstants.paddingM,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textSecondary),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_outlined,
                              color: AppColors.textSecondary),
                          const SizedBox(width: AppConstants.paddingM),
                          Expanded(
                            child: Text(
                              _selectedAcademicYear ?? 'Select Academic Year',
                              style: TextStyle(
                                fontSize: AppConstants.fontM,
                                color: _selectedAcademicYear != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    'This academic year will be displayed throughout the app.',
                    style: TextStyle(
                      fontSize: AppConstants.fontS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDistributionRow extends StatelessWidget {
  final String role;
  final int count;
  final int total;
  final Color color;

  const _UserDistributionRow({
    required this.role,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (count / total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              role,
              style: const TextStyle(
                fontSize: AppConstants.fontM,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: AppConstants.fontM,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? AppColors.adminPrimary : AppColors.surfaceLight,
        foregroundColor:
            isSelected ? AppColors.textWhite : AppColors.textPrimary,
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(label),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel userModel;
  final bool isDeactivated;
  final VoidCallback onViewDetails;
  final VoidCallback onDeactivate;
  final VoidCallback onRestore;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;

  const _UserCard({
    required this.userModel,
    required this.isDeactivated,
    required this.onViewDetails,
    required this.onDeactivate,
    required this.onRestore,
    required this.onEdit,
    required this.onResetPassword,
  });

  Color _getRoleColor() {
    switch (userModel.role) {
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
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor().withOpacity(0.15),
          child: Icon(
            Icons.person,
            color: _getRoleColor(),
          ),
        ),
        title: Text(
          userModel.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userModel.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userModel.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDeactivated
                        ? AppColors.warning.withOpacity(0.14)
                        : AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDeactivated ? 'DEACTIVATED' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          isDeactivated ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
                if (userModel.gradeLevel != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    userModel.gradeLevel!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view_details') {
              onViewDetails();
            } else if (value == 'edit') {
              onEdit();
            } else if (value == 'reset_password') {
              onResetPassword();
            } else if (value == 'deactivate') {
              onDeactivate();
            } else if (value == 'restore') {
              onRestore();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_details',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            if (!isDeactivated)
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Info'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'reset_password',
              child: Row(
                children: [
                  Icon(Icons.lock_reset_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Reset Password'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: isDeactivated ? 'restore' : 'deactivate',
              child: Row(
                children: [
                  Icon(
                    isDeactivated ? Icons.restore_outlined : Icons.block,
                    size: 18,
                    color: isDeactivated ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDeactivated ? 'Restore' : 'Deactivate',
                    style: TextStyle(
                      color:
                          isDeactivated ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentStatCard extends StatelessWidget {
  final String title;
  final int count;
  final int pending;
  final Color color;

  const _ContentStatCard({
    required this.title,
    required this.count,
    required this.pending,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: AppConstants.fontM,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              '$count',
              style: TextStyle(
                fontSize: AppConstants.fontXXL,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              '$pending pending',
              style: const TextStyle(
                fontSize: AppConstants.fontS,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
