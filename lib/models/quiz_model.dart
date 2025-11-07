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
  final bool isPublished;

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
    this.isPublished = false,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      lessonId: json['lessonId'] ?? '',
      subject: json['subject'] ?? '',
      gradeLevel: json['gradeLevel'] ?? '',
      questions: (json['questions'] as List?)?.map((q) => QuizQuestion.fromJson(q)).toList() ?? [],
      duration: json['duration'] ?? 30,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
      isPublished: json['isPublished'] ?? false,
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
      'isPublished': isPublished,
    };
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final dynamic correctAnswer; // String for single answer, List<String> for multiple
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
      completedAt: DateTime.parse(json['completedAt'] ?? DateTime.now().toIso8601String()),
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
