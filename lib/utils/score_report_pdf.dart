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
          pw.Text(
            'Student Score Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Generated: ${_formatDateTime(generatedAt)}'),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  studentName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (studentEmail.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(studentEmail),
                ],
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    _metricChip('Attempts', entries.length.toString()),
                    pw.SizedBox(width: 8),
                    _metricChip('Average', '${avg.toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          if (entries.isEmpty)
            pw.Text('No quiz results available.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('Quiz'),
                    _cellHeader('Score'),
                    _cellHeader('Completed'),
                  ],
                ),
                ...entries.map((e) {
                  final title = e.quizTitle.isEmpty ? e.quizId : e.quizTitle;
                  return pw.TableRow(
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
        ];
      },
    ),
  );

  return doc.save();
}

pw.Widget _metricChip(String label, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(999),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _cellHeader(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
      ),
    ),
  );
}

pw.Widget _cellBody(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 10),
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
