import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  final bool includeAllContent;
  final String screenTitle;
  final Color accentColor;

  const TeacherAnalyticsScreen({
    super.key,
    this.includeAllContent = false,
    this.screenTitle = 'My Analytics',
    this.accentColor = AppColors.teacherPrimary,
  });

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _myQuizzes = [];
  List<Map<String, dynamic>> _myLessons = [];
  List<Map<String, dynamic>> _allQuizResults = [];
  List<Map<String, dynamic>> _lessonProgress = [];

  Map<String, Map<String, dynamic>> _quizById = {};

  String _selectedTimeRange = '7days';

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

  List<Map<String, dynamic>> get _quizResults {
    final cutoff = _startDate;
    if (_selectedTimeRange == 'all') return _allQuizResults;
    return _allQuizResults.where((r) {
      final completedAt = r['completedAt'];
      DateTime? date;
      if (completedAt is Timestamp) {
        date = completedAt.toDate();
      } else if (completedAt is String) {
        date = DateTime.tryParse(completedAt);
      }
      if (date == null) return true;
      return date.isAfter(cutoff);
    }).toList();
  }

  String? get _teacherId => FirebaseAuth.instance.currentUser?.uid;

  Color get _accentColor => widget.accentColor;

  String get _lessonsCardTitle {
    return widget.includeAllContent ? 'Lessons' : 'My Lessons';
  }

  String get _quizzesCardTitle {
    return widget.includeAllContent ? 'Quizzes' : 'My Quizzes';
  }

  String get _averageCardTitle {
    return widget.includeAllContent ? 'Overall Avg' : 'Class Avg';
  }

  String get _atRiskDescription {
    return widget.includeAllContent
        ? 'Students averaging below 60% across all quizzes.'
        : 'Students averaging below 60% across your quizzes.';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teacherId = _teacherId;
      if (!widget.includeAllContent && teacherId == null) {
        throw Exception('Not authenticated');
      }

      final quizQuery = FirebaseFirestore.instance.collection('quizzes');
      final lessonQuery = FirebaseFirestore.instance.collection('lessons');

      final quizSnap = await (widget.includeAllContent
          ? quizQuery.get()
          : quizQuery.where('createdBy', isEqualTo: teacherId).get());
      final lessonSnap = await (widget.includeAllContent
          ? lessonQuery.get()
          : lessonQuery.where('createdBy', isEqualTo: teacherId).get());
      final progressSnap =
          await FirebaseFirestore.instance.collection('lesson_progress').get();

      _myQuizzes = quizSnap.docs
          .map((d) => <String, dynamic>{
                ...d.data(),
                'id': (d.data()['id'] ?? d.id).toString(),
              })
          .toList();

      _myLessons = lessonSnap.docs
          .map((d) => <String, dynamic>{
                ...d.data(),
                'id': (d.data()['id'] ?? d.id).toString(),
              })
          .toList();

      _quizById = {for (final q in _myQuizzes) q['id'].toString(): q};

      final quizIds = _myQuizzes.map((q) => q['id'].toString()).toList();

      if (quizIds.isNotEmpty) {
        final chunks = _chunks(quizIds, 10);
        final resultSnapshots = await Future.wait(
          chunks.map(
            (chunk) => FirebaseFirestore.instance
                .collection('quiz_results')
                .where('quizId', whereIn: chunk)
                .orderBy('completedAt', descending: true)
                .get(),
          ),
        );
        _allQuizResults = resultSnapshots
            .expand((s) => s.docs)
            .map((d) => <String, dynamic>{...d.data(), 'docId': d.id})
            .toList();
      } else {
        _allQuizResults = [];
      }

      final lessonIds = _myLessons.map((l) => l['id'].toString()).toSet();
      _lessonProgress = progressSnap.docs
          .map((d) => <String, dynamic>{...d.data(), 'docId': d.id})
          .where((p) => lessonIds.contains((p['lessonId'] ?? '').toString()))
          .toList();

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<List<T>> _chunks<T>(List<T> list, int size) {
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      result.add(list.sublist(
        i,
        (i + size) < list.length ? (i + size) : list.length,
      ));
    }
    return result;
  }

  // --- Computed Properties ----------------------------------------------------

  double get _overallAverage {
    double total = 0;
    int count = 0;
    for (final r in _quizResults) {
      final score = (r['score'] as num?)?.toDouble() ?? 0;
      final pts = (r['totalPoints'] as num?)?.toDouble() ?? 0;
      if (pts > 0) {
        total += score / pts * 100;
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  int get _passingCount {
    return _quizResults.where((r) {
      final score = (r['score'] as num?)?.toDouble() ?? 0;
      final pts = (r['totalPoints'] as num?)?.toDouble() ?? 0;
      return pts > 0 && score / pts * 100 >= 60;
    }).length;
  }

  Set<String> get _uniqueStudents {
    return _quizResults
        .map((r) => (r['studentId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Map<String, _QuizStat> get _quizStats {
    final stats = <String, _QuizStat>{};
    for (final r in _quizResults) {
      final quizId = (r['quizId'] ?? '').toString();
      if (quizId.isEmpty) continue;
      final score = (r['score'] as num?)?.toDouble() ?? 0;
      final pts = (r['totalPoints'] as num?)?.toDouble() ?? 0;
      final pct = pts > 0 ? score / pts * 100 : 0.0;
      final time = (r['timeTaken'] as num?)?.toDouble() ?? 0;
      final studentId = (r['studentId'] ?? '').toString();

      if (!stats.containsKey(quizId)) {
        stats[quizId] = _QuizStat(
          quizId: quizId,
          title: (_quizById[quizId]?['title'] ?? 'Quiz').toString(),
          subject: (_quizById[quizId]?['subject'] ?? '').toString(),
          quarter: (_quizById[quizId]?['quarter'] ?? '').toString(),
        );
      }
      stats[quizId]!.addResult(pct, time,
          studentId: studentId.isEmpty ? null : studentId);
    }
    return stats;
  }

  Map<String, double> get _quarterAverages {
    final map = <String, List<double>>{};
    for (final r in _quizResults) {
      final quizId = (r['quizId'] ?? '').toString();
      final quarter = (_quizById[quizId]?['quarter'] ?? 'Other').toString();
      final key = quarter.trim().isEmpty ? 'Other' : quarter;
      final score = (r['score'] as num?)?.toDouble() ?? 0;
      final pts = (r['totalPoints'] as num?)?.toDouble() ?? 0;
      if (pts <= 0) continue;
      map.putIfAbsent(key, () => []).add(score / pts * 100);
    }
    return map.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );
  }

  Map<String, double> get _subjectAverages {
    final map = <String, List<double>>{};
    for (final r in _quizResults) {
      final quizId = (r['quizId'] ?? '').toString();
      final subject = (_quizById[quizId]?['subject'] ?? 'Other').toString();
      final key = subject.trim().isEmpty ? 'Other' : subject;
      final score = (r['score'] as num?)?.toDouble() ?? 0;
      final pts = (r['totalPoints'] as num?)?.toDouble() ?? 0;
      if (pts <= 0) continue;
      map.putIfAbsent(key, () => []).add(score / pts * 100);
    }
    return map.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );
  }

  List<_MissedQuestion> get _missedQuestions {
    final misses = <String, _MissedQuestion>{};
    for (final r in _quizResults) {
      final quizId = (r['quizId'] ?? '').toString();
      final quiz = _quizById[quizId];
      if (quiz == null) continue;
      final questions = (quiz['questions'] as List? ?? const [])
          .whereType<Map>()
          .map((q) => Map<String, dynamic>.from(q))
          .toList();
      final answers =
          (r['answers'] is Map) ? r['answers'] as Map : <dynamic, dynamic>{};
      for (final q in questions) {
        final qId = (q['id'] ?? '').toString();
        if (qId.isEmpty) continue;
        final key = '$quizId::$qId';
        misses.putIfAbsent(
          key,
          () => _MissedQuestion(
            questionId: qId,
            questionText: (q['question'] ?? '').toString(),
            quizTitle: (quiz['title'] ?? 'Quiz').toString(),
            subject: (quiz['subject'] ?? '').toString(),
          ),
        );
        final correct = q['correctAnswer'];
        final studentAnswer = answers[qId];
        misses[key]!.totalAttempts++;
        if (!_isAnswerCorrect(studentAnswer, correct)) {
          misses[key]!.missCount++;
        }
      }
    }
    final list = misses.values.where((m) => m.totalAttempts > 0).toList()
      ..sort((a, b) => b.missRate.compareTo(a.missRate));
    return list.take(15).toList();
  }

  bool _isAnswerCorrect(dynamic userAnswer, dynamic correctAnswer) {
    if (correctAnswer == null || userAnswer == null) return false;
    if (correctAnswer is List) {
      if (userAnswer is List) {
        final c =
            correctAnswer.map((e) => e.toString().trim().toLowerCase()).toSet();
        final u =
            userAnswer.map((e) => e.toString().trim().toLowerCase()).toSet();
        return c.difference(u).isEmpty && u.difference(c).isEmpty;
      }
      return false;
    }
    return userAnswer.toString().trim().toLowerCase() ==
        correctAnswer.toString().trim().toLowerCase();
  }

  Map<String, int> get _lessonViews {
    final views = <String, int>{};
    for (final p in _lessonProgress) {
      final lessonId = (p['lessonId'] ?? '').toString();
      if (lessonId.isNotEmpty) {
        views[lessonId] = (views[lessonId] ?? 0) + 1;
      }
    }
    return views;
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.screenTitle),
        backgroundColor: _accentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            initialValue: _selectedTimeRange,
            tooltip: 'Time range',
            icon: const Icon(Icons.date_range_outlined),
            onSelected: (value) => setState(() => _selectedTimeRange = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: '7days', child: Text('Last 7 Days')),
              PopupMenuItem(value: '30days', child: Text('Last 30 Days')),
              PopupMenuItem(value: '90days', child: Text('Last 90 Days')),
              PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withValues(alpha: 0.6),
          indicatorColor: AppColors.textWhite,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Performance'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Item Analysis'),
            Tab(icon: Icon(Icons.people_outlined), text: 'Engagement'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildPerformanceTab(),
                    _buildItemAnalysisTab(),
                    _buildEngagementTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: AppConstants.paddingL),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Overview ------------------------------------------------------

  Widget _buildOverviewTab() {
    final stats = _quizStats;
    final overall = _overallAverage;
    final passingRate = _quizResults.isEmpty
        ? 0
        : (_passingCount / _quizResults.length * 100).round();
    final students = _uniqueStudents.length;

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        children: [
          Row(
            children: [
              Expanded(
                child: _AnalyticsCard(
                  title: _lessonsCardTitle,
                  value: _myLessons.length.toString(),
                  icon: Icons.book_outlined,
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: _AnalyticsCard(
                  title: _quizzesCardTitle,
                  value: _myQuizzes.length.toString(),
                  icon: Icons.quiz_outlined,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          Row(
            children: [
              Expanded(
                child: _AnalyticsCard(
                  title: 'Students',
                  value: students.toString(),
                  icon: Icons.people_outlined,
                  color: AppColors.studentPrimary,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: _AnalyticsCard(
                  title: _averageCardTitle,
                  value: '${overall.toStringAsFixed(1)}%',
                  icon: Icons.grade_outlined,
                  color: _scoreColor(overall),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          Row(
            children: [
              Expanded(
                child: _AnalyticsCard(
                  title: 'Pass Rate',
                  value: '$passingRate%',
                  icon: Icons.check_circle_outline,
                  color:
                      passingRate >= 70 ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: _AnalyticsCard(
                  title: 'Attempts',
                  value: _quizResults.length.toString(),
                  icon: Icons.assignment_outlined,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          if (_quizResults.isNotEmpty) ...[
            const SizedBox(height: AppConstants.paddingXL),
            const _SectionHeader('Pass / Fail Distribution'),
            const SizedBox(height: AppConstants.paddingM),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Row(
                  children: [
                    SizedBox(
                      height: 180,
                      width: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 32,
                          sections: [
                            PieChartSectionData(
                              value: _passingCount.toDouble(),
                              color: AppColors.success,
                              title:
                                  '${(_passingCount / _quizResults.length * 100).toStringAsFixed(0)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: AppConstants.fontM,
                              ),
                            ),
                            PieChartSectionData(
                              value: (_quizResults.length - _passingCount)
                                  .toDouble(),
                              color: AppColors.error,
                              title:
                                  '${((_quizResults.length - _passingCount) / _quizResults.length * 100).toStringAsFixed(0)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: AppConstants.fontM,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingL),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LegendDot(
                          color: AppColors.success,
                          label: 'Passed ($_passingCount)',
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        _LegendDot(
                          color: AppColors.error,
                          label:
                              'Failed ${_quizResults.length - _passingCount}',
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          '$passingRate% pass rate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: passingRate >= 70
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: AppConstants.paddingXL),
            const _SectionHeader('Average Scores per Quiz'),
            const SizedBox(height: AppConstants.paddingM),
            _buildQuizAvgBarChart(stats),
          ],
          if (_subjectAverages.isNotEmpty) ...[
            const SizedBox(height: AppConstants.paddingXL),
            const _SectionHeader('Performance by Subject'),
            const SizedBox(height: AppConstants.paddingM),
            ..._subjectAverages.entries
                .map((e) => _buildProgressRow(label: e.key, value: e.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizAvgBarChart(Map<String, _QuizStat> stats) {
    final sorted = stats.values.toList()
      ..sort((a, b) => b.avgScore.compareTo(a.avgScore));
    final top = sorted.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final quiz = top[group.x.toInt()];
                        return BarTooltipItem(
                          '${quiz.title}\n${quiz.avgScore.toStringAsFixed(1)}%',
                          const TextStyle(
                              color: Colors.white,
                              fontSize: AppConstants.fontS),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= top.length) {
                            return const SizedBox.shrink();
                          }
                          final title = top[index].title;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              title.length > 8
                                  ? '${title.substring(0, 8)}\u2026'
                                  : title,
                              style: const TextStyle(
                                  fontSize: AppConstants.fontXS),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: AppConstants.fontXS),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  barGroups: top.asMap().entries.map((entry) {
                    final avg = entry.value.avgScore;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: avg,
                          color: _scoreColor(avg),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            const Text(
              'Top 6 quizzes by average score',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppConstants.fontS,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow({required String label, required double value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _scoreColor(value),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(value)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Student Performance ------------------------------------------

  Widget _buildPerformanceTab() {
    if (_quizResults.isEmpty) {
      return const _EmptyState(
        icon: Icons.bar_chart,
        message: 'No quiz submissions yet.',
      );
    }

    final stats = _quizStats;
    final quarterAvgs = _quarterAverages;
    final subjectAvgs = _subjectAverages;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      children: [
        const _SectionHeader('Performance Trends per Quarter'),
        const SizedBox(height: AppConstants.paddingM),
        if (quarterAvgs.length >= 2)
          _buildQuarterLineChart(quarterAvgs)
        else ...[
          ...quarterAvgs.entries.map(
            (e) => _buildProgressRow(label: e.key, value: e.value),
          ),
        ],
        const SizedBox(height: AppConstants.paddingXL),
        const _SectionHeader('Subject Strengths & Weaknesses'),
        const SizedBox(height: AppConstants.paddingM),
        if (subjectAvgs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingL),
              child: Text('No subject data yet.'),
            ),
          )
        else
          _buildSubjectBarChart(subjectAvgs),
        const SizedBox(height: AppConstants.paddingXL),
        const _SectionHeader('Per-Quiz Performance'),
        const SizedBox(height: AppConstants.paddingM),
        ...stats.values.map((stat) => _buildQuizPerformanceCard(stat)),
      ],
    );
  }

  Widget _buildQuarterLineChart(Map<String, double> quarterAvgs) {
    final sorted = quarterAvgs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: AppConstants.fontXS),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sorted[index].key.replaceAll('Quarter ', 'Q'),
                              style: const TextStyle(
                                  fontSize: AppConstants.fontXS),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 100,
                  clipData: FlClipData.all(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sorted.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.value);
                      }).toList(),
                      isCurved: true,
                      color: _accentColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _accentColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            const Text(
              'Class average score over time by quarter',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppConstants.fontS,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectBarChart(Map<String, double> subjectAvgs) {
    final sorted = subjectAvgs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final entry = sorted[group.x.toInt()];
                        return BarTooltipItem(
                          '${entry.key}\n${entry.value.toStringAsFixed(1)}%',
                          const TextStyle(
                              color: Colors.white,
                              fontSize: AppConstants.fontS),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          final label = sorted[index].key;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label.length > 8
                                  ? '${label.substring(0, 8)}\u2026'
                                  : label,
                              style: const TextStyle(
                                  fontSize: AppConstants.fontXS),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: AppConstants.fontXS),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: sorted.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: _scoreColor(entry.value.value),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            const Text(
              'Average score per subject',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppConstants.fontS,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizPerformanceCard(_QuizStat stat) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppConstants.fontM,
                        ),
                      ),
                      if (stat.subject.isNotEmpty)
                        Text(
                          '${stat.subject}${stat.quarter.isNotEmpty ? ' \u2022 ${stat.quarter}' : ''}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppConstants.fontS,
                          ),
                        ),
                    ],
                  ),
                ),
                _ScoreBadge(score: stat.avgScore),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Attempts',
                    value: '${stat.attempts}',
                    icon: Icons.people_outlined,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Highest',
                    value: '${stat.maxScore.toStringAsFixed(0)}%',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Lowest',
                    value: '${stat.minScore.toStringAsFixed(0)}%',
                    icon: Icons.trending_down,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            if (stat.attempts > 0) ...[
              const SizedBox(height: AppConstants.paddingM),
              _buildProgressRow(label: 'Average', value: stat.avgScore),
            ],
          ],
        ),
      ),
    );
  }

  // --- Tab 3: Item Analysis -------------------------------------------------

  Widget _buildItemAnalysisTab() {
    if (_myQuizzes.isEmpty) {
      return const _EmptyState(
        icon: Icons.analytics_outlined,
        message: 'No quizzes available for analysis.',
      );
    }

    final stats = _quizStats;
    final missed = _missedQuestions;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      children: [
        const _SectionHeader('Quiz Completion & Avg Time'),
        const SizedBox(height: AppConstants.paddingM),
        if (stats.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingL),
              child: Text('No submissions yet.'),
            ),
          )
        else
          ...stats.values.map(_buildCompletionCard),
        const SizedBox(height: AppConstants.paddingXL),
        if (stats.length >= 2) ...[
          const _SectionHeader('Completion Rate by Quiz'),
          const SizedBox(height: AppConstants.paddingM),
          _buildCompletionBarChart(stats),
          const SizedBox(height: AppConstants.paddingXL),
        ],
        const _SectionHeader('Most Missed Questions'),
        const SizedBox(height: AppConstants.paddingM),
        if (missed.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingL),
              child: Text(
                'No item data yet. Questions are analysed once students submit quizzes.',
              ),
            ),
          )
        else ...[
          _buildMissedBarChart(missed),
          const SizedBox(height: AppConstants.paddingM),
          ...missed.asMap().entries.map((entry) {
            final q = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      _difficultyColor(q.missRate).withValues(alpha: 0.15),
                  child: Text(
                    '${entry.key + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _difficultyColor(q.missRate),
                    ),
                  ),
                ),
                title: Text(
                  q.questionText.length > 70
                      ? '${q.questionText.substring(0, 70)}\u2026'
                      : q.questionText,
                  style: const TextStyle(fontSize: AppConstants.fontM),
                ),
                subtitle: Text(
                  '${q.quizTitle}${q.subject.isNotEmpty ? ' \u2022 ${q.subject}' : ''}',
                  style: const TextStyle(fontSize: AppConstants.fontS),
                ),
                trailing: _DifficultyBadge(missRate: q.missRate),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildCompletionCard(_QuizStat stat) {
    final avgMinutes = stat.avgTimeSec / 60;
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppConstants.fontM,
              ),
            ),
            if (stat.subject.isNotEmpty)
              Text(
                stat.subject,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppConstants.fontS,
                ),
              ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Attempts',
                    value: '${stat.attempts}',
                    icon: Icons.people_outlined,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Avg Time',
                    value: avgMinutes < 1
                        ? '${stat.avgTimeSec.toStringAsFixed(0)}s'
                        : '${avgMinutes.toStringAsFixed(1)}m',
                    icon: Icons.timer_outlined,
                    color: AppColors.info,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Avg Score',
                    value: '${stat.avgScore.toStringAsFixed(1)}%',
                    icon: Icons.grade_outlined,
                    color: _scoreColor(stat.avgScore),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBarChart(Map<String, _QuizStat> stats) {
    final totalStudents = _uniqueStudents.length;
    if (totalStudents == 0) {
      return const SizedBox.shrink();
    }
    final entries = stats.values.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final stat = entries[group.x.toInt()];
                    final rate = stat.studentIds.length / totalStudents * 100;
                    return BarTooltipItem(
                      '${stat.title}\n${rate.toStringAsFixed(0)}% participated',
                      const TextStyle(
                          color: Colors.white, fontSize: AppConstants.fontS),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      final title = entries[index].title;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          title.length > 8
                              ? '${title.substring(0, 8)}\u2026'
                              : title,
                          style: const TextStyle(fontSize: AppConstants.fontXS),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: AppConstants.fontXS),
                    ),
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: entries.asMap().entries.map((entry) {
                final rate =
                    entry.value.studentIds.length / totalStudents * 100;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: rate,
                      color: rate >= 70 ? AppColors.success : AppColors.warning,
                      width: 22,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissedBarChart(List<_MissedQuestion> missed) {
    final top = missed.take(8).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final q = top[group.x.toInt()];
                    return BarTooltipItem(
                      '${q.questionText.length > 30 ? '${q.questionText.substring(0, 30)}\u2026' : q.questionText}\nMiss rate: ${q.missRate.toStringAsFixed(1)}%',
                      const TextStyle(
                          color: Colors.white, fontSize: AppConstants.fontS),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Q${value.toInt() + 1}',
                        style: const TextStyle(fontSize: AppConstants.fontXS),
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: AppConstants.fontXS),
                    ),
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: top.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.missRate,
                      color: _difficultyColor(entry.value.missRate),
                      width: 22,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // --- Tab 4: Student Engagement --------------------------------------------

  Widget _buildEngagementTab() {
    final views = _lessonViews;
    final stats = _quizStats;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      children: [
        Row(
          children: [
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Views',
                value: _lessonProgress.length.toString(),
                icon: Icons.visibility_outlined,
                color: _accentColor,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: _AnalyticsCard(
                title: 'Active Students',
                value: _uniqueStudents.length.toString(),
                icon: Icons.people_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        if (_myLessons.isNotEmpty) ...[
          const SizedBox(height: AppConstants.paddingXL),
          const _SectionHeader('Lesson Views per Lesson'),
          const SizedBox(height: AppConstants.paddingM),
          _buildLessonViewsChart(views),
        ],
        if (stats.isNotEmpty) ...[
          const SizedBox(height: AppConstants.paddingXL),
          const _SectionHeader('Quiz Participation Rate'),
          const SizedBox(height: AppConstants.paddingM),
          ...stats.values.map(_buildParticipationRow),
        ],
        const SizedBox(height: AppConstants.paddingXL),
        const _SectionHeader('At-Risk Students'),
        const SizedBox(height: AppConstants.paddingS),
        Text(
          _atRiskDescription,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppConstants.fontS,
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        _buildAtRiskSection(),
      ],
    );
  }

  Widget _buildLessonViewsChart(Map<String, int> views) {
    final sorted = _myLessons
        .map((l) => MapEntry(
              (l['title'] ?? 'Lesson').toString(),
              views[(l['id'] ?? '').toString()] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();

    if (top.every((e) => e.value == 0)) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingL),
          child: Text('No lesson views recorded yet.'),
        ),
      );
    }

    final maxVal = top.first.value.toDouble() * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal < 1 ? 1 : maxVal,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = top[group.x.toInt()];
                    return BarTooltipItem(
                      '${entry.key}\n${entry.value} views',
                      const TextStyle(
                          color: Colors.white, fontSize: AppConstants.fontS),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= top.length) {
                        return const SizedBox.shrink();
                      }
                      final title = top[index].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          title.length > 8
                              ? '${title.substring(0, 8)}\u2026'
                              : title,
                          style: const TextStyle(fontSize: AppConstants.fontXS),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: AppConstants.fontXS),
                    ),
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: top.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: _accentColor,
                      width: 22,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipationRow(_QuizStat stat) {
    final totalStudents = _uniqueStudents.length;
    final participated = stat.studentIds.length;
    final rate = totalStudents == 0 ? 0.0 : participated / totalStudents * 100;
    final color = rate >= 70 ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stat.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$participated / $totalStudents',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
            child: LinearProgressIndicator(
              value: totalStudents == 0 ? 0 : rate / 100,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskSection() {
    final studentScores = <String, List<double>>{};
    final studentNames = <String, String>{};
    for (final r in _quizResults) {
      final studentId = (r['studentId'] ?? '').toString();
      if (studentId.isEmpty) continue;
      studentNames[studentId] = (r['studentName'] ?? 'Student').toString();
      final score = (r['score'] as num?)?.toDouble() ?? 0;
      final pts = (r['totalPoints'] as num?)?.toDouble() ?? 0;
      if (pts > 0) {
        studentScores.putIfAbsent(studentId, () => []).add(score / pts * 100);
      }
    }

    final atRisk = studentScores.entries.where((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return avg < 60;
    }).toList()
      ..sort((a, b) {
        final avgA = a.value.reduce((x, y) => x + y) / a.value.length;
        final avgB = b.value.reduce((x, y) => x + y) / b.value.length;
        return avgA.compareTo(avgB);
      });

    if (atRisk.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: AppConstants.paddingM),
              Text('No at-risk students right now. Great work!'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: atRisk.take(10).map((entry) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final name = studentNames[entry.key] ?? 'Student';
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.error.withValues(alpha: 0.12),
              child: const Icon(Icons.warning_amber_outlined,
                  color: AppColors.error),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${entry.value.length} quiz attempt${entry.value.length == 1 ? '' : 's'}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Text(
                '${avg.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Helpers --------------------------------------------------------------

  Color _scoreColor(double score) {
    if (score >= 75) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Color _difficultyColor(double missRate) {
    if (missRate >= 70) return AppColors.error;
    if (missRate >= 40) return AppColors.warning;
    return AppColors.info;
  }
}

// --- Data Models -------------------------------------------------------------

class _QuizStat {
  final String quizId;
  final String title;
  final String subject;
  final String quarter;
  final List<double> scores = [];
  final List<double> times = [];
  final Set<String> studentIds = {};
  int attempts = 0;

  _QuizStat({
    required this.quizId,
    required this.title,
    required this.subject,
    required this.quarter,
  });

  void addResult(double pct, double time, {String? studentId}) {
    scores.add(pct);
    times.add(time);
    attempts++;
    if (studentId != null && studentId.isNotEmpty) {
      studentIds.add(studentId);
    }
  }

  double get avgScore =>
      scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
  double get maxScore =>
      scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b);
  double get minScore =>
      scores.isEmpty ? 0 : scores.reduce((a, b) => a < b ? a : b);
  double get avgTimeSec =>
      times.isEmpty ? 0 : times.reduce((a, b) => a + b) / times.length;
}

class _MissedQuestion {
  final String questionId;
  final String questionText;
  final String quizTitle;
  final String subject;
  int missCount = 0;
  int totalAttempts = 0;

  _MissedQuestion({
    required this.questionId,
    required this.questionText,
    required this.quizTitle,
    required this.subject,
  });

  double get missRate =>
      totalAttempts == 0 ? 0 : missCount / totalAttempts * 100;
}

// --- UI Components ------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppConstants.fontXL,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              value,
              style: TextStyle(
                fontSize: AppConstants.fontXXL,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppConstants.fontS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textSecondary;
    return Column(
      children: [
        Icon(icon, size: 18, color: effectiveColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: effectiveColor,
            fontSize: AppConstants.fontM,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppConstants.fontXS,
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (score >= 75) {
      color = AppColors.success;
    } else if (score >= 60) {
      color = AppColors.warning;
    } else {
      color = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
      ),
      child: Text(
        '${score.toStringAsFixed(1)}%',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final double missRate;
  const _DifficultyBadge({required this.missRate});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (missRate >= 70) {
      label = 'Hard';
      color = AppColors.error;
    } else if (missRate >= 40) {
      label = 'Med';
      color = AppColors.warning;
    } else {
      label = 'Easy';
      color = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
      ),
      child: Text(
        '$label\n${missRate.toStringAsFixed(0)}%',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: AppConstants.fontXS,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppConstants.paddingS),
        Text(label),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppConstants.fontL,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
