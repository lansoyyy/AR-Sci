import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  String _selectedTimeRange = '30days';
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

  String? get _teacherId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Analytics'),
        backgroundColor: AppColors.teacherPrimary,
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
            _buildOverviewSection(),
            const SizedBox(height: AppConstants.paddingXL),
            
            _buildSectionHeader('Lesson Engagement'),
            const SizedBox(height: AppConstants.paddingM),
            _buildLessonEngagementSection(),
            const SizedBox(height: AppConstants.paddingXL),
            
            _buildSectionHeader('Quiz Performance'),
            const SizedBox(height: AppConstants.paddingM),
            _buildQuizPerformanceSection(),
            const SizedBox(height: AppConstants.paddingXL),
            
            _buildSectionHeader('Student Activity'),
            const SizedBox(height: AppConstants.paddingM),
            _buildStudentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .where('createdBy', isEqualTo: _teacherId)
          .snapshots(),
      builder: (context, lessonsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('quizzes')
              .where('createdBy', isEqualTo: _teacherId)
              .snapshots(),
          builder: (context, quizzesSnapshot) {
            final lessonsCount = lessonsSnapshot.data?.docs.length ?? 0;
            final quizzesCount = quizzesSnapshot.data?.docs.length ?? 0;
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'My Lessons',
                        value: lessonsCount.toString(),
                        icon: Icons.book_outlined,
                        color: AppColors.teacherPrimary,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: StatCard(
                        title: 'My Quizzes',
                        value: quizzesCount.toString(),
                        icon: Icons.quiz_outlined,
                        color: AppColors.warning,
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

  Widget _buildLessonEngagementSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .where('createdBy', isEqualTo: _teacherId)
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
                                  color: AppColors.teacherPrimary,
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
          .collection('quizzes')
          .where('createdBy', isEqualTo: _teacherId)
          .snapshots(),
      builder: (context, quizzesSnapshot) {
        if (!quizzesSnapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingXL),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final quizzes = quizzesSnapshot.data?.docs ?? [];
        final quizIds = quizzes.map((q) => q.id).toList();

        if (quizIds.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingL),
              child: Text('No quizzes created yet'),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('quiz_results')
              .where('quizId', whereIn: quizIds.take(10).toList())
              .orderBy('completedAt', descending: true)
              .snapshots(),
          builder: (context, resultsSnapshot) {
            final results = resultsSnapshot.data?.docs ?? [];
            
            if (results.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingL),
                  child: Text('No quiz attempts yet'),
                ),
              );
            }

            // Calculate averages by quiz
            final quizStats = <String, Map<String, dynamic>>{};
            for (final result in results) {
              final data = result.data();
              final quizId = data['quizId'] as String? ?? 'unknown';
              final score = (data['score'] as num?)?.toDouble() ?? 0;
              final total = (data['totalPoints'] as num?)?.toDouble() ?? 1;
              final percentage = (score / total) * 100;

              if (!quizStats.containsKey(quizId)) {
                quizStats[quizId] = {
                  'scores': <double>[],
                  'attempts': 0,
                };
              }
              quizStats[quizId]!['scores'].add(percentage);
              quizStats[quizId]!['attempts'] = (quizStats[quizId]!['attempts'] as int) + 1;
            }

            // Get quiz titles
            final quizAverages = quizStats.entries.map((entry) {
              final quizDoc = quizzes.firstWhere((q) => q.id == entry.key, 
                  orElse: () => quizzes.first);
              final scores = entry.value['scores'] as List<double>;
              final avg = scores.reduce((a, b) => a + b) / scores.length;
              return {
                'id': entry.key,
                'title': quizDoc.data()['title'] ?? 'Unknown Quiz',
                'average': avg,
                'attempts': entry.value['attempts'],
              };
            }).toList()
              ..sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

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
                              spots: quizAverages.asMap().entries.map((entry) {
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
                    ...quizAverages.map((quiz) {
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
      },
    );
  }

  Widget _buildStudentActivitySection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quiz_results')
          .orderBy('completedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        final results = snapshot.data?.docs ?? [];
        
        // Get unique students who took quizzes recently
        final studentIds = results.map((r) => r.data()['studentId'] as String?).toSet();
        
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.people, color: AppColors.teacherPrimary),
                title: const Text('Recent Student Activity'),
                subtitle: Text('${results.length} recent quiz attempts'),
              ),
              const Divider(height: 1),
              ...results.take(5).map((result) {
                final data = result.data();
                final quizTitle = data['quizTitle'] as String? ?? 'Quiz';
                final score = (data['score'] as num?)?.toDouble() ?? 0;
                final total = (data['totalPoints'] as num?)?.toDouble() ?? 1;
                final percentage = (score / total) * 100;
                final studentName = data['studentName'] as String? ?? 'Student';
                
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: percentage >= 70 
                        ? AppColors.success 
                        : percentage >= 50 
                            ? AppColors.warning 
                            : AppColors.error,
                    child: Text(
                      '${percentage.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(studentName),
                  subtitle: Text(quizTitle),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
