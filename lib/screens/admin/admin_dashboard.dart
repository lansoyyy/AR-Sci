import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
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

  final List<Widget> _screens = [
    const _DashboardHome(),
    const _UserManagement(),
    const _ContentManagement(),
    const _SettingsPage(),
  ];

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

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.adminPrimary,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications_outlined),
        //     onPressed: () {
        //       Navigator.pushNamed(context, '/notifications',
        //           arguments: 'admin');
        //     },
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.person_outline),
        //     onPressed: () {
        //       Navigator.pushNamed(context, '/profile', arguments: 'admin');
        //     },
        //   ),
        // ],
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

            // FeatureCard(
            //   title: 'Manage Users',
            //   description: 'Add, edit, or remove user accounts',
            //   icon: Icons.people_outline,
            //   iconColor: AppColors.adminPrimary,
            //   onTap: () {
            //     Navigator.pushNamed(context, '/admin-verify-accounts');
            //   },
            // ),

            // FeatureCard(
            //   title: 'Content Review',
            //   description: 'Review and approve pending content',
            //   icon: Icons.rate_review_outlined,
            //   iconColor: AppColors.warning,
            //   onTap: () {},
            // ),

            FeatureCard(
              title: 'Create Lesson',
              description: 'Create a new lesson',
              icon: Icons.add_box_outlined,
              iconColor: AppColors.studentPrimary,
              onTap: () {
                Navigator.pushNamed(context, '/admin-create-lesson');
              },
            ),

            FeatureCard(
              title: 'Create Quiz',
              description: 'Create a new quiz',
              icon: Icons.quiz_outlined,
              iconColor: AppColors.warning,
              onTap: () {
                Navigator.pushNamed(context, '/admin-create-quiz');
              },
            ),

            // FeatureCard(
            //   title: 'System Reports',
            //   description: 'View detailed analytics and reports',
            //   icon: Icons.analytics_outlined,
            //   iconColor: AppColors.info,
            //   onTap: () {},
            // ),

            // FeatureCard(
            //   title: 'Announcements',
            //   description: 'Send notifications to all users',
            //   icon: Icons.campaign_outlined,
            //   iconColor: AppColors.error,
            //   onTap: () {},
            // ),

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

  Future<void> _deleteUser(String userId, String email) async {
    try {
      // Delete from Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $e'),
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
            child: Row(
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
                    onTap: () => setState(() => _selectedFilter = 'student'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: _FilterButton(
                    label: 'Teachers',
                    isSelected: _selectedFilter == 'teacher',
                    onTap: () => setState(() => _selectedFilter = 'teacher'),
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
                  print(snapshot.error);
                  return Center(
                    child: Text(
                      'Error loading users: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Filter by search text
                final searchTerm = _searchController.text.toLowerCase().trim();
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  return name.contains(searchTerm) ||
                      email.contains(searchTerm);
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
                    final userModel = UserModel.fromJson(data);

                    return _UserCard(
                      userModel: userModel,
                      onDelete: () => _deleteUser(doc.id, userModel.email),
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

  String _subjectToColorName(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return 'physics';
    if (s.contains('chemistry')) return 'chemistry';
    if (s.contains('biology')) return 'biology';
    if (s.contains('earth')) return 'earthScience';
    return 'physics';
  }

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

  Future<void> _showEditLessonDialog(
    BuildContext context, {
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final titleController =
        TextEditingController(text: (data['title'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: (data['description'] ?? '').toString());
    final contentController =
        TextEditingController(text: (data['content'] ?? '').toString());

    var subject = (data['subject'] ?? AppConstants.subjects.first).toString();
    var gradeLevel =
        (data['gradeLevel'] ?? data['grade'] ?? AppConstants.gradeLevels.first)
            .toString();
    var quarter = (data['quarter'] ?? 'Quarter 3').toString();
    var isPublished = data['isPublished'] == true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: AppConstants.paddingM),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: AppConstants.paddingM),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: AppConstants.subjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => subject = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                DropdownButtonFormField<String>(
                  value: gradeLevel,
                  decoration: const InputDecoration(labelText: 'Grade Level'),
                  items: AppConstants.gradeLevels
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => gradeLevel = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                DropdownButtonFormField<String>(
                  value: quarter,
                  decoration: const InputDecoration(labelText: 'Quarter'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Quarter 3', child: Text('Quarter 3')),
                    DropdownMenuItem(
                        value: 'Quarter 4', child: Text('Quarter 4')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => quarter = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 6,
                ),
                const SizedBox(height: AppConstants.paddingM),
                SwitchListTile(
                  value: isPublished,
                  onChanged: (v) => setState(() => isPublished = v),
                  activeColor: AppColors.adminPrimary,
                  title: const Text('Published'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('lessons')
                      .doc(id)
                      .update({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'subject': subject,
                    'gradeLevel': gradeLevel,
                    'quarter': quarter,
                    'color': _subjectToColorName(subject),
                    'content': contentController.text.trim(),
                    'isPublished': isPublished,
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lesson updated.')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  final message = e is FirebaseException
                      ? '${e.code}: ${e.message ?? 'Unknown Firebase error'}'
                      : e.toString();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed. $message')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditQuizDialog(
    BuildContext context, {
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final titleController =
        TextEditingController(text: (data['title'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: (data['description'] ?? '').toString());
    final durationController = TextEditingController(
      text: (data['duration'] ?? 30).toString(),
    );

    final lessonId = (data['lessonId'] ?? '').toString();

    var subject = (data['subject'] ?? AppConstants.subjects.first).toString();
    var gradeLevel =
        (data['gradeLevel'] ?? data['grade'] ?? AppConstants.gradeLevels.first)
            .toString();
    var isPublished = data['isPublished'] == true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Quiz'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: AppConstants.paddingM),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: AppConstants.paddingM),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: AppConstants.subjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => subject = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                DropdownButtonFormField<String>(
                  value: gradeLevel,
                  decoration: const InputDecoration(labelText: 'Grade Level'),
                  items: AppConstants.gradeLevels
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => gradeLevel = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duration (minutes)'),
                ),
                if (lessonId.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.paddingM),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lesson ID: $lessonId',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.paddingM),
                SwitchListTile(
                  value: isPublished,
                  onChanged: (v) => setState(() => isPublished = v),
                  activeColor: AppColors.adminPrimary,
                  title: const Text('Published'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final duration =
                      int.tryParse(durationController.text.trim()) ?? 30;
                  await FirebaseFirestore.instance
                      .collection('quizzes')
                      .doc(id)
                      .update({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'subject': subject,
                    'gradeLevel': gradeLevel,
                    'duration': duration,
                    'isPublished': isPublished,
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quiz updated.')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  final message = e is FirebaseException
                      ? '${e.code}: ${e.message ?? 'Unknown Firebase error'}'
                      : e.toString();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed. $message')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonsStream =
        FirebaseFirestore.instance.collection('lessons').snapshots();
    final quizzesStream =
        FirebaseFirestore.instance.collection('quizzes').snapshots();

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
                      stream: lessonsStream,
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
                      stream: quizzesStream,
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
                    stream: lessonsStream,
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
                                    _showEditLessonDialog(
                                      context,
                                      id: doc.id,
                                      data: data,
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
                    stream: quizzesStream,
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
                                    _showEditQuizDialog(
                                      context,
                                      id: doc.id,
                                      data: data,
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
            subtitle: '2025-2026',
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
  final UserModel userModel;
  final VoidCallback onDelete;

  const _UserCard({
    required this.userModel,
    required this.onDelete,
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
            if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete User'),
                  content: Text(
                    'Are you sure you want to delete ${userModel.name}? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
