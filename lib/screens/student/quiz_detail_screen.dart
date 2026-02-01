import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../models/quiz_model.dart';

class QuizDetailScreen extends StatefulWidget {
  const QuizDetailScreen({super.key});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final Map<String, dynamic> _quiz = {};
  final Map<String, dynamic> _userAnswers = {};
  bool _isTakingQuiz = false;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  int _currentQuestionIndex = 0;
  int _remainingTime = 0;
  Timer? _timer;
  int _score = 0;
  int _totalPoints = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startQuiz() {
    final duration = _quiz['duration'] is int
        ? _quiz['duration'] as int
        : int.tryParse((_quiz['duration'] ?? '').toString()) ?? 30;
    setState(() {
      _isTakingQuiz = true;
      _remainingTime = duration * 60; // Convert to seconds
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _submitQuiz();
      }
    });
  }

  void _selectAnswer(String questionId, dynamic answer) {
    setState(() {
      _userAnswers[questionId] = answer;
    });
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    if (_hasSubmitted) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to submit.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final rawQuestions = _quiz['questions'] as List? ?? [];
      int score = 0;
      int totalPoints = 0;

      for (var q in rawQuestions) {
        if (q is! Map) continue;
        final question = Map<String, dynamic>.from(q);
        final questionId = question['id']?.toString() ?? '';
        final correctAnswer = question['correctAnswer'];
        final points = question['points'] is int
            ? question['points'] as int
            : int.tryParse(question['points']?.toString() ?? '1') ?? 1;
        final userAnswer = _userAnswers[questionId];

        totalPoints += points;

        if (_isAnswerCorrect(userAnswer, correctAnswer)) {
          score += points;
        }
      }

      final result = QuizResult(
        id: '${user.uid}_${_quiz['id']}_${DateTime.now().millisecondsSinceEpoch}',
        quizId: _quiz['id']?.toString() ?? '',
        studentId: user.uid,
        score: score,
        totalPoints: totalPoints,
        answers: Map.from(_userAnswers),
        completedAt: DateTime.now(),
        timeTaken: (_quiz['duration'] is int
                ? _quiz['duration'] as int
                : int.tryParse((_quiz['duration'] ?? '').toString()) ?? 30) *
            60 -
            _remainingTime,
      );

      await FirebaseFirestore.instance
          .collection('quiz_results')
          .doc(result.id)
          .set({
            ...result.toJson(),
            'completedAt': FieldValue.serverTimestamp(), // Use server timestamp
          });

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _hasSubmitted = true;
        _score = score;
        _totalPoints = totalPoints;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit quiz: $e')),
      );
    }
  }

  bool _isAnswerCorrect(dynamic userAnswer, dynamic correctAnswer) {
    if (userAnswer == null) return false;
    if (correctAnswer == null) return false;

    // Handle different answer types
    if (correctAnswer is List) {
      if (userAnswer is List) {
        // Compare lists (order doesn't matter for multiple select)
        final correctSet = correctAnswer.toSet();
        final userSet = userAnswer.toSet();
        return correctSet.difference(userSet).isEmpty &&
            userSet.difference(correctSet).isEmpty;
      }
      return false;
    }

    // String comparison (case-insensitive)
    return userAnswer.toString().toLowerCase() ==
        correctAnswer.toString().toLowerCase();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final quiz = args is Map<String, dynamic> ? args : <String, dynamic>{};
    _quiz.addAll(quiz);

    final title = (_quiz['title'] ?? 'Quiz').toString();
    final description = (_quiz['description'] ?? '').toString();
    final subject = (_quiz['subject'] ?? '').toString();
    final grade = (_quiz['gradeLevel'] ?? _quiz['grade'] ?? '').toString();

    final rawQuestions = _quiz['questions'] as List? ?? const [];
    final questionsCount = rawQuestions.length;

    final duration = _quiz['duration'] is int
        ? _quiz['duration'] as int
        : int.tryParse((_quiz['duration'] ?? '').toString()) ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.studentPrimary,
        actions: _isTakingQuiz
            ? [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _remainingTime < 60
                        ? AppColors.error
                        : AppColors.textWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_remainingTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : null,
      ),
      body: _hasSubmitted
          ? _buildResultScreen()
          : _isTakingQuiz
              ? _buildQuizTakingScreen(rawQuestions)
              : _buildQuizInfoScreen(
                  title,
                  description,
                  subject,
                  grade,
                  questionsCount,
                  duration,
                ),
    );
  }

  Widget _buildQuizInfoScreen(
    String title,
    String description,
    String subject,
    String grade,
    int questionsCount,
    int duration,
  ) {
    final rawQuestions = _quiz['questions'] as List? ?? const [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (subject.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingM,
                    vertical: AppConstants.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.studentPrimary,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusRound),
                  ),
                  child: Text(
                    subject,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppConstants.fontS,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (grade.isNotEmpty) ...[
                const SizedBox(width: AppConstants.paddingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingM,
                    vertical: AppConstants.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusRound),
                  ),
                  child: Text(
                    grade,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppConstants.fontS,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppConstants.paddingL),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppConstants.fontXXL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppConstants.paddingM),
            Text(
              description,
              style: const TextStyle(
                fontSize: AppConstants.fontL,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.paddingXL),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuizMeta(
                    label: 'Questions',
                    value: questionsCount.toString(),
                  ),
                  _QuizMeta(
                    label: 'Duration',
                    value: '$duration min',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
          const Text(
            'Questions',
            style: TextStyle(
              fontSize: AppConstants.fontXL,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          if (rawQuestions.isEmpty)
            const Text(
              'No questions added yet.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...List.generate(rawQuestions.length, (index) {
              final q = rawQuestions[index];
              final map = q is Map
                  ? Map<String, dynamic>.from(q)
                  : <String, dynamic>{};
              final questionText = (map['question'] ?? 'Question').toString();
              return Card(
                margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Text(
                    '${index + 1}. $questionText',
                    style: const TextStyle(
                      fontSize: AppConstants.fontL,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: AppConstants.paddingXL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: rawQuestions.isEmpty ? null : _startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.studentPrimary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: const Text(
                'Start Quiz',
                style: TextStyle(
                  fontSize: AppConstants.fontL,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTakingScreen(List rawQuestions) {
    if (rawQuestions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    final currentQuestion = rawQuestions[_currentQuestionIndex];
    final questionMap = currentQuestion is Map
        ? Map<String, dynamic>.from(currentQuestion)
        : <String, dynamic>{};
    final questionId = questionMap['id']?.toString() ?? '';
    final questionText = questionMap['question']?.toString() ?? '';
    final type = questionMap['type']?.toString() ?? 'multipleChoice';
    final options = questionMap['options'] as List? ?? [];

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / rawQuestions.length,
          backgroundColor: AppColors.divider,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.studentPrimary),
        ),
        // Question counter
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Text(
            'Question ${_currentQuestionIndex + 1} of ${rawQuestions.length}',
            style: const TextStyle(
              fontSize: AppConstants.fontM,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionText,
                  style: const TextStyle(
                    fontSize: AppConstants.fontXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXL),
                _buildQuestionOptions(questionId, type, options),
              ],
            ),
          ),
        ),
        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _currentQuestionIndex--);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.studentPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuestionIndex > 0)
                const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentQuestionIndex < rawQuestions.length - 1) {
                      setState(() => _currentQuestionIndex++);
                    } else {
                      _submitQuiz();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.studentPrimary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: Text(
                    _currentQuestionIndex < rawQuestions.length - 1
                        ? 'Next'
                        : 'Submit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionOptions(String questionId, String type, List options) {
    final userAnswer = _userAnswers[questionId];

    switch (type) {
      case 'trueFalse':
        return Column(
          children: [
            _buildOptionTile(
              questionId,
              'True',
              userAnswer == 'True',
              () => _selectAnswer(questionId, 'True'),
            ),
            const SizedBox(height: AppConstants.paddingM),
            _buildOptionTile(
              questionId,
              'False',
              userAnswer == 'False',
              () => _selectAnswer(questionId, 'False'),
            ),
          ],
        );

      case 'fillInBlank':
        final controller = TextEditingController(text: userAnswer?.toString() ?? '');
        return TextField(
          controller: controller,
          onChanged: (value) => _selectAnswer(questionId, value.trim()),
          decoration: const InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(AppConstants.paddingM),
          ),
          style: const TextStyle(fontSize: AppConstants.fontL),
        );

      case 'multipleChoice':
      default:
        return Column(
          children: options.map((option) {
            final optionText = option.toString();
            final isSelected = userAnswer == optionText;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
              child: _buildOptionTile(
                questionId,
                optionText,
                isSelected,
                () => _selectAnswer(questionId, optionText),
              ),
            );
          }).toList(),
        );
    }
  }

  Widget _buildOptionTile(
    String questionId,
    String option,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.studentPrimary.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? AppColors.studentPrimary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.studentPrimary : AppColors.textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.studentPrimary : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: AppConstants.fontL,
                  color: isSelected
                      ? AppColors.studentPrimary
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = _totalPoints > 0 ? (_score / _totalPoints * 100) : 0;
    final passed = percentage >= 60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: passed ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      passed ? Icons.check_circle : Icons.cancel,
                      size: 60,
                      color: passed ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: AppConstants.fontXXL,
                        fontWeight: FontWeight.bold,
                        color: passed ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),
            Text(
              passed ? 'Congratulations!' : 'Keep Practicing!',
              style: const TextStyle(
                fontSize: AppConstants.fontXXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'You scored $_score out of $_totalPoints points',
              style: const TextStyle(
                fontSize: AppConstants.fontL,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.studentPrimary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: const Text(
                  'Back to Quizzes',
                  style: TextStyle(
                    fontSize: AppConstants.fontL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizMeta extends StatelessWidget {
  final String label;
  final String value;

  const _QuizMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppConstants.fontS,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppConstants.fontL,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
