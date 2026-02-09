import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _selectedTimeRange = '7days';
  final List<String> _timeRanges = ['7days', '30days', '90days', 'all'];

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case '7days':
        return now.subtract(const Duration(days: 7));
      case '30days':
        return now.subtract(const Duration(days: 30));
      case '90days':
        return now.subtract(const Duration(days: 90));
      default:
        return DateTime(2020);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppColors.adminPrimary,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedTimeRange,
            onSelected: (value) => setState(() => _selectedTimeRange = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7days', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30days', child: Text('Last 30 Days')),
              const PopupMenuItem(value: '90days', child: Text('Last 90 Days')),
              const PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Stats
            _buildOverviewSection(),
            const SizedBox(height: AppConstants.paddingXL),
            
            // User Statistics
            _buildSectionHeader('User Statistics'),
            const SizedBox(height: AppConstants.paddingM),
            _buildUserStatsChart(),
            const SizedBox(height: AppConstants.paddingXL),
            
            // Lesson Engagement
            _buildSectionHeader('Lesson Engagement'),
            const SizedBox(height: AppConstants.paddingM),
            _buildLessonEngagementSection(),
            const SizedBox(height: AppConstants.paddingXL),
            
            // Quiz Performance
            _buildSectionHeader('Quiz Performance Trends'),
            const SizedBox(height: AppConstants.paddingM),
            _buildQuizPerformanceSection(),
            const SizedBox(height: AppConstants.paddingXL),
            
            // Top Content
            _buildSectionHeader('Top Performing Content'),
            const SizedBox(height: AppConstants.paddingM),
            _buildTopContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('quiz_results')
              .where('completedAt', isGreaterThan: Timestamp.fromDate(_startDate))
              .snapshots(),
          builder: (context, quizSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('lesson_progress')
                  .where('lastAccessed', isGreaterThan: Timestamp.fromDate(_startDate))
                  .snapshots(),
              builder: (context, lessonSnapshot) {
                final totalUsers = usersSnapshot.data?.docs.length ?? 0;
                final activeUsers = usersSnapshot.data?.docs.where((d) {
                  final verified = d.data()['verified'] as bool? ?? false;
                  return verified;
                }).length ?? 0;
                final quizAttempts = quizSnapshot.data?.docs.length ?? 0;
                final lessonViews = lessonSnapshot.data?.docs.length ?? 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Total Users',
                            value: totalUsers.toString(),
                            icon: Icons.people_outline,
                            color: AppColors.adminPrimary,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingM),
                        Expanded(
                          child: StatCard(
                            title: 'Active Users',
                            value: activeUsers.toString(),
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            subtitle: 'Verified',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Quiz Attempts',
                            value: quizAttempts.toString(),
                            icon: Icons.quiz_outlined,
                            color: AppColors.warning,
                            subtitle: _selectedTimeRange == 'all' ? 'All time' : 'This period',
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingM),
                        Expanded(
                          child: StatCard(
                            title: 'Lesson Views',
                            value: lessonViews.toString(),
                            icon: Icons.book_outlined,
                            color: AppColors.studentPrimary,
                            subtitle: _selectedTimeRange == 'all' ? 'All time' : 'This period',
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppConstants.fontXL,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildUserStatsChart() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingXL),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        int students = 0, teachers = 0, admins = 0;
        
        for (final doc in docs) {
          final role = doc.data()['role'] as String? ?? '';
          switch (role) {
            case 'student':
              students++;
              break;
            case 'teacher':
              teachers++;
              break;
            case 'admin':
              admins++;
              break;
          }
        }

        final total = students + teachers + admins;
        if (total == 0) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingL),
              child: Text('No user data available'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: students.toDouble(),
                          title: 'Students\n$students',
                          color: AppColors.studentPrimary,
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        PieChartSectionData(
                          value: teachers.toDouble(),
                          title: 'Teachers\n$teachers',
                          color: AppColors.teacherPrimary,
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        PieChartSectionData(
                          value: admins.toDouble(),
                          title: 'Admins\n$admins',
                          color: AppColors.adminPrimary,
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend('Students', AppColors.studentPrimary, students),
                    const SizedBox(width: AppConstants.paddingL),
                    _buildLegend('Teachers', AppColors.teacherPrimary, teachers),
                    const SizedBox(width: AppConstants.paddingL),
                    _buildLegend('Admins', AppColors.adminPrimary, admins),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label ($value)'),
      ],
    );
  }

  Widget _buildLessonEngagementSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .where('isPublished', isEqualTo: true)
          .snapshots(),
      builder: (context, lessonsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('lesson_progress').snapshots(),
          builder: (context, progressSnapshot) {
            if (!lessonsSnapshot.hasData) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingXL),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final lessons = lessonsSnapshot.data?.docs ?? [];
            final progress = progressSnapshot.data?.docs ?? [];

            // Calculate views per lesson
            final lessonViews = <String, int>{};
            for (final p in progress) {
              final lessonId = p.data()['lessonId'] as String?;
              if (lessonId != null) {
                lessonViews[lessonId] = (lessonViews[lessonId] ?? 0) + 1;
              }
            }

            // Sort lessons by views
            final sortedLessons = List<Map<String, dynamic>>.from(
              lessons.map((d) => {...d.data(), 'id': d.id}),
            )..sort((a, b) {
                final viewsA = lessonViews[a['id']] ?? 0;
                final viewsB = lessonViews[b['id']] ?? 0;
                return viewsB.compareTo(viewsA);
              });

            final topLessons = sortedLessons.take(5).toList();

            if (topLessons.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingL),
                  child: Text('No lesson data available'),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: topLessons.isEmpty 
                              ? 10 
                              : (lessonViews[topLessons.first['id']] ?? 0).toDouble() * 1.2,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < topLessons.length) {
                                    final title = topLessons[value.toInt()]['title'] as String? ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        title.length > 10 
                                            ? '${title.substring(0, 10)}...' 
                                            : title,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString());
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: topLessons.asMap().entries.map((entry) {
                            final views = lessonViews[entry.value['id']] ?? 0;
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: views.toDouble(),
                                  color: AppColors.studentPrimary,
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text(
                      'Top 5 Most Viewed Lessons',
                      style: TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuizPerformanceSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quiz_results')
          .orderBy('completedAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingXL),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final results = snapshot.data?.docs ?? [];
        
        if (results.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingL),
              child: Text('No quiz data available'),
            ),
          );
        }

        // Calculate average scores by quiz
        final quizStats = <String, Map<String, dynamic>>{};
        for (final result in results) {
          final data = result.data();
          final quizId = data['quizId'] as String? ?? 'unknown';
          final quizTitle = data['quizTitle'] as String? ?? 'Unknown Quiz';
          final score = (data['score'] as num?)?.toDouble() ?? 0;
          final total = (data['totalQuestions'] as num?)?.toDouble() ?? 1;
          final percentage = (score / total) * 100;

          if (!quizStats.containsKey(quizId)) {
            quizStats[quizId] = {
              'title': quizTitle,
              'scores': <double>[],
              'attempts': 0,
            };
          }
          quizStats[quizId]!['scores'].add(percentage);
          quizStats[quizId]!['attempts'] = (quizStats[quizId]!['attempts'] as int) + 1;
        }

        // Calculate averages
        final quizAverages = quizStats.entries.map((entry) {
          final scores = entry.value['scores'] as List<double>;
          final avg = scores.reduce((a, b) => a + b) / scores.length;
          return {
            'id': entry.key,
            'title': entry.value['title'],
            'average': avg,
            'attempts': entry.value['attempts'],
          };
        }).toList()
          ..sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

        final topQuizzes = quizAverages.take(5).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}%');
                            },
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: topQuizzes.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value['average'] as double,
                            );
                          }).toList(),
                          isCurved: true,
                          color: AppColors.warning,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.warning.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                // Quiz stats list
                ...topQuizzes.map((quiz) {
                  final avg = quiz['average'] as double;
                  final attempts = quiz['attempts'] as int;
                  return ListTile(
                    dense: true,
                    title: Text(
                      quiz['title'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text('$attempts attempts'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: avg >= 70 
                            ? AppColors.success 
                            : avg >= 50 
                                ? AppColors.warning 
                                : AppColors.error,
                        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                      ),
                      child: Text(
                        '${avg.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopContentSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .orderBy('viewCount', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingXL),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final lessons = snapshot.data?.docs ?? [];

        if (lessons.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingL),
              child: Text('No content data available'),
            ),
          );
        }

        return Card(
          child: Column(
            children: lessons.asMap().entries.map((entry) {
              final index = entry.key;
              final lesson = entry.value.data();
              final title = lesson['title'] as String? ?? 'Untitled';
              final subject = lesson['subject'] as String? ?? 'General';
              final views = (lesson['viewCount'] as num?)?.toInt() ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getSubjectColor(subject),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(title),
                subtitle: Text(subject),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      views.toString(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return AppColors.physics;
    if (s.contains('chemistry')) return AppColors.chemistry;
    if (s.contains('biology')) return AppColors.biology;
    if (s.contains('earth')) return AppColors.earthScience;
    return AppColors.primary;
  }
}
