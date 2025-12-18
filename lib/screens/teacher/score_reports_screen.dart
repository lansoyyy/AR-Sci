import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../utils/score_report_pdf.dart';

class TeacherScoreReportsScreen extends StatefulWidget {
  const TeacherScoreReportsScreen({super.key});

  @override
  State<TeacherScoreReportsScreen> createState() =>
      _TeacherScoreReportsScreenState();
}

class _TeacherScoreReportsScreenState extends State<TeacherScoreReportsScreen> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedStudentEmail;
  bool _isGenerating = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _studentsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _resultsStream(String studentId) {
    return FirebaseFirestore.instance
        .collection('quiz_results')
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  Future<void> _openPdfPreview() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;

    setState(() => _isGenerating = true);

    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get();

      final studentData = studentDoc.data() ?? {};
      final studentName = (studentData['name'] as String?) ??
          (_selectedStudentName ?? 'Student');
      final studentEmail =
          (studentData['email'] as String?) ?? (_selectedStudentEmail ?? '');

      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_results')
          .where('studentId', isEqualTo: studentId)
          .get();

      final entries = resultsSnapshot.docs
          .map((d) => StudentScoreEntry.fromFirestore(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

      final Uint8List bytes = await buildStudentScoreReportPdf(
        studentName: studentName,
        studentEmail: studentEmail,
        entries: entries,
        generatedAt: DateTime.now(),
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _TeacherScoreReportPdfPreviewScreen(
            pdfBytes: bytes,
            fileName: _buildFileName(studentName),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate PDF report.')),
      );
    }
  }

  String _buildFileName(String studentName) {
    final safe = studentName
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    return 'score_report_${safe.isEmpty ? 'student' : safe}.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Reports'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.softGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Student',
                          style: TextStyle(
                            fontSize: AppConstants.fontL,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _studentsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }

                            final docs = snapshot.data?.docs ?? [];

                            if (docs.isEmpty) {
                              return const Text(
                                'No students found.',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              );
                            }

                            final items = docs.map((doc) {
                              final data = doc.data();
                              final name =
                                  (data['name'] as String?) ?? 'Student';
                              final email = (data['email'] as String?) ?? '';
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                    email.isEmpty ? name : '$name ($email)'),
                              );
                            }).toList();

                            return DropdownButtonFormField<String>(
                              value: _selectedStudentId,
                              items: items,
                              decoration: const InputDecoration(
                                labelText: 'Student',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              onChanged: (value) {
                                if (value == null) return;
                                final selectedDoc =
                                    docs.firstWhere((d) => d.id == value);
                                final data = selectedDoc.data();
                                setState(() {
                                  _selectedStudentId = value;
                                  _selectedStudentName =
                                      (data['name'] as String?) ?? 'Student';
                                  _selectedStudentEmail =
                                      (data['email'] as String?) ?? '';
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                Expanded(
                  child: _selectedStudentId == null
                      ? const Center(
                          child: Text(
                            'Select a student to view their results.',
                            style: TextStyle(
                              fontSize: AppConstants.fontL,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _resultsStream(_selectedStudentId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final docs = snapshot.data?.docs ?? [];
                            final entries = docs
                                .map((d) => StudentScoreEntry.fromFirestore(
                                    d.id, d.data()))
                                .toList()
                              ..sort((a, b) =>
                                  b.completedAt.compareTo(a.completedAt));

                            if (entries.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No quiz results for this student yet.',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontL,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                final e = entries[index];
                                final pct = e.percentage;
                                final color = pct >= 80
                                    ? AppColors.success
                                    : pct >= 60
                                        ? AppColors.warning
                                        : AppColors.error;

                                return Card(
                                  margin: const EdgeInsets.only(
                                      bottom: AppConstants.paddingS),
                                  child: ListTile(
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                            AppConstants.radiusM),
                                      ),
                                      child: Icon(
                                        Icons.quiz_outlined,
                                        color: color,
                                      ),
                                    ),
                                    title: Text(
                                      e.quizTitle.isEmpty
                                          ? e.quizId
                                          : e.quizTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Score: ${e.score}/${e.totalPoints} (${pct.toStringAsFixed(0)}%)',
                                    ),
                                    trailing: Text(
                                      _formatDate(e.completedAt),
                                      style: const TextStyle(
                                        fontSize: AppConstants.fontS,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                CustomButton(
                  text: 'Preview & Share PDF',
                  onPressed: (_selectedStudentId == null || _isGenerating)
                      ? null
                      : _openPdfPreview,
                  isLoading: _isGenerating,
                  fullWidth: true,
                  backgroundColor: AppColors.teacherPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _TeacherScoreReportPdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const _TeacherScoreReportPdfPreviewScreen({
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        backgroundColor: AppColors.teacherPrimary,
        actions: [
          IconButton(
            onPressed: () {
              Printing.sharePdf(bytes: pdfBytes, filename: fileName);
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
