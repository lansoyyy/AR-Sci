import 'dart:convert';

import 'package:http/http.dart' as http;

class AiAssessmentService {
  static const String _endpoint =
      'https://api.together.xyz/v1/chat/completions';

  static const String _model = 'meta-llama/Llama-3.3-70B-Instruct-Turbo';

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

    return parsed
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
}
