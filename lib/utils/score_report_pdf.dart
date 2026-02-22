import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StudentScoreEntry {
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalPoints;
  final DateTime completedAt;

  StudentScoreEntry({
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalPoints,
    required this.completedAt,
  });

  double get percentage {
    if (totalPoints == 0) return 0;
    return (score / totalPoints) * 100;
  }

  static StudentScoreEntry fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final quizId = (data['quizId'] as String?) ?? id;
    final quizTitle = (data['quizTitle'] as String?) ?? '';
    final score = (data['score'] as num?)?.toInt() ?? 0;
    final totalPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;

    final completedAtValue = data['completedAt'];
    DateTime completedAt;
    if (completedAtValue is Timestamp) {
      completedAt = completedAtValue.toDate();
    } else if (completedAtValue is String) {
      completedAt = DateTime.tryParse(completedAtValue) ?? DateTime.now();
    } else {
      completedAt = DateTime.now();
    }

    return StudentScoreEntry(
      quizId: quizId,
      quizTitle: quizTitle,
      score: score,
      totalPoints: totalPoints,
      completedAt: completedAt,
    );
  }
}

Future<Uint8List> buildStudentScoreReportPdf({
  required String studentName,
  required String studentEmail,
  required List<StudentScoreEntry> entries,
  required DateTime generatedAt,
}) async {
  final doc = pw.Document();

  final avg = entries.isEmpty
      ? 0.0
      : entries.map((e) => e.percentage).reduce((a, b) => a + b) /
          entries.length;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return [
          // Header Section
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Student Score Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated: ${_formatDateTime(generatedAt)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          
          // Student Information Section
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Student Information',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                studentName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              if (studentEmail.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  studentEmail,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              pw.SizedBox(height: 16),
              
              // Metrics Section
              pw.Row(
                children: [
                  _metricLabel('Total Attempts'),
                  pw.SizedBox(width: 12),
                  _metricValue(entries.length.toString()),
                  pw.SizedBox(width: 24),
                  _metricLabel('Average Score'),
                  pw.SizedBox(width: 12),
                  _metricValue('${avg.toStringAsFixed(1)}%'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          if (entries.isEmpty)
            pw.Text(
              'No quiz results available.',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey700,
              ),
            )
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Quiz Results',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 1,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      children: [
                        _cellHeader('Quiz'),
                        _cellHeader('Score'),
                        _cellHeader('Completed'),
                      ],
                    ),
                    ...entries.map((e) {
                      final title = e.quizTitle.isEmpty ? e.quizId : e.quizTitle;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: entries.indexOf(e) % 2 == 0
                              ? PdfColors.white
                              : PdfColors.grey50,
                        ),
                        children: [
                          _cellBody(title),
                          _cellBody(
                              '${e.score}/${e.totalPoints} (${e.percentage.toStringAsFixed(0)}%)'),
                          _cellBody(_formatDate(e.completedAt)),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
        ];
      },
    ),
  );

  return doc.save();
}

pw.Widget _metricLabel(String label) {
  return pw.Text(
    '$label: ',
    style: pw.TextStyle(
      fontSize: 12,
      color: PdfColors.grey700,
    ),
  );
}

pw.Widget _metricValue(String value) {
  return pw.Text(
    value,
    style: pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    ),
  );
}

pw.Widget _cellHeader(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
        color: PdfColors.black,
      ),
    ),
  );
}

pw.Widget _cellBody(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.black,
      ),
    ),
  );
}

String _formatDate(DateTime dt) {
  return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime dt) {
  final date = _formatDate(dt);
  return '$date ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
