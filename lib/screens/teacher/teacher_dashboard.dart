import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardHome(),
    const _LessonsManagement(),
    const _QuizzesManagement(),
    const _StudentsPage(),
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
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Prof. Jane Smith',
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
                      'Physics Teacher',
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

            // Analytics Stats
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Students',
                      value: '156',
                      icon: Icons.people_outline,
                      color: AppColors.teacherPrimary,
                      subtitle: 'Active',
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StatCard(
                      title: 'Lessons',
                      value: '24',
                      icon: Icons.book_outlined,
                      color: AppColors.studentPrimary,
                      subtitle: 'Published',
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
                      value: '82%',
                      icon: Icons.trending_up_outlined,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: StatCard(
                      title: 'Quizzes',
                      value: '18',
                      icon: Icons.quiz_outlined,
                      color: AppColors.warning,
                      subtitle: 'Active',
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
              title: 'Create New Lesson',
              description: 'Add a new lesson with content and materials',
              icon: Icons.add_box_outlined,
              iconColor: AppColors.teacherPrimary,
              onTap: () {},
            ),

            FeatureCard(
              title: 'Create Quiz',
              description: 'Design a new quiz for your students',
              icon: Icons.quiz_outlined,
              iconColor: AppColors.studentPrimary,
              onTap: () {},
            ),

            FeatureCard(
              title: 'View Reports',
              description: 'Check student performance and analytics',
              icon: Icons.analytics_outlined,
              iconColor: AppColors.warning,
              onTap: () {
                Navigator.pushNamed(context, '/teacher-score-reports');
              },
            ),

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

            _ActivityCard(
              title: 'Quiz Submitted',
              subtitle:
                  '25 students completed ${AppConstants.allLessons.first['subject']} Quiz',
              time: '2 hours ago',
              icon: Icons.assignment_turned_in_outlined,
              color: AppColors.success,
            ),

            _ActivityCard(
              title: 'New Lesson Published',
              subtitle:
                  '${AppConstants.allLessons.first['title']} is now available',
              time: '5 hours ago',
              icon: Icons.publish_outlined,
              color: AppColors.studentPrimary,
            ),

            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }
}

class _LessonsManagement extends StatelessWidget {
  const _LessonsManagement();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Lessons'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        itemCount: AppConstants.allLessons.length,
        itemBuilder: (context, index) {
          final lesson = AppConstants.allLessons[index];
          return _LessonManagementCard(
            title: lesson['title'],
            subject: lesson['subject'],
            gradeLevel: lesson['grade'],
            students: 30 + (index * 15), // Varying student counts
            isPublished: index % 2 == 0,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New Lesson'),
      ),
    );
  }
}

class _QuizzesManagement extends StatelessWidget {
  const _QuizzesManagement();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        itemCount: 5,
        itemBuilder: (context, index) {
          return _QuizManagementCard(
            title: 'Quiz ${index + 1}',
            questions: 10,
            duration: 30,
            submissions: 32,
            avgScore: 85.0,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New Quiz'),
      ),
    );
  }
}

class _StudentsPage extends StatelessWidget {
  const _StudentsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _StudentCard(
            name: 'Student ${index + 1}',
            gradeLevel: 'Grade 9',
            avgScore: 75.0 + (index * 2),
            completedLessons: 6 + index,
          );
        },
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
  final int students;
  final bool isPublished;

  const _LessonManagementCard({
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.students,
    required this.isPublished,
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
            const SizedBox(height: AppConstants.paddingS),
            Text(
              '$students students enrolled',
              style: const TextStyle(
                fontSize: AppConstants.fontS,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
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

class _QuizManagementCard extends StatelessWidget {
  final String title;
  final int questions;
  final int duration;
  final int submissions;
  final double avgScore;

  const _QuizManagementCard({
    required this.title,
    required this.questions,
    required this.duration,
    required this.submissions,
    required this.avgScore,
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
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
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
  final String gradeLevel;
  final double avgScore;
  final int completedLessons;

  const _StudentCard({
    required this.name,
    required this.gradeLevel,
    required this.avgScore,
    required this.completedLessons,
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
        subtitle: Text('$gradeLevel • $completedLessons lessons completed'),
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
            const Text(
              'Avg Score',
              style: TextStyle(
                fontSize: AppConstants.fontS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
