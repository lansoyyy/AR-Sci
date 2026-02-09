import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  bool _isGenerating = false;
  String _selectedReportType = 'my_lessons';
  final List<Map<String, String>> _reportTypes = [
    {'id': 'my_lessons', 'name': 'My Lessons Summary', 'icon': 'book'},
    {'id': 'my_quizzes', 'name': 'My Quizzes Report', 'icon': 'quiz'},
    {'id': 'student_progress', 'name': 'Student Progress Report', 'icon': 'people'},
    {'id': 'class_overview', 'name': 'Class Overview', 'icon': 'dashboard'},
  ];

  Future<void> _generateAndPrintPDF() async {
    setState(() => _isGenerating = true);
    
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('MMMM dd, yyyy');
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      
      switch (_selectedReportType) {
        case 'my_lessons':
          await _generateMyLessonsReport(pdf, now, dateFormat, teacherId);
          break;
        case 'my_quizzes':
          await _generateMyQuizzesReport(pdf, now, dateFormat, teacherId);
          break;
        case 'student_progress':
          await _generateStudentProgressReport(pdf, now, dateFormat, teacherId);
          break;
        case 'class_overview':
          await _generateClassOverviewReport(pdf, now, dateFormat, teacherId);
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

  Future<void> _generateMyLessonsReport(pw.Document pdf, DateTime now, DateFormat dateFormat, String? teacherId) async {
    final lessonsSnapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .where('createdBy', isEqualTo: teacherId)
        .get();
    final lessons = lessonsSnapshot.docs;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildReportHeader('My Lessons Summary', now, dateFormat),
        footer: (context) => _buildReportFooter(),
        build: (context) => [
          pw.Text('Lessons Created by You', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Total Lessons: ${lessons.length}'),
          pw.SizedBox(height: 20),
          pw.Text('Lesson Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...lessons.map((lesson) {
            final data = lesson.data();
            final isPublished = data['isPublished'] == true;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                color: isPublished ? null : PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(data['title'] as String? ?? 'Untitled',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Subject: ${data['subject'] ?? 'N/A'}'),
                  pw.Text('Grade Level: ${data['gradeLevel'] ?? 'N/A'}'),
                  pw.Text('Quarter: ${data['quarter'] ?? 'N/A'}'),
                  pw.Text('Status: ${isPublished ? 'Published' : 'Draft'}'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _generateMyQuizzesReport(pw.Document pdf, DateTime now, DateFormat dateFormat, String? teacherId) async {
    final quizzesSnapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('createdBy', isEqualTo: teacherId)
        .get();
    final quizzes = quizzesSnapshot.docs;
    
    // Get results for these quizzes
    final quizIds = quizzes.map((q) => q.id).toList();
    Map<String, List<Map<String, dynamic>>> quizResults = {};
    
    if (quizIds.isNotEmpty) {
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_results')
          .where('quizId', whereIn: quizIds.take(10).toList())
          .get();
      
      for (final result in resultsSnapshot.docs) {
        final data = result.data();
        final quizId = data['quizId'] as String?;
        if (quizId != null) {
          quizResults.putIfAbsent(quizId, () => []).add(data);
        }
      }
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildReportHeader('My Quizzes Report', now, dateFormat),
        footer: (context) => _buildReportFooter(),
        build: (context) => [
          pw.Text('Quizzes Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Total Quizzes: ${quizzes.length}'),
          pw.SizedBox(height: 20),
          pw.Text('Quiz Performance', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...quizzes.map((quiz) {
            final data = quiz.data();
            final quizId = quiz.id;
            final results = quizResults[quizId] ?? [];
            final avgScore = results.isEmpty ? 0 : results.map((r) {
              final score = (r['score'] as num?)?.toDouble() ?? 0;
              final total = (r['totalPoints'] as num?)?.toDouble() ?? 1;
              return (score / total) * 100;
            }).reduce((a, b) => a + b) / results.length;
            
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(data['title'] as String? ?? 'Untitled',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Attempts: ${results.length}'),
                  pw.Text('Average Score: ${avgScore.toStringAsFixed(1)}%'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _generateStudentProgressReport(pw.Document pdf, DateTime now, DateFormat dateFormat, String? teacherId) async {
    // Get teacher's sections
    final teacherDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(teacherId)
        .get();
    final teacherData = teacherDoc.data();
    final sections = (teacherData?['sectionsHandled'] as List<dynamic>?)?.cast<String>() ?? [];
    
    // Get students in those sections
    Query<Map<String, dynamic>> studentsQuery = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('verified', isEqualTo: true);
    
    final studentsSnapshot = await studentsQuery.get();
    final students = studentsSnapshot.docs.where((s) {
      final grade = s.data()['gradeLevel'] as String?;
      final section = s.data()['section'] as String?;
      if (sections.isEmpty) return true;
      return sections.contains(grade) || sections.contains(section);
    }).toList();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildReportHeader('Student Progress Report', now, dateFormat),
        footer: (context) => _buildReportFooter(),
        build: (context) => [
          pw.Text('Students in Your Classes', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Total Students: ${students.length}'),
          pw.SizedBox(height: 20),
          _buildStatsTable([
            ['Student Name', 'Grade/Section', 'Status'],
            ...students.map((s) {
              final data = s.data();
              return [
                data['name'] as String? ?? 'Unknown',
                '${data['gradeLevel'] ?? 'N/A'} / ${data['section'] ?? 'N/A'}',
                'Active',
              ];
            }),
          ]),
        ],
      ),
    );
  }

  Future<void> _generateClassOverviewReport(pw.Document pdf, DateTime now, DateFormat dateFormat, String? teacherId) async {
    final lessonsSnapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .where('createdBy', isEqualTo: teacherId)
        .get();
    final quizzesSnapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('createdBy', isEqualTo: teacherId)
        .get();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildReportHeader('Class Overview', now, dateFormat),
        footer: (context) => _buildReportFooter(),
        build: (context) => [
          pw.Text('Teaching Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Generated on: ${dateFormat.format(now)}'),
          pw.SizedBox(height: 30),
          _buildStatsTable([
            ['Component', 'Count'],
            ['Lessons Created', lessonsSnapshot.docs.length.toString()],
            ['Quizzes Created', quizzesSnapshot.docs.length.toString()],
          ]),
          pw.SizedBox(height: 30),
          pw.Text('About This Report', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('This overview summarizes your teaching activities in the AR Fusion platform.'),
        ],
      ),
    );
  }

  pw.Widget _buildReportHeader(String title, DateTime now, DateFormat dateFormat) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Text('AR Fusion - Teacher Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
        title: const Text('Reports & Downloads'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      label: Text(_isGenerating ? 'Generating...' : 'Print / Save as PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teacherPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingL),
            
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
      case 'my_lessons':
        return 'This report includes:\n• All lessons created by you\n• Subject and grade level details\n• Publication status\n• Lesson metadata';
      case 'my_quizzes':
        return 'This report includes:\n• All quizzes created by you\n• Student attempt counts\n• Average scores per quiz\n• Performance summary';
      case 'student_progress':
        return 'This report includes:\n• Students in your sections\n• Grade and section breakdown\n• Enrollment status';
      case 'class_overview':
        return 'This report includes:\n• Summary of your teaching activities\n• Lesson and quiz counts\n• High-level statistics';
      default:
        return 'Select a report type to see details.';
    }
  }
}
