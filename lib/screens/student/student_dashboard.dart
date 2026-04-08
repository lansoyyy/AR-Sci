import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';
import '../../utils/colors.dart';
import '../../utils/content_utils.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/quiz_card.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_model.dart';
import '../../models/user_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            setState(() {
              _currentUser = UserModel.fromJson(data);
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update screens with current user data
    final updatedScreens = <Widget>[
      _DashboardHome(
        currentUser: _currentUser,
        isLoading: _isLoading,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      _LessonsPage(currentUser: _currentUser),
      _QuizzesPage(currentUser: _currentUser),
      const _ProgressPage(),
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
          selectedItemColor: AppColors.studentPrimary,
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
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _parseFirestoreDate(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.now();
}

LessonModel _lessonModelFromMap(Map<String, dynamic> lesson) {
  return LessonModel.fromJson({
    ...lesson,
    'id': (lesson['id'] ?? '').toString(),
    'teacherId':
        (lesson['teacherId'] ?? lesson['createdBy'] ?? 'admin').toString(),
    'gradeLevel': (lesson['gradeLevel'] ?? lesson['grade'] ?? '').toString(),
  });
}

QuizModel _quizModelFromMap(Map<String, dynamic> quiz) {
  return QuizModel.fromJson({
    ...quiz,
    'id': (quiz['id'] ?? '').toString(),
    'gradeLevel': (quiz['gradeLevel'] ?? quiz['grade'] ?? '').toString(),
  });
}

Map<String, dynamic> _mapFirestoreDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  return <String, dynamic>{
    ...doc.data(),
    'id': doc.data()['id'] ?? doc.id,
  };
}

List<Map<String, dynamic>> _sortVisibleContent(
    List<Map<String, dynamic>> items) {
  items.sort((a, b) {
    final aDate = parseFlexibleDate(a['availableFrom']) ??
        _parseFirestoreDate(a['createdAt']);
    final bDate = parseFlexibleDate(b['availableFrom']) ??
        _parseFirestoreDate(b['createdAt']);
    return bDate.compareTo(aDate);
  });
  return items;
}

List<Map<String, dynamic>> _visibleLessonsForStudent(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  UserModel? student,
) {
  final items = docs
      .map(_mapFirestoreDoc)
      .where((lesson) => canStudentAccessContent(lesson, student))
      .toList();
  return _sortVisibleContent(items);
}

List<Map<String, dynamic>> _visibleQuizzesForStudent(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  UserModel? student,
) {
  final items = docs
      .map(_mapFirestoreDoc)
      .where((quiz) => canStudentAccessContent(quiz, student))
      .toList();
  return _sortVisibleContent(items);
}

class _DashboardHome extends StatelessWidget {
  final UserModel? currentUser;
  final bool isLoading;
  final Function(int) onNavigate;

  const _DashboardHome({
    this.currentUser,
    this.isLoading = false,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final studentId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: AppColors.studentPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications',
                  arguments: 'student');
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.studentBookmarks);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile', arguments: 'student');
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
                    AppColors.studentPrimary,
                    AppColors.studentLight,
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
                            Text(
                              isLoading
                                  ? 'Loading...'
                                  : (currentUser?.name ?? 'Student'),
                              style: const TextStyle(
                                fontSize: AppConstants.fontXXL,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingS),
                            if (currentUser?.gradeLevel != null)
                              Wrap(
                                spacing: AppConstants.paddingS,
                                runSpacing: AppConstants.paddingS,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.paddingM,
                                      vertical: AppConstants.paddingS,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.textWhite.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.radiusRound),
                                    ),
                                    child: Text(
                                      currentUser!.gradeLevel!,
                                      style: const TextStyle(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if ((currentUser?.section ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppConstants.paddingM,
                                        vertical: AppConstants.paddingS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.textWhite
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                            AppConstants.radiusRound),
                                      ),
                                      child: Text(
                                        currentUser!.section!,
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
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

            // Stats Section
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('lessons')
                    .where('isPublished', isEqualTo: true)
                    .snapshots(),
                builder: (context, lessonsSnapshot) {
                  final lessonsCount = _visibleLessonsForStudent(
                    lessonsSnapshot.data?.docs ??
                        const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    currentUser,
                  ).length;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('quizzes')
                        .where('isPublished', isEqualTo: true)
                        .snapshots(),
                    builder: (context, quizzesSnapshot) {
                      final quizzesCount = _visibleQuizzesForStudent(
                        quizzesSnapshot.data?.docs ??
                            const <QueryDocumentSnapshot<
                                Map<String, dynamic>>>[],
                        currentUser,
                      ).length;

                      final resultsStream = studentId == null
                          ? const Stream<
                              QuerySnapshot<Map<String, dynamic>>>.empty()
                          : FirebaseFirestore.instance
                              .collection('quiz_results')
                              .where('studentId', isEqualTo: studentId)
                              .snapshots();

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: resultsStream,
                        builder: (context, resultsSnapshot) {
                          final resultDocs = resultsSnapshot.data?.docs ?? [];
                          final attempts = resultDocs.length;

                          double avg = 0;
                          if (attempts > 0) {
                            final totalPct = resultDocs.map((d) {
                              final data = d.data();
                              final score =
                                  (data['score'] as num?)?.toDouble() ?? 0;
                              final totalPoints =
                                  (data['totalPoints'] as num?)?.toDouble() ??
                                      0;
                              if (totalPoints <= 0) return 0.0;
                              return (score / totalPoints) * 100;
                            }).reduce((a, b) => a + b);
                            avg = totalPct / attempts;
                          }

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Lessons',
                                      value: lessonsCount.toString(),
                                      icon: Icons.book_outlined,
                                      color: AppColors.studentPrimary,
                                      subtitle: 'Available',
                                      onTap: () => onNavigate(1),
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.paddingM),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Quizzes',
                                      value: quizzesCount.toString(),
                                      icon: Icons.quiz_outlined,
                                      color: AppColors.success,
                                      subtitle: 'Available',
                                      onTap: () => onNavigate(2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.paddingM),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Avg Score',
                                      value: '${avg.toStringAsFixed(0)}%',
                                      icon: Icons.star_outline,
                                      color: AppColors.warning,
                                      onTap: () => onNavigate(3),
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.paddingM),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Attempts',
                                      value: attempts.toString(),
                                      icon: Icons.assignment_turned_in_outlined,
                                      color: AppColors.error,
                                      subtitle: 'Quizzes',
                                      onTap: () => onNavigate(2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // AR Quick Access
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Card(
                color: AppColors.studentPrimary,
                child: InkWell(
                  onTap: () async {
                    try {
                      final snapshot = await FirebaseFirestore.instance
                          .collection('lessons')
                          .where('isPublished', isEqualTo: true)
                          .limit(50)
                          .get();

                      final visibleLessons = _visibleLessonsForStudent(
                        snapshot.docs,
                        currentUser,
                      );

                      if (visibleLessons.isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'No AR-ready lessons are available for you right now.')),
                        );
                        return;
                      }

                      final firstLesson = visibleLessons.first;

                      if (!context.mounted) return;
                      Navigator.pushNamed(
                        context,
                        '/ar-view',
                        arguments: firstLesson,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open AR. $e')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.textWhite.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusM),
                          ),
                          child: const Icon(
                            Icons.view_in_ar,
                            color: AppColors.textWhite,
                            size: AppConstants.iconL,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingM),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AR Science Lab',
                                style: TextStyle(
                                  fontSize: AppConstants.fontL,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite,
                                ),
                              ),
                              SizedBox(height: AppConstants.paddingXS),
                              Text(
                                'Explore 3D models and simulations',
                                style: TextStyle(
                                  fontSize: AppConstants.fontM,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.textWhite,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // Recent Lessons
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Text(
                'Continue Learning',
                style: TextStyle(
                  fontSize: AppConstants.fontXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            // Show lessons from constants
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .where('isPublished', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingM),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allDocs = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final firebaseLessons = _visibleLessonsForStudent(
                  allDocs,
                  currentUser,
                ).take(2).toList();

                if (firebaseLessons.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingM),
                    child: Center(
                      child: Text(
                        'No lessons available.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return Column(
                  children: firebaseLessons.map((lesson) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.paddingM),
                      child: LessonCard(
                        lesson: _lessonModelFromMap(lesson),
                        showProgress: false,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/lesson-detail',
                            arguments: lesson,
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // Upcoming Quizzes
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Text(
                'Upcoming Quizzes',
                style: TextStyle(
                  fontSize: AppConstants.fontXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            // Show quiz for first lesson
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('quizzes')
                  .where('isPublished', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final allDocs = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingM),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final items = _visibleQuizzesForStudent(allDocs, currentUser)
                    .take(2)
                    .toList();

                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingM),
                    child: Center(
                      child: Text(
                        'No quizzes available.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return Column(
                  children: items.map((quizMap) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.paddingM),
                      child: QuizCard(
                        quiz: _quizModelFromMap(quizMap),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/quiz-detail',
                            arguments: quizMap,
                          );
                        },
                      ),
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

class _LessonsPage extends StatefulWidget {
  final UserModel? currentUser;

  const _LessonsPage({this.currentUser});

  @override
  State<_LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<_LessonsPage> {
  String _selectedFilter = 'All';

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> all) {
    if (_selectedFilter == 'All') {
      return all;
    }

    if (_selectedFilter.startsWith('Quarter')) {
      return all
          .where((lesson) => lesson['quarter'] == _selectedFilter)
          .toList();
    }

    final grade = (all.isNotEmpty
            ? (all.first['gradeLevel'] ?? all.first['grade'])
            : null)
        ?.toString();
    if (grade != null && grade.isNotEmpty) {
      final hasGrade = all.any((lesson) {
        final g = (lesson['gradeLevel'] ?? lesson['grade'] ?? '').toString();
        return g == _selectedFilter;
      });
      if (hasGrade) {
        return all.where((lesson) {
          final g = (lesson['gradeLevel'] ?? lesson['grade'] ?? '').toString();
          return g == _selectedFilter;
        }).toList();
      }
    }

    final hasSubject = all.any(
        (lesson) => (lesson['subject'] ?? '').toString() == _selectedFilter);
    if (hasSubject) {
      return all
          .where((lesson) => lesson['subject'] == _selectedFilter)
          .toList();
    }

    return all;
  }

  void _onFilterSelected(String label) {
    setState(() {
      _selectedFilter = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lessons'),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .where('isPublished', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final allDocs = snapshot.data?.docs ?? [];
                final visibleLessons = _visibleLessonsForStudent(
                  allDocs,
                  widget.currentUser,
                );
                final quarters = visibleLessons
                    .map((lesson) => (lesson['quarter'] ?? '').toString())
                    .where((s) => s.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
                final grades = visibleLessons
                    .map((lesson) =>
                        (lesson['gradeLevel'] ?? lesson['grade'] ?? '')
                            .toString())
                    .where((s) => s.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
                final subjects = visibleLessons
                    .map((lesson) => (lesson['subject'] ?? '').toString())
                    .where((s) => s.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

                final labels = <String>[
                  'All',
                  ...quarters,
                  ...grades,
                  ...subjects,
                ];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: labels.map((label) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(right: AppConstants.paddingS),
                        child: _FilterChip(
                          label: label,
                          isSelected: _selectedFilter == label,
                          onSelected: (_) => _onFilterSelected(label),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          // Lessons List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .where('isPublished', isEqualTo: true)
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

                final allDocs = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final lessons = _applyFilter(
                  _visibleLessonsForStudent(allDocs, widget.currentUser),
                );

                if (lessons.isEmpty) {
                  return const Center(
                    child: Text(
                      'No lessons available.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingM),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return LessonCard(
                      lesson: _lessonModelFromMap(lesson),
                      showProgress: false,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/lesson-detail',
                          arguments: lesson,
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

class _QuizzesPage extends StatelessWidget {
  final UserModel? currentUser;

  const _QuizzesPage({this.currentUser});

  @override
  Widget build(BuildContext context) {
    return _QuizzesPageBody(currentUser: currentUser);
  }
}

class _QuizzesPageBody extends StatefulWidget {
  final UserModel? currentUser;

  const _QuizzesPageBody({this.currentUser});

  @override
  State<_QuizzesPageBody> createState() => _QuizzesPageBodyState();
}

class _QuizzesPageBodyState extends State<_QuizzesPageBody> {
  String _selectedFilter = 'All';

  void _onFilterSelected(String label) {
    setState(() => _selectedFilter = label);
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> all) {
    if (_selectedFilter == 'All') return all;

    final hasGrade = all.any((q) {
      final g = (q['gradeLevel'] ?? q['grade'] ?? '').toString();
      return g == _selectedFilter;
    });

    if (hasGrade) {
      return all.where((q) {
        final g = (q['gradeLevel'] ?? q['grade'] ?? '').toString();
        return g == _selectedFilter;
      }).toList();
    }

    final hasSubject =
        all.any((q) => (q['subject'] ?? '').toString() == _selectedFilter);
    if (hasSubject) {
      return all
          .where((q) => (q['subject'] ?? '').toString() == _selectedFilter)
          .toList();
    }

    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('quizzes')
                  .where('isPublished', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final allDocs = snapshot.data?.docs ?? [];
                final visibleQuizzes = _visibleQuizzesForStudent(
                  allDocs,
                  widget.currentUser,
                );
                final grades = visibleQuizzes
                    .map((quiz) =>
                        (quiz['gradeLevel'] ?? quiz['grade'] ?? '').toString())
                    .where((s) => s.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
                final subjects = visibleQuizzes
                    .map((quiz) => (quiz['subject'] ?? '').toString())
                    .where((s) => s.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

                final labels = <String>['All', ...grades, ...subjects];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: labels.map((label) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(right: AppConstants.paddingS),
                        child: _FilterChip(
                          label: label,
                          isSelected: _selectedFilter == label,
                          onSelected: (_) => _onFilterSelected(label),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('quizzes')
                  .where('isPublished', isEqualTo: true)
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

                final allDocs = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final filtered = _applyFilter(
                  _visibleQuizzesForStudent(allDocs, widget.currentUser),
                );

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No quizzes available.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final quiz = filtered[index];
                    return QuizCard(
                      quiz: _quizModelFromMap(quiz),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/quiz-detail',
                          arguments: quiz,
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

class _ProgressPage extends StatefulWidget {
  const _ProgressPage();

  @override
  State<_ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<_ProgressPage> {
  final Map<String, String> _quizTitleCache = {};

  Future<void> _fetchMissingQuizTitles(List<String> quizIds) async {
    final toFetch = quizIds
        .toSet()
        .where((id) => id.isNotEmpty && !_quizTitleCache.containsKey(id))
        .toList();
    if (toFetch.isEmpty) return;
    final chunks = <List<String>>[];
    for (var i = 0; i < toFetch.length; i += 10) {
      chunks.add(toFetch.sublist(
          i, (i + 10) < toFetch.length ? (i + 10) : toFetch.length));
    }
    final newTitles = <String, String>{};
    for (final chunk in chunks) {
      final snap = await FirebaseFirestore.instance
          .collection('quizzes')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final title = (doc.data()['title'] ?? '').toString();
        newTitles[doc.id] = title;
        final cid = (doc.data()['id'] ?? '').toString();
        if (cid.isNotEmpty) newTitles[cid] = title;
      }
      final stillMissing =
          chunk.where((id) => !newTitles.containsKey(id)).toList();
      if (stillMissing.isNotEmpty) {
        final snap2 = await FirebaseFirestore.instance
            .collection('quizzes')
            .where('id', whereIn: stillMissing)
            .get();
        for (final doc in snap2.docs) {
          final title = (doc.data()['title'] ?? '').toString();
          final cid = (doc.data()['id'] ?? doc.id).toString();
          newTitles[cid] = title;
          newTitles[doc.id] = title;
        }
      }
    }
    if (newTitles.isNotEmpty && mounted) {
      setState(() => _quizTitleCache.addAll(newTitles));
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: studentId == null
          ? const Center(
              child: Text(
                'You are not logged in.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('quiz_results')
                  .where('studentId', isEqualTo: studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load progress. ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Trigger fetch for quizIds with missing titles
                final missingTitleIds = docs
                    .where((d) =>
                        (d.data()['quizTitle'] ?? '').toString().trim().isEmpty)
                    .map((d) => (d.data()['quizId'] ?? '').toString())
                    .where((id) => id.isNotEmpty)
                    .toList();
                if (missingTitleIds.isNotEmpty) {
                  _fetchMissingQuizTitles(missingTitleIds);
                }

                final entries = docs.map((d) {
                  final data = d.data();
                  final quizId = (data['quizId'] ?? d.id).toString();
                  final storedTitle =
                      (data['quizTitle'] ?? '').toString().trim();
                  final quizTitle = storedTitle.isNotEmpty
                      ? storedTitle
                      : (_quizTitleCache[quizId] ?? '');
                  final score = (data['score'] as num?)?.toInt() ?? 0;
                  final totalPoints =
                      (data['totalPoints'] as num?)?.toInt() ?? 0;
                  final completedAt = _parseFirestoreDate(data['completedAt']);
                  final pct =
                      totalPoints <= 0 ? 0.0 : (score / totalPoints) * 100;
                  return {
                    'quizId': quizId,
                    'quizTitle': quizTitle,
                    'score': score,
                    'totalPoints': totalPoints,
                    'completedAt': completedAt,
                    'percentage': pct,
                  };
                }).toList()
                  ..sort((a, b) {
                    final ad = a['completedAt'] as DateTime;
                    final bd = b['completedAt'] as DateTime;
                    return bd.compareTo(ad);
                  });

                final attempts = entries.length;
                double avg = 0;
                double best = 0;
                if (attempts > 0) {
                  final totalPct = entries
                      .map((e) => (e['percentage'] as double))
                      .reduce((a, b) => a + b);
                  avg = totalPct / attempts;
                  best = entries
                      .map((e) => (e['percentage'] as double))
                      .reduce((a, b) => a > b ? a : b);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Progress Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.paddingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quiz Progress',
                                style: TextStyle(
                                  fontSize: AppConstants.fontXL,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingM),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Attempts',
                                      value: attempts.toString(),
                                      icon: Icons.quiz_outlined,
                                      color: AppColors.studentPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.paddingM),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Average',
                                      value: '${avg.toStringAsFixed(0)}%',
                                      icon: Icons.star_outline,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.paddingM),
                              StatCard(
                                title: 'Best',
                                value: '${best.toStringAsFixed(0)}%',
                                icon: Icons.emoji_events_outlined,
                                color: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingXL),

                      // Recent Scores
                      const Text(
                        'Recent Quiz Scores',
                        style: TextStyle(
                          fontSize: AppConstants.fontXL,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingM),

                      if (entries.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppConstants.paddingM),
                            child: Text(
                              'No quiz results yet.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...entries.take(10).map((e) {
                          final storedTitle = (e['quizTitle'] as String).trim();
                          final quizId = (e['quizId'] as String);
                          final title = storedTitle.isNotEmpty
                              ? storedTitle
                              : (_quizTitleCache[quizId] ?? quizId);
                          return _ScoreCard(
                            title: title,
                            score: e['score'] as int,
                            total: e['totalPoints'] as int,
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    this.isSelected = false,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.studentPrimary.withOpacity(0.2),
      checkmarkColor: AppColors.studentPrimary,
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final int total;

  const _ScoreCard({
    required this.title,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / total) * 100;
    final color = percentage >= 80
        ? AppColors.success
        : percentage >= 60
            ? AppColors.warning
            : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Icon(Icons.quiz_outlined, color: color),
        ),
        title: Text(title),
        trailing: Text(
          '$score/$total',
          style: TextStyle(
            fontSize: AppConstants.fontL,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
