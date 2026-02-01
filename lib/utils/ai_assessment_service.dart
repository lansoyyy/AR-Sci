import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiAssessmentService {
  static const String _endpoint =
      'https://api.together.xyz/v1/chat/completions';

  static const String _model = 'meta-llama/Llama-3.3-70B-Instruct-Turbo';

  // Rate limiting: maximum AI requests per user per day
  static const int _maxDailyRequests = 20;

  /// Check if user is authorized to use AI generation (teachers and admins only)
  static Future<bool> _isAuthorizedUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final role = userDoc.data()?['role'] as String?;
      return role == 'teacher' || role == 'admin';
    } catch (e) {
      debugPrint('Error checking user authorization: $e');
      return false;
    }
  }

  /// Check if user has exceeded daily AI request limit
  static Future<bool> _hasExceededDailyLimit(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ai_usage_logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('timestamp', isLessThan: endOfDay.toIso8601String())
          .count()
          .get();

      return (snapshot.count ?? 0) >= _maxDailyRequests;
    } catch (e) {
      debugPrint('Error checking daily limit: $e');
      return false;
    }
  }

  /// Log AI generation usage for rate limiting and audit purposes
  static Future<void> _logUsage({
    required String userId,
    required String lessonTitle,
    required String gradeLevel,
    required String subject,
    required int questionCount,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('ai_usage_logs').add({
        'userId': userId,
        'lessonTitle': lessonTitle,
        'gradeLevel': gradeLevel,
        'subject': subject,
        'questionCount': questionCount,
        'success': success,
        'errorMessage': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging AI usage: $e');
    }
  }

  static String _extractJson(String input) {
    final firstBrace = input.indexOf('[');
    if (firstBrace == -1) {
      throw const FormatException('No JSON array found in AI response.');
    }

    final lastBrace = input.lastIndexOf(']');
    if (lastBrace == -1 || lastBrace <= firstBrace) {
      throw const FormatException('Invalid JSON array in AI response.');
    }

    return input.substring(firstBrace, lastBrace + 1);
  }

  static Future<List<Map<String, dynamic>>> generateQuestions({
    required String lessonTitle,
    required String lessonMaterial,
    required String gradeLevel,
    required String subject,
    int questionCount = 10,
  }) async {
    // Check authorization - only teachers and admins can use AI generation
    final isAuthorized = await _isAuthorizedUser();
    if (!isAuthorized) {
      throw Exception(
          'Unauthorized: Only teachers and admins can generate AI questions.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated.');
    }

    // Check rate limiting
    final hasExceededLimit = await _hasExceededDailyLimit(user.uid);
    if (hasExceededLimit) {
      throw Exception(
          'Daily AI generation limit exceeded ($_maxDailyRequests requests per day). Please try again tomorrow.');
    }

    final apiKey = const String.fromEnvironment(
      'TOGETHER_API_KEY',
      defaultValue: '',
    );

    if (apiKey.trim().isEmpty) {
      throw const FormatException(
          'Missing TOGETHER_API_KEY. Provide it using --dart-define=TOGETHER_API_KEY=YOUR_KEY');
    }

    final systemPrompt =
        'You are an expert teacher creating a short assessment based on the lesson material. '
        'Return ONLY a valid JSON array of questions. Do not wrap in markdown.\n\n'
        'Each item in the array MUST follow this schema:\n'
        '{\n'
        '  "question": string,\n'
        '  "type": "multipleChoice" | "trueFalse" | "fillInBlank",\n'
        '  "options": string[],\n'
        '  "correctAnswer": string,\n'
        '  "points": number\n'
        '}\n\n'
        'Rules:\n'
        '- For multipleChoice: provide exactly 4 options. correctAnswer must be exactly one of the options.\n'
        '- For trueFalse: options must be ["True","False"]. correctAnswer must be either "True" or "False".\n'
        '- For fillInBlank: options must be empty []. correctAnswer is the exact word/phrase.\n'
        '- Points should be 1.\n'
        '- Keep language appropriate for the grade level.\n';

    final userPrompt = 'Create $questionCount questions for: $lessonTitle\n'
        'Grade Level: $gradeLevel\n'
        'Subject: $subject\n\n'
        'Lesson Material:\n$lessonMaterial';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
      }),
    );

    List<Map<String, dynamic>>? result;
    String? errorMessage;

    try {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'AI request failed (${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final content = ((decoded['choices'] as List?)?.isNotEmpty == true)
          ? (decoded['choices'][0]['message']?['content'] as String? ?? '')
          : '';

      final jsonStr = _extractJson(content);
      final parsed = jsonDecode(jsonStr);

      if (parsed is! List) {
        throw const FormatException('AI response is not a JSON array.');
      }

      result = parsed
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      // Log successful usage
      await _logUsage(
        userId: user.uid,
        lessonTitle: lessonTitle,
        gradeLevel: gradeLevel,
        subject: subject,
        questionCount: questionCount,
        success: true,
      );

      return result;
    } catch (e) {
      errorMessage = e.toString();

      // Log failed usage
      await _logUsage(
        userId: user.uid,
        lessonTitle: lessonTitle,
        gradeLevel: gradeLevel,
        subject: subject,
        questionCount: questionCount,
        success: false,
        errorMessage: errorMessage,
      );

      rethrow;
    }
  }
}
