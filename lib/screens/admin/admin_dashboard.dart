import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardHome(),
    const _UserManagement(),
    const _ContentManagement(),
    const _SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

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
              Navigator.pushNamed(context, '/notifications',
                  arguments: 'admin');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile', arguments: 'admin');
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
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusRound),
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

            const SizedBox(height: AppConstants.paddingL),

            // System Stats
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Users',
                      value: '1,245',
                      icon: Icons.people_outline,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StatCard(
                      title: 'Active',
                      value: '892',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      subtitle: 'Online',
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
                    child: StatCard(
                      title: 'Lessons',
                      value: '156',
                      icon: Icons.book_outlined,
                      color: AppColors.studentPrimary,
                      subtitle: 'Published',
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StatCard(
                      title: 'Quizzes',
                      value: '89',
                      icon: Icons.quiz_outlined,
                      color: AppColors.warning,
                      subtitle: 'Active',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // User Distribution
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Text(
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
                child: Column(
                  children: [
                    _UserDistributionRow(
                      role: 'Students',
                      count: 1050,
                      total: 1245,
                      color: AppColors.studentPrimary,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _UserDistributionRow(
                      role: 'Teachers',
                      count: 185,
                      total: 1245,
                      color: AppColors.teacherPrimary,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _UserDistributionRow(
                      role: 'Admins',
                      count: 10,
                      total: 1245,
                      color: AppColors.adminPrimary,
                    ),
                  ],
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

            FeatureCard(
              title: 'Manage Users',
              description: 'Add, edit, or remove user accounts',
              icon: Icons.people_outline,
              iconColor: AppColors.adminPrimary,
              onTap: () {
                Navigator.pushNamed(context, '/admin-verify-accounts');
              },
            ),

            FeatureCard(
              title: 'Content Review',
              description: 'Review and approve pending content',
              icon: Icons.rate_review_outlined,
              iconColor: AppColors.warning,
              onTap: () {},
            ),

            FeatureCard(
              title: 'System Reports',
              description: 'View detailed analytics and reports',
              icon: Icons.analytics_outlined,
              iconColor: AppColors.info,
              onTap: () {},
            ),

            FeatureCard(
              title: 'Announcements',
              description: 'Send notifications to all users',
              icon: Icons.campaign_outlined,
              iconColor: AppColors.error,
              onTap: () {},
            ),

            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }
}

class _UserManagement extends StatelessWidget {
  const _UserManagement();

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
            child: Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    label: 'All (1245)',
                    isSelected: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: _FilterButton(
                    label: 'Students',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: _FilterButton(
                    label: 'Teachers',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Users List
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _UserCard(
                  name: 'User ${index + 1}',
                  email: 'user${index + 1}@example.com',
                  role: index % 3 == 0 ? 'Teacher' : 'Student',
                  isActive: index % 2 == 0,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.adminPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }
}

class _ContentManagement extends StatelessWidget {
  const _ContentManagement();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: Column(
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: _ContentStatCard(
                    title: 'Lessons',
                    count: 156,
                    pending: 12,
                    color: AppColors.studentPrimary,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: _ContentStatCard(
                    title: 'Quizzes',
                    count: 89,
                    pending: 5,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              children: [
                const Text(
                  'Pending Approval',
                  style: TextStyle(
                    fontSize: AppConstants.fontL,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                _ContentReviewCard(
                  title: 'Laws of Motion',
                  type: 'Lesson',
                  author: 'Prof. Jane Smith',
                  subject: 'Physics',
                ),
                _ContentReviewCard(
                  title: 'Chemical Reactions Quiz',
                  type: 'Quiz',
                  author: 'Dr. John Doe',
                  subject: 'Chemistry',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: AppColors.adminPrimary,
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
          _SettingsTile(
            icon: Icons.school_outlined,
            title: 'Academic Year',
            subtitle: '2024-2025',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.security_outlined,
            title: 'Security & Privacy',
            onTap: () {},
          ),
          const SizedBox(height: AppConstants.paddingXL),
          const Text(
            'System Management',
            style: TextStyle(
              fontSize: AppConstants.fontL,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.analytics_outlined,
            title: 'System Analytics',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'Error Logs',
            onTap: () {},
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
  final String name;
  final String email;
  final String role;
  final bool isActive;

  const _UserCard({
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? AppColors.success : AppColors.textLight,
          child: Icon(
            Icons.person,
            color: AppColors.textWhite,
          ),
        ),
        title: Text(name),
        subtitle: Text('$email\n$role'),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
            const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
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

class _ContentReviewCard extends StatelessWidget {
  final String title;
  final String type;
  final String author;
  final String subject;

  const _ContentReviewCard({
    required this.title,
    required this.type,
    required this.author,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingM,
                    vertical: AppConstants.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusRound),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontSize: AppConstants.fontS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: AppConstants.fontS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppConstants.fontL,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              'By $author',
              style: const TextStyle(
                fontSize: AppConstants.fontM,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
              ],
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
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: ListTile(
        leading: Icon(icon, color: AppColors.adminPrimary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
