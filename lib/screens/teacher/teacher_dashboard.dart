import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../models/user_model.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  UserModel? _currentUser;
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _currentUser = UserModel.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedScreens = <Widget>[
      _DashboardHome(currentUser: _currentUser, isLoading: _isLoading),
      _LessonsManagement(currentUser: _currentUser),
      _QuizzesManagement(currentUser: _currentUser),
      _StudentsPage(currentUser: _currentUser),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        body: updatedScreens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.teacherPrimary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Lessons',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz),
              label: 'Quizzes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Students',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final UserModel? currentUser;
  final bool isLoading;

  const _DashboardHome({
    this.currentUser,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final teacherName = (currentUser?.name.trim().isNotEmpty ?? false)
        ? currentUser!.name.trim()
        : 'Teacher';

    // Display subjects if available, otherwise show 'Teacher'
    String teacherSubject = 'Teacher';
    if (currentUser?.subjects != null && currentUser!.subjects!.isNotEmpty) {
      teacherSubject = currentUser!.subjects!.join(', ');
    } else if (currentUser?.subject?.trim().isNotEmpty ?? false) {
      // Fallback to legacy single subject field
      teacherSubject = currentUser!.subject!.trim();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: AppColors.teacherPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications',
                  arguments: 'teacher');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile', arguments: 'teacher');
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
                    AppColors.teacherPrimary,
                    AppColors.teacherLight,
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
                  Text(
                    isLoading ? 'Loading...' : teacherName,
                    style: const TextStyle(
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
                    child: Text(
                      isLoading ? 'Loading...' : teacherSubject,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingL),

            // Analytics Stats
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'student')
                          .where('verified', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const StatCard(
                            title: 'Students',
                            value: '-',
                            icon: Icons.people_outline,
                            color: AppColors.teacherPrimary,
                            subtitle: 'In Scope',
                          );
                        }
                        // Filter students by teacher's sections
                        final allStudents = snapshot.data?.docs ?? [];
                        final filteredStudents = allStudents.where((doc) {
                          final data = doc.data();
                          final studentGrade = data['gradeLevel'] as String?;
                          final studentSection = data['section'] as String?;
                          final teacherSections = currentUser?.sectionsHandled;

                          if (teacherSections == null ||
                              teacherSections.isEmpty) {
                            return true; // Show all if no sections specified
                          }

                          if (studentGrade != null &&
                              teacherSections.contains(studentGrade)) {
                            return true;
                          }
                          if (studentSection != null &&
                              teacherSections.contains(studentSection)) {
                            return true;
                          }

                          return false;
                        }).toList();

                        return StatCard(
                          title: 'Students',
                          value: filteredStudents.length.toString(),
                          icon: Icons.people_outline,
                          color: AppColors.teacherPrimary,
                          subtitle: 'In Scope',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('lessons')
                          .where('createdBy',
                              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .where('isPublished', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const StatCard(
                            title: 'Lessons',
                            value: '-',
                            icon: Icons.book_outlined,
                            color: AppColors.studentPrimary,
                            subtitle: 'Published',
                          );
                        }
                        final count = snapshot.data?.docs.length ?? 0;
                        return StatCard(
                          title: 'Lessons',
                          value: count.toString(),
                          icon: Icons.book_outlined,
                          color: AppColors.studentPrimary,
                          subtitle: 'Published',
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
                          .collection('quizzes')
                          .where('createdBy',
                              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),
                      builder: (context, quizzesSnapshot) {
                        if (quizzesSnapshot.hasError) {
                          return const StatCard(
                            title: 'Avg Score',
                            value: '-',
                            icon: Icons.trending_up_outlined,
                            color: AppColors.success,
                          );
                        }

                        final quizzes = quizzesSnapshot.data?.docs ?? [];
                        if (quizzes.isEmpty) {
                          return const StatCard(
                            title: 'Avg Score',
                            value: '0%',
                            icon: Icons.trending_up_outlined,
                            color: AppColors.success,
                          );
                        }

                        // Get quiz IDs for this teacher
                        final quizIds = quizzes.map((d) => d.id).toList();

                        // Now get results for these quizzes
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('quiz_results')
                              .where('quizId',
                                  whereIn: quizIds.isEmpty ? [''] : quizIds)
                              .snapshots(),
                          builder: (context, resultsSnapshot) {
                            final docs = resultsSnapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const StatCard(
                                title: 'Avg Score',
                                value: '0%',
                                icon: Icons.trending_up_outlined,
                                color: AppColors.success,
                              );
                            }

                            final percentages = docs.map((d) {
                              final data = d.data();
                              final score =
                                  (data['score'] as num?)?.toDouble() ?? 0.0;
                              final totalPoints =
                                  (data['totalPoints'] as num?)?.toDouble() ??
                                      0.0;
                              if (totalPoints <= 0) return 0.0;
                              return (score / totalPoints) * 100;
                            }).toList();

                            final avg = percentages.reduce((a, b) => a + b) /
                                (percentages.isEmpty ? 1 : percentages.length);

                            return StatCard(
                              title: 'Avg Score',
                              value: '${avg.toStringAsFixed(0)}%',
                              icon: Icons.trending_up_outlined,
                              color: AppColors.success,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('quizzes')
                          .where('createdBy',
                              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .where('isPublished', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const StatCard(
                            title: 'Quizzes',
                            value: '-',
                            icon: Icons.quiz_outlined,
                            color: AppColors.warning,
                            subtitle: 'Active',
                          );
                        }
                        final count = snapshot.data?.docs.length ?? 0;
                        return StatCard(
                          title: 'Quizzes',
                          value: count.toString(),
                          icon: Icons.quiz_outlined,
                          color: AppColors.warning,
                          subtitle: 'Active',
                        );
                      },
                    ),
                  ),
                ],
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
              title: 'Create Learning Materials',
              description: 'Add new learning materials with content',
              icon: Icons.add_box_outlined,
              iconColor: AppColors.teacherPrimary,
              onTap: () {
                Navigator.pushNamed(context, '/admin-create-lesson');
              },
            ),

            FeatureCard(
              title: 'Create Quiz',
              description: 'Create a quiz for your students',
              icon: Icons.quiz_outlined,
              iconColor: AppColors.studentPrimary,
              onTap: () {
                Navigator.pushNamed(context, '/admin-create-quiz');
              },
            ),

            // StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            //   stream: FirebaseFirestore.instance
            //       .collection('users')
            //       .where('role', isEqualTo: 'student')
            //       .where('verified', isEqualTo: false)
            //       .snapshots(),
            //   builder: (context, snapshot) {
            //     final pending = snapshot.data?.docs.length ?? 0;
            //     final suffix = pending == 0
            //         ? 'No pending registrations'
            //         : '$pending pending registrations';
            //     return FeatureCard(
            //       title: 'Approve Students',
            //       description: suffix,
            //       icon: Icons.verified_outlined,
            //       iconColor: AppColors.success,
            //       onTap: () {
            //         Navigator.pushNamed(context, '/teacher-approve-students');
            //       },
            //     );
            //   },
            // ),

            const SizedBox(height: AppConstants.paddingXL),

            // Recent Activity
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Text(
                'Recent Activity',
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
                  .collection('quiz_results')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingM),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final teacherId = FirebaseAuth.instance.currentUser?.uid;
                if (teacherId == null) {
                  return const SizedBox.shrink();
                }

                // Get teacher's quiz IDs first
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('quizzes')
                      .where('createdBy', isEqualTo: teacherId)
                      .snapshots(),
                  builder: (context, quizzesSnapshot) {
                    if (quizzesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(AppConstants.paddingM),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final teacherQuizIds = quizzesSnapshot.data?.docs
                            .map((d) => d.data()['id'] as String? ?? d.id)
                            .toSet() ??
                        <String>{};

                    if (teacherQuizIds.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final activities = docs.where((d) {
                      final quizId = (d.data()['quizId'] as String?) ?? '';
                      return teacherQuizIds.contains(quizId);
                    }).map((d) {
                      final data = d.data();
                      final quizTitle = (data['quizTitle'] as String?) ?? '';
                      final quizId = (data['quizId'] as String?) ?? d.id;
                      final completedAt =
                          _parseFirestoreDate(data['completedAt']);
                      return {
                        'title': 'Quiz Submitted',
                        'subtitle': quizTitle.isNotEmpty
                            ? 'A student completed $quizTitle'
                            : 'A student completed quiz $quizId',
                        'time': _timeAgo(completedAt),
                        'icon': Icons.assignment_turned_in_outlined,
                        'color': AppColors.success,
                        'dt': completedAt,
                      };
                    }).toList()
                      ..sort((a, b) {
                        final ad = a['dt'] as DateTime;
                        final bd = b['dt'] as DateTime;
                        return bd.compareTo(ad);
                      });

                    if (activities.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: activities.take(3).map((a) {
                        return _ActivityCard(
                          title: a['title'] as String,
                          subtitle: a['subtitle'] as String,
                          time: a['time'] as String,
                          icon: a['icon'] as IconData,
                          color: a['color'] as Color,
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .where('isPublished', isEqualTo: true)
                  .where('createdBy',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final lessons = docs.map((d) {
                  final data = d.data();
                  final title = (data['title'] as String?) ?? '';
                  final createdAt = _parseFirestoreDate(data['createdAt']);
                  return {
                    'title': title,
                    'dt': createdAt,
                  };
                }).toList()
                  ..sort((a, b) {
                    final ad = a['dt'] as DateTime;
                    final bd = b['dt'] as DateTime;
                    return bd.compareTo(ad);
                  });

                if (lessons.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: lessons.take(2).map((l) {
                    final title = (l['title'] as String).isEmpty
                        ? 'New lesson published'
                        : '${l['title']} is now available';
                    final dt = l['dt'] as DateTime;
                    return _ActivityCard(
                      title: 'New Lesson Published',
                      subtitle: title,
                      time: _timeAgo(dt),
                      icon: Icons.publish_outlined,
                      color: AppColors.studentPrimary,
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }
}

class _LessonsManagement extends StatefulWidget {
  final UserModel? currentUser;

  const _LessonsManagement({this.currentUser});

  @override
  State<_LessonsManagement> createState() => _LessonsManagementState();
}

class _LessonsManagementState extends State<_LessonsManagement> {
  String? get _teacherId => FirebaseAuth.instance.currentUser?.uid;
  Future<void> _confirmAndDelete({
    required String lessonId,
    required String title,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete lesson. $e')),
      );
    }
  }

  Future<void> _showEditDialog({
    required String lessonId,
    required Map<String, dynamic> lesson,
  }) async {
    final titleController =
        TextEditingController(text: (lesson['title'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: (lesson['description'] ?? '').toString());
    bool isPublished = lesson['isPublished'] == true;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
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
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    SwitchListTile(
                      value: isPublished,
                      onChanged: (v) => setLocalState(() => isPublished = v),
                      title: const Text('Published'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (didSave != true) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .update({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'isPublished': isPublished,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update lesson. $e')),
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Lessons'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('lessons')
            .where('createdBy', isEqualTo: _teacherId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load lessons. ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            );
          }

          final lessons = (snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[])
              .map((d) => <String, dynamic>{
                    ...d.data(),
                    'id': d.data()['id'] ?? d.id,
                  })
              .toList();

          if (lessons.isEmpty) {
            return const Center(
              child: Text(
                'No lessons available.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final lessonId = (lesson['id'] ?? '').toString();
              final title = (lesson['title'] ?? '').toString();
              return _LessonManagementCard(
                title: title,
                subject: (lesson['subject'] ?? '').toString(),
                gradeLevel:
                    (lesson['gradeLevel'] ?? lesson['grade'] ?? '').toString(),
                isPublished: lesson['isPublished'] == true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/lesson-detail',
                    arguments: lesson,
                  );
                },
                onEdit: lessonId.isEmpty
                    ? null
                    : () => _showEditDialog(lessonId: lessonId, lesson: lesson),
                onDelete: lessonId.isEmpty
                    ? null
                    : () => _confirmAndDelete(lessonId: lessonId, title: title),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/admin-create-lesson');
        },
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New Lesson'),
      ),
    );
  }
}

class _QuizzesManagement extends StatefulWidget {
  final UserModel? currentUser;

  const _QuizzesManagement({this.currentUser});

  @override
  State<_QuizzesManagement> createState() => _QuizzesManagementState();
}

class _QuizzesManagementState extends State<_QuizzesManagement> {
  String? get _teacherId => FirebaseAuth.instance.currentUser?.uid;
  Future<void> _showEditDialog({
    required String quizId,
    required Map<String, dynamic> quiz,
  }) async {
    final titleController =
        TextEditingController(text: (quiz['title'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: (quiz['description'] ?? '').toString());
    final durationController = TextEditingController(
      text: (quiz['duration'] ?? 30).toString(),
    );
    bool isPublished = quiz['isPublished'] == true;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
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
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Duration (min)'),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    SwitchListTile(
                      value: isPublished,
                      onChanged: (v) => setLocalState(() => isPublished = v),
                      title: const Text('Published'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (didSave != true) {
      titleController.dispose();
      descriptionController.dispose();
      durationController.dispose();
      return;
    }

    try {
      final duration = int.tryParse(durationController.text.trim()) ?? 30;
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .update({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'duration': duration,
        'isPublished': isPublished,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quiz. $e')),
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      durationController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .where('createdBy', isEqualTo: _teacherId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load quizzes. ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            );
          }

          final quizzes = (snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[])
              .map((d) => <String, dynamic>{
                    ...d.data(),
                    'id': d.data()['id'] ?? d.id,
                  })
              .toList();

          if (quizzes.isEmpty) {
            return const Center(
              child: Text(
                'No quizzes available.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              final quizId = (quiz['id'] ?? '').toString();
              final questionsList = quiz['questions'] as List? ?? const [];
              final duration = quiz['duration'] is int
                  ? quiz['duration'] as int
                  : int.tryParse((quiz['duration'] ?? '').toString()) ?? 30;

              if (quizId.isEmpty) {
                return _QuizManagementCard(
                  title: (quiz['title'] ?? '').toString(),
                  questions: questionsList.length,
                  duration: duration,
                  submissions: 0,
                  avgScore: 0,
                  onView: () {
                    Navigator.pushNamed(
                      context,
                      '/quiz-detail',
                      arguments: quiz,
                    );
                  },
                  onEdit: null,
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('quiz_results')
                    .where('quizId', isEqualTo: quizId)
                    .snapshots(),
                builder: (context, resultsSnapshot) {
                  final resultDocs = resultsSnapshot.data?.docs ?? [];
                  final submissions = resultDocs.length;
                  double avg = 0;
                  if (submissions > 0) {
                    final totalPct = resultDocs.map((d) {
                      final data = d.data();
                      final score = (data['score'] as num?)?.toDouble() ?? 0.0;
                      final totalPoints =
                          (data['totalPoints'] as num?)?.toDouble() ?? 0.0;
                      if (totalPoints <= 0) return 0.0;
                      return (score / totalPoints) * 100;
                    }).reduce((a, b) => a + b);
                    avg = totalPct / submissions;
                  }

                  return _QuizManagementCard(
                    title: (quiz['title'] ?? '').toString(),
                    questions: questionsList.length,
                    duration: duration,
                    submissions: submissions,
                    avgScore: avg,
                    onView: () {
                      Navigator.pushNamed(
                        context,
                        '/quiz-detail',
                        arguments: quiz,
                      );
                    },
                    onEdit: () => _showEditDialog(quizId: quizId, quiz: quiz),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/admin-create-quiz');
        },
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New Quiz'),
      ),
    );
  }
}

class _StudentsPage extends StatefulWidget {
  final UserModel? currentUser;

  const _StudentsPage({this.currentUser});

  @override
  State<_StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<_StudentsPage> {
  List<String>? get _teacherSections => widget.currentUser?.sectionsHandled;
  final TextEditingController _searchController = TextEditingController();

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStudentsStream() {
    // Build query for students based on teacher's subjects and sections
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('verified', isEqualTo: true);

    // Filter by grade level if teacher has sectionsHandled
    if (_teacherSections != null && _teacherSections!.isNotEmpty) {
      // Filter by sections - need to use where with array-contains for each section
      // Since Firestore doesn't support OR queries, we'll filter in memory
      return query.snapshots();
    }

    // If no sections specified, return all verified students
    return query.snapshots();
  }

  bool _isStudentInTeacherScope(Map<String, dynamic> studentData) {
    // Check if student's grade level is in teacher's sectionsHandled
    final studentGrade = studentData['gradeLevel'] as String?;
    final studentSection = studentData['section'] as String?;

    if (_teacherSections != null && _teacherSections!.isNotEmpty) {
      // Check if student's grade level or section matches any of teacher's sections
      if (studentGrade != null && _teacherSections!.contains(studentGrade)) {
        return true;
      }
      if (studentSection != null &&
          _teacherSections!.contains(studentSection)) {
        return true;
      }
      return false;
    }

    // If no sections specified, show all students
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = _searchController.text.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search student name or email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildStudentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load students. ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final scopeFilteredDocs = docs.where((doc) {
                  return _isStudentInTeacherScope(doc.data());
                }).toList();

                final filteredDocs = searchTerm.isEmpty
                    ? scopeFilteredDocs
                    : scopeFilteredDocs.where((doc) {
                        final data = doc.data();
                        final name =
                            (data['name'] as String? ?? '').toLowerCase();
                        final email =
                            (data['email'] as String? ?? '').toLowerCase();
                        return name.contains(searchTerm) ||
                            email.contains(searchTerm);
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No students found.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final studentId = doc.id;

                    final name = (data['name'] as String?) ?? 'Student';
                    final email = (data['email'] as String?) ?? '';
                    final grade = (data['gradeLevel'] as String?) ?? '';

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('quiz_results')
                          .where('studentId', isEqualTo: studentId)
                          .snapshots(),
                      builder: (context, resultsSnapshot) {
                        final resultDocs = resultsSnapshot.data?.docs ?? [];
                        final attempts = resultDocs.length;
                        double avg = 0;
                        if (attempts > 0) {
                          final totalPct = resultDocs.map((d) {
                            final r = d.data();
                            final score =
                                (r['score'] as num?)?.toDouble() ?? 0.0;
                            final totalPoints =
                                (r['totalPoints'] as num?)?.toDouble() ?? 0.0;
                            if (totalPoints <= 0) return 0.0;
                            return (score / totalPoints) * 100;
                          }).reduce((a, b) => a + b);
                          avg = totalPct / attempts;
                        }

                        return _StudentCard(
                          name: name,
                          email: email,
                          gradeLevel: grade,
                          attempts: attempts,
                          avgScore: avg,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: AppConstants.fontS,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _LessonManagementCard extends StatelessWidget {
  final String title;
  final String subject;
  final String gradeLevel;
  final bool isPublished;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _LessonManagementCard({
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.isPublished,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM,
                      vertical: AppConstants.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusRound),
                    ),
                    child: Text(
                      isPublished ? 'Published' : 'Draft',
                      style: TextStyle(
                        fontSize: AppConstants.fontS,
                        fontWeight: FontWeight.w600,
                        color:
                            isPublished ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                '$subject • $gradeLevel',
                style: const TextStyle(
                  fontSize: AppConstants.fontM,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizManagementCard extends StatelessWidget {
  final String title;
  final int questions;
  final int duration;
  final int submissions;
  final double avgScore;
  final VoidCallback? onView;
  final VoidCallback? onEdit;

  const _QuizManagementCard({
    required this.title,
    required this.questions,
    required this.duration,
    required this.submissions,
    required this.avgScore,
    this.onView,
    this.onEdit,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: AppConstants.fontL,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              '$questions questions • $duration min',
              style: const TextStyle(
                fontSize: AppConstants.fontM,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                _QuizStat(label: 'Submissions', value: '$submissions'),
                const SizedBox(width: AppConstants.paddingL),
                _QuizStat(label: 'Avg Score', value: '${avgScore.toInt()}%'),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
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

class _QuizStat extends StatelessWidget {
  final String label;
  final String value;

  const _QuizStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppConstants.fontS,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppConstants.fontL,
            fontWeight: FontWeight.bold,
            color: AppColors.teacherPrimary,
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String name;
  final String email;
  final String gradeLevel;
  final int attempts;
  final double avgScore;

  const _StudentCard({
    required this.name,
    required this.email,
    required this.gradeLevel,
    required this.attempts,
    required this.avgScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.teacherPrimary,
          child: Icon(Icons.person, color: AppColors.textWhite),
        ),
        title: Text(name),
        subtitle: Text(
          [
            if (email.isNotEmpty) email,
            if (gradeLevel.isNotEmpty) gradeLevel,
          ].join(' • '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${avgScore.toInt()}%',
              style: const TextStyle(
                fontSize: AppConstants.fontL,
                fontWeight: FontWeight.bold,
                color: AppColors.teacherPrimary,
              ),
            ),
            Text(
              '$attempts attempts',
              style: const TextStyle(
                fontSize: AppConstants.fontS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: null,
      ),
    );
  }
}

DateTime _parseFirestoreDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  return '${diff.inDays} days ago';
}
