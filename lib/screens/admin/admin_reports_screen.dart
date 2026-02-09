import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isGenerating = false;
  String _selectedReportType = 'user_summary';
  final List<Map<String, String>> _reportTypes = [
    {'id': 'user_summary', 'name': 'User Summary Report', 'icon': 'people'},
    {'id': 'lesson_summary', 'name': 'Lesson Summary Report', 'icon': 'book'},
    {'id': 'quiz_report', 'name': 'Quiz Performance Report', 'icon': 'quiz'},
    {
      'id': 'system_overview',
      'name': 'System Overview Report',
      'icon': 'dashboard'
    },
  ];

  Future<void> _generateAndPrintPDF() async {
    setState(() => _isGenerating = true);

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('MMMM dd, yyyy');

      switch (_selectedReportType) {
        case 'user_summary':
          await _generateUserSummaryReport(pdf, now, dateFormat);
          break;
        case 'lesson_summary':
          await _generateLessonSummaryReport(pdf, now, dateFormat);
          break;
        case 'quiz_report':
          await _generateQuizReport(pdf, now, dateFormat);
          break;
        case 'system_overview':
          await _generateSystemOverviewReport(pdf, now, dateFormat);
          break;
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateUserSummaryReport(
      pw.Document pdf, DateTime now, DateFormat dateFormat) async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final users = usersSnapshot.docs;

    int students = 0, teachers = 0, admins = 0;
    int verified = 0, pending = 0;

    for (final user in users) {
      final data = user.data();
      final role = data['role'] as String? ?? '';
      final isVerified = data['verified'] as bool? ?? false;

      if (isVerified) {
        verified++;
      } else {
        pending++;
      }

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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildReportHeader('User Summary Report', now, dateFormat),
        footer: (context) => _buildReportFooter(),
        build: (context) => [
          pw.Text('User Statistics Overview',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          _buildStatsTable([
            ['Metric', 'Count'],
            ['Total Users', users.length.toString()],
            ['Verified Users', verified.toString()],
            ['Pending Verification', pending.toString()],
          ]),
          pw.SizedBox(height: 30),
          pw.Text('User Distribution by Role',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          _buildStatsTable([
            ['Role', 'Count', 'Percentage'],
            [
              'Students',
              students.toString(),
              '${users.isEmpty ? 0 : (students / users.length * 100).toStringAsFixed(1)}%'
            ],
            [
              'Teachers',
              teachers.toString(),
              '${users.isEmpty ? 0 : (teachers / users.length * 100).toStringAsFixed(1)}%'
            ],
            [
              'Administrators',
              admins.toString(),
              '${users.isEmpty ? 0 : (admins / users.length * 100).toStringAsFixed(1)}%'
            ],
          ]),
          pw.SizedBox(height: 30),
          pw.Text('Recent Registrations',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text(
              'This report was generated automatically by the AR Fusion system.'),
        ],
      ),
    );
  }

  Future<void> _generateLessonSummaryReport(
      pw.Document pdf, DateTime now, DateFormat dateFormat) async {
    final lessonsSnapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .where('isPublished', isEqualTo: true)
        .get();
    final lessons = lessonsSnapshot.docs;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildReportHeader('Lesson Summary Report', now, dateFormat),
        footer: (context) => _buildReportFooter(),
        build: (context) => [
          pw.Text('Published Lessons Overview',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Total Published Lessons: ${lessons.length}'),
          pw.SizedBox(height: 20),
          pw.Text('Lesson Details',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...lessons.map((lesson) {
            final data = lesson.data();
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(data['title'] as String? ?? 'Untitled',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Subject: ${data['subject'] ?? 'N/A'}'),
                  pw.Text('Grade Level: ${data['gradeLevel'] ?? 'N/A'}'),
                  pw.Text('Quarter: ${data['quarter'] ?? 'N/A'}'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _generateQuizReport(
      pw.Document pdf, DateTime now, DateFormat dateFormat) async {
    final resultsSnapshot = await FirebaseFirestore.instance
        .collection('quiz_results')
        .orderBy('completedAt', descending: true)
        .limit(100)
        .get();
    final results = resultsSnapshot.docs;

    double totalScore = 0;
    Map<String, List<double>> quizScores = {};

    for (final result in results) {
      final data = result.data();
      final score = (data['score'] as num?)?.toDouble() ?? 0;
      final total = (data['totalQuestions'] as num?)?.toDouble() ?? 1;
      final percentage = (score / total) * 100;
      final quizId = data['quizId'] as String? ?? 'unknown';
      final quizTitle = data['quizTitle'] as String? ?? 'Unknown Quiz';
      final key = '$quizId|$quizTitle';

      totalScore += percentage;
      quizScores.putIfAbsent(key, () => []).add(percentage);
    }

    final averageScore = results.isEmpty ? 0 : totalScore / results.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildReportHeader('Quiz Performance Report', now, dateFormat),
        footer: (context) => _buildReportFooter(),
        build: (context) => [
          pw.Text('Quiz Statistics',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Total Quiz Attempts: ${results.length}'),
          pw.Text('Average Score: ${averageScore.toStringAsFixed(1)}%'),
          pw.SizedBox(height: 20),
          pw.Text('Performance by Quiz',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...quizScores.entries.map((entry) {
            final parts = entry.key.split('|');
            final title = parts.length > 1 ? parts[1] : entry.key;
            final scores = entry.value;
            final avg = scores.reduce((a, b) => a + b) / scores.length;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 5),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text(title)),
                  pw.Text('${scores.length} attempts'),
                  pw.SizedBox(width: 20),
                  pw.Text('Avg: ${avg.toStringAsFixed(1)}%'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _generateSystemOverviewReport(
      pw.Document pdf, DateTime now, DateFormat dateFormat) async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final lessonsSnapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .where('isPublished', isEqualTo: true)
        .get();
    final quizzesSnapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('isPublished', isEqualTo: true)
        .get();
    final quizResultsSnapshot =
        await FirebaseFirestore.instance.collection('quiz_results').get();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildReportHeader('System Overview Report', now, dateFormat),
        footer: (context) => _buildReportFooter(),
        build: (context) => [
          pw.Text('AR Fusion System Summary',
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Generated on: ${dateFormat.format(now)}'),
          pw.SizedBox(height: 30),
          pw.Text('System Statistics',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          _buildStatsTable([
            ['Component', 'Count'],
            ['Total Users', usersSnapshot.docs.length.toString()],
            ['Published Lessons', lessonsSnapshot.docs.length.toString()],
            ['Published Quizzes', quizzesSnapshot.docs.length.toString()],
            ['Quiz Attempts', quizResultsSnapshot.docs.length.toString()],
          ]),
          pw.SizedBox(height: 30),
          pw.Text('About This Report',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'This system overview provides a high-level summary of the AR Fusion educational platform.'),
          pw.Text(
              'The platform serves students, teachers, and administrators with AR-based science learning.'),
          pw.SizedBox(height: 20),
          pw.Text(
              'For detailed analytics, please refer to the Analytics Dashboard.'),
        ],
      ),
    );
  }

  pw.Widget _buildReportHeader(
      String title, DateTime now, DateFormat dateFormat) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Text('AR Fusion',
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text(title, style: pw.TextStyle(fontSize: 18)),
          pw.Text('Generated: ${dateFormat.format(now)}'),
          pw.Divider(),
        ],
      ),
    );
  }

  pw.Widget _buildReportFooter() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text('AR Fusion - Step into the future of science learning',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
    );
  }

  pw.Widget _buildStatsTable(List<List<String>> data) {
    return pw.Table.fromTextArray(
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & PDF Export'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Report Type',
                      style: TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    ..._reportTypes.map((type) {
                      return RadioListTile<String>(
                        title: Text(type['name']!),
                        value: type['id']!,
                        groupValue: _selectedReportType,
                        onChanged: (value) {
                          setState(() => _selectedReportType = value!);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingL),

            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateAndPrintPDF,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print),
                      label: Text(_isGenerating
                          ? 'Generating...'
                          : 'Print / Save as PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin-analytics');
                      },
                      icon: const Icon(Icons.analytics),
                      label: const Text('View Detailed Analytics'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingL),

            // Report Preview Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Preview',
                      style: TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text(
                      _getReportDescription(),
                      style: const TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getReportDescription() {
    switch (_selectedReportType) {
      case 'user_summary':
        return 'This report includes:\n• Total user count\n• User distribution by role (Students, Teachers, Admins)\n• Verification status breakdown\n• Recent registration trends';
      case 'lesson_summary':
        return 'This report includes:\n• All published lessons\n• Subject and grade level distribution\n• Quarter breakdown\n• Lesson details and metadata';
      case 'quiz_report':
        return 'This report includes:\n• Quiz attempt statistics\n• Average scores by quiz\n• Performance trends\n• Top performing quizzes';
      case 'system_overview':
        return 'This report includes:\n• Complete system summary\n• User, lesson, and quiz counts\n• Platform overview\n• High-level statistics';
      default:
        return 'Select a report type to see details.';
    }
  }
}
