import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String lessonId;
  final String subject;
  final String gradeLevel;
  final List<QuizQuestion> questions;
  final int duration; // in minutes
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool isPublished;
  final List<String> assignedSections;
  final List<String> assignedGradeLevels;
  final bool showQuestionsAfterSubmission;
  final bool showCorrectAnswersAfterSubmission;
  final bool showIncorrectAnswersAfterSubmission;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonId,
    required this.subject,
    required this.gradeLevel,
    required this.questions,
    required this.duration,
    required this.createdAt,
    this.scheduledDate,
    this.availableFrom,
    this.availableTo,
    this.isPublished = false,
    this.assignedSections = const [],
    this.assignedGradeLevels = const [],
    this.showQuestionsAfterSubmission = true,
    this.showCorrectAnswersAfterSubmission = true,
    this.showIncorrectAnswersAfterSubmission = true,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    DateTime? _parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return QuizModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      lessonId: json['lessonId'] ?? '',
      subject: json['subject'] ?? '',
      gradeLevel: json['gradeLevel'] ?? '',
      questions: (json['questions'] as List?)
              ?.map((q) => QuizQuestion.fromJson(q))
              .toList() ??
          [],
      duration: json['duration'] ?? 30,
      createdAt: _parseDate(json['createdAt']),
      scheduledDate: _parseOptionalDate(json['scheduledDate']),
      availableFrom: _parseOptionalDate(json['availableFrom']),
      availableTo: _parseOptionalDate(json['availableTo']),
      isPublished: json['isPublished'] ?? false,
      assignedSections: List<String>.from(json['assignedSections'] ?? const []),
      assignedGradeLevels:
          List<String>.from(json['assignedGradeLevels'] ?? const []),
      showQuestionsAfterSubmission:
          json['showQuestionsAfterSubmission'] != false,
      showCorrectAnswersAfterSubmission:
          json['showCorrectAnswersAfterSubmission'] != false,
      showIncorrectAnswersAfterSubmission:
          json['showIncorrectAnswersAfterSubmission'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lessonId': lessonId,
      'subject': subject,
      'gradeLevel': gradeLevel,
      'questions': questions.map((q) => q.toJson()).toList(),
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'availableFrom': availableFrom?.toIso8601String(),
      'availableTo': availableTo?.toIso8601String(),
      'isPublished': isPublished,
      'assignedSections': assignedSections,
      'assignedGradeLevels': assignedGradeLevels,
      'showQuestionsAfterSubmission': showQuestionsAfterSubmission,
      'showCorrectAnswersAfterSubmission': showCorrectAnswersAfterSubmission,
      'showIncorrectAnswersAfterSubmission':
          showIncorrectAnswersAfterSubmission,
    };
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final dynamic
      correctAnswer; // String for single answer, List<String> for multiple
  final int points;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.points = 1,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == 'QuestionType.${json['type']}',
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'],
      points: json['points'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type.toString().split('.').last,
      'options': options,
      'correctAnswer': correctAnswer,
      'points': points,
    };
  }
}

enum QuestionType {
  multipleChoice,
  multipleResponse,
  trueFalse,
  matching,
  fillInBlank,
}

class QuizResult {
  final String id;
  final String quizId;
  final String studentId;
  final int score;
  final int totalPoints;
  final Map<String, dynamic> answers;
  final DateTime completedAt;
  final int timeTaken; // in seconds

  QuizResult({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.score,
    required this.totalPoints,
    required this.answers,
    required this.completedAt,
    required this.timeTaken,
  });

  double get percentage => (score / totalPoints) * 100;

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'] ?? '',
      quizId: json['quizId'] ?? '',
      studentId: json['studentId'] ?? '',
      score: json['score'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      answers: Map<String, dynamic>.from(json['answers'] ?? {}),
      completedAt: DateTime.parse(
          json['completedAt'] ?? DateTime.now().toIso8601String()),
      timeTaken: json['timeTaken'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'score': score,
      'totalPoints': totalPoints,
      'answers': answers,
      'completedAt': completedAt.toIso8601String(),
      'timeTaken': timeTaken,
    };
  }
}
