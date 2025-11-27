import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/quiz_card.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardHome(),
    const _LessonsPage(),
    const _QuizzesPage(),
    const _ProgressPage(),
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
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: AppConstants.fontL,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  const Text(
                    'John Doe',
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
                      'Grade 9',
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

            // Stats Section
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Lessons',
                      value: '12',
                      icon: Icons.book_outlined,
                      color: AppColors.studentPrimary,
                      subtitle: 'Completed',
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StatCard(
                      title: 'Quizzes',
                      value: '8',
                      icon: Icons.quiz_outlined,
                      color: AppColors.success,
                      subtitle: 'Passed',
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
                      title: 'Avg Score',
                      value: '85%',
                      icon: Icons.star_outline,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StatCard(
                      title: 'Streak',
                      value: '7',
                      icon: Icons.local_fire_department_outlined,
                      color: AppColors.error,
                      subtitle: 'Days',
                    ),
                  ),
                ],
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
                  onTap: () {
                    // Get first available lesson for AR demo
                    final firstLesson = AppConstants.allLessons.first;
                    Navigator.pushNamed(
                      context,
                      '/ar-view',
                      arguments: firstLesson,
                    );
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
            ...AppConstants.allLessons.take(2).map((lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
                  child: LessonCard(
                    lesson: LessonModel(
                      id: lesson['id'],
                      title: lesson['title'],
                      description: lesson['description'],
                      subject: lesson['subject'],
                      gradeLevel: lesson['grade'],
                      content: '',
                      teacherId: '1',
                      createdAt: DateTime.now(),
                      isPublished: true,
                    ),
                    showProgress: true,
                    progress:
                        0.3 + (AppConstants.allLessons.indexOf(lesson) * 0.2),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/lesson-detail',
                        arguments: lesson,
                      );
                    },
                  ),
                )),

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
            QuizCard(
              quiz: QuizModel(
                id: 'quiz_${AppConstants.allLessons.first['id']}',
                title: '${AppConstants.allLessons.first['subject']} Quiz',
                description:
                    'Test your knowledge on ${AppConstants.allLessons.first['title']}',
                lessonId: AppConstants.allLessons.first['id'],
                subject: AppConstants.allLessons.first['subject'],
                gradeLevel: AppConstants.allLessons.first['grade'],
                questions: [],
                duration: 30,
                createdAt: DateTime.now(),
                isPublished: true,
              ),
              onTap: () {
                Navigator.pushNamed(context, '/quiz-detail');
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
  const _LessonsPage();

  @override
  State<_LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<_LessonsPage> {
  String _selectedFilter = 'All';

  List<Map<String, dynamic>> get _filteredLessons {
    final all = AppConstants.allLessons;

    if (_selectedFilter == 'All') {
      return all;
    }

    if (_selectedFilter == 'Quarter 3' || _selectedFilter == 'Quarter 4') {
      return all
          .where((lesson) => lesson['quarter'] == _selectedFilter)
          .toList();
    }

    if (_selectedFilter == 'Grade 9') {
      return all.where((lesson) => lesson['grade'] == 'Grade 9').toList();
    }

    if (AppConstants.subjects.contains(_selectedFilter)) {
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
    final lessons = _filteredLessons;

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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'All',
                    onSelected: (_) => _onFilterSelected('All'),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  _FilterChip(
                    label: 'Quarter 3',
                    isSelected: _selectedFilter == 'Quarter 3',
                    onSelected: (_) => _onFilterSelected('Quarter 3'),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  _FilterChip(
                    label: 'Quarter 4',
                    isSelected: _selectedFilter == 'Quarter 4',
                    onSelected: (_) => _onFilterSelected('Quarter 4'),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  _FilterChip(
                    label: 'Grade 9',
                    isSelected: _selectedFilter == 'Grade 9',
                    onSelected: (_) => _onFilterSelected('Grade 9'),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  ...AppConstants.subjects.map((subject) => Padding(
                        padding:
                            const EdgeInsets.only(left: AppConstants.paddingS),
                        child: _FilterChip(
                          label: subject,
                          isSelected: _selectedFilter == subject,
                          onSelected: (_) => _onFilterSelected(subject),
                        ),
                      )),
                ],
              ),
            ),
          ),

          // Lessons List
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(vertical: AppConstants.paddingM),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return LessonCard(
                  lesson: LessonModel(
                    id: lesson['id'],
                    title: lesson['title'],
                    description: lesson['description'],
                    subject: lesson['subject'],
                    gradeLevel: lesson['grade'],
                    content: '',
                    teacherId: '1',
                    createdAt: DateTime.now(),
                    isPublished: true,
                  ),
                  showProgress: true,
                  progress: (index + 1) * 0.15,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/lesson-detail',
                      arguments: lesson,
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
  const _QuizzesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        itemCount: 5,
        itemBuilder: (context, index) {
          return QuizCard(
            quiz: QuizModel(
              id: '$index',
              title: 'Quiz ${index + 1}',
              description: 'Test your knowledge',
              lessonId: '1',
              subject: 'Physics',
              gradeLevel: 'Grade 9',
              questions: List.generate(
                  10,
                  (i) => QuizQuestion(
                        id: '$i',
                        question: 'Question $i',
                        type: QuestionType.multipleChoice,
                        options: ['A', 'B', 'C', 'D'],
                        correctAnswer: 'A',
                      )),
              duration: 30,
              createdAt: DateTime.now(),
              isPublished: true,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/quiz-detail');
            },
          );
        },
      ),
    );
  }
}

class _ProgressPage extends StatelessWidget {
  const _ProgressPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: AppColors.studentPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Progress Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  children: [
                    const Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: AppConstants.fontXL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: 0.75,
                              strokeWidth: 12,
                              backgroundColor: AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.studentPrimary,
                              ),
                            ),
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '75%',
                                style: TextStyle(
                                  fontSize: AppConstants.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.studentPrimary,
                                ),
                              ),
                              Text(
                                'Complete',
                                style: TextStyle(
                                  fontSize: AppConstants.fontM,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // Subject Progress
            const Text(
              'Subject Progress',
              style: TextStyle(
                fontSize: AppConstants.fontXL,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            _SubjectProgress(
                subject: 'Physics', progress: 0.85, color: AppColors.physics),
            _SubjectProgress(
                subject: 'Chemistry',
                progress: 0.70,
                color: AppColors.chemistry),
            _SubjectProgress(
                subject: 'Biology', progress: 0.65, color: AppColors.biology),

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

            _ScoreCard(title: 'Physics Quiz 1', score: 90, total: 100),
            _ScoreCard(title: 'Chemistry Quiz 2', score: 85, total: 100),
            _ScoreCard(title: 'Biology Quiz 1', score: 78, total: 100),
          ],
        ),
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

class _SubjectProgress extends StatelessWidget {
  final String subject;
  final double progress;
  final Color color;

  const _SubjectProgress({
    required this.subject,
    required this.progress,
    required this.color,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: AppConstants.fontL,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: AppConstants.fontL,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
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
