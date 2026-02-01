import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/ai_assessment_service.dart';
import '../../widgets/custom_button.dart';

class AdminCreateQuizScreen extends StatefulWidget {
  const AdminCreateQuizScreen({super.key});

  @override
  State<AdminCreateQuizScreen> createState() => _AdminCreateQuizScreenState();
}

class _AdminCreateQuizScreenState extends State<AdminCreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '30');

  String _selectedSubject = AppConstants.subjects.first;
  String _selectedGradeLevel = AppConstants.gradeLevels.first;
  String _selectedLessonId = '';
  bool _isPublished = true;
  bool _isSaving = false;

  bool _isGenerating = false;
  String? _generationError;
  List<Map<String, dynamic>> _generatedQuestions = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _cachedLessons = <Map<String, dynamic>>[];

  String _fallbackLessonMaterial(Map<String, dynamic> lesson) {
    final description = (lesson['description'] ?? '').toString().trim();
    final arItems = (lesson['arItems'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    final buffer = StringBuffer();
    if (description.isNotEmpty) {
      buffer.writeln(description);
    }
    if (arItems.isNotEmpty) {
      buffer.writeln('\nAR Items:');
      for (final item in arItems) {
        buffer.writeln('- $item');
      }
    }
    return buffer.toString().trim();
  }

  List<Map<String, dynamic>> _normalizeQuestions(
    List<Map<String, dynamic>> input,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;

    return input.asMap().entries.map((entry) {
      final index = entry.key;
      final q = entry.value;

      final questionText = (q['question'] ?? '').toString().trim();
      final rawType = (q['type'] ?? 'multipleChoice').toString().trim();

      var type = rawType;
      if (type != 'multipleChoice' && type != 'trueFalse' && type != 'fillInBlank') {
        type = 'multipleChoice';
      }

      var options = (q['options'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          <String>[];

      var correctAnswer = (q['correctAnswer'] ?? '').toString().trim();

      final points = q['points'] is int
          ? q['points'] as int
          : int.tryParse((q['points'] ?? '').toString()) ?? 1;

      if (type == 'trueFalse') {
        options = <String>['True', 'False'];
        correctAnswer = correctAnswer == 'False' ? 'False' : 'True';
      } else if (type == 'fillInBlank') {
        options = <String>[];
      } else {
        if (options.length < 4) {
          final padded = <String>[...options];
          while (padded.length < 4) {
            padded.add('Option ${padded.length + 1}');
          }
          options = padded;
        }
        if (options.length > 4) {
          options = options.take(4).toList();
        }
        if (correctAnswer.isEmpty || !options.contains(correctAnswer)) {
          correctAnswer = options.isNotEmpty ? options.first : '';
        }
      }

      return <String, dynamic>{
        'id': 'q_${now}_$index',
        'question': questionText.isEmpty ? 'Question ${index + 1}' : questionText,
        'type': type,
        'options': options,
        'correctAnswer': correctAnswer,
        'points': points,
      };
    }).toList();
  }

  Future<void> _generateWithAi() async {
    if (_isGenerating) return;

    final lesson = _cachedLessons.firstWhere(
      (l) => (l['id'] ?? '').toString() == _selectedLessonId,
      orElse: () => <String, dynamic>{},
    );

    final lessonTitle = (lesson['title'] ?? '').toString().trim();
    final lessonContent = (lesson['content'] ?? '').toString().trim();
    final lessonMaterial =
        lessonContent.isNotEmpty ? lessonContent : _fallbackLessonMaterial(lesson);

    if (lessonTitle.isEmpty || lessonMaterial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No lesson material found for AI generation.'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final generated = await AiAssessmentService.generateQuestions(
        lessonTitle: lessonTitle,
        lessonMaterial: lessonMaterial,
        gradeLevel: _selectedGradeLevel,
        subject: _selectedSubject,
        questionCount: 10,
      );

      final normalized = _normalizeQuestions(generated);

      if (!mounted) return;
      setState(() {
        _generatedQuestions = normalized;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${normalized.length} questions.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generationError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI generation failed. $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isGenerating = false);
    }
  }

  List<Map<String, dynamic>> _mergeLessons(
    List<Map<String, dynamic>> firebaseLessons,
  ) {
    final seenIds = <String>{};
    return <Map<String, dynamic>>[
      ...firebaseLessons.where((l) {
        final id = (l['id'] ?? '').toString();
        return id.isNotEmpty && seenIds.add(id);
      }),
      ...AppConstants.allLessons.where((l) {
        final id = (l['id'] ?? '').toString();
        return id.isNotEmpty && seenIds.add(id);
      }),
    ];
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPublished && _generatedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate questions before publishing.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      final duration = int.tryParse(_durationController.text.trim()) ?? 30;

      final docRef = FirebaseFirestore.instance.collection('quizzes').doc();
      final quizId = docRef.id;

      final payload = <String, dynamic>{
        'id': quizId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'lessonId': _selectedLessonId,
        'subject': _selectedSubject,
        'gradeLevel': _selectedGradeLevel,
        'questions': _generatedQuestions,
        'duration': duration,
        'createdAt': DateTime.now().toIso8601String(),
        'isPublished': _isPublished,
        if (currentUser != null) 'createdBy': currentUser.uid,
      };

      await docRef.set(payload);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment created successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      debugPrint('Failed to create quiz: $e');

      final message = e is FirebaseException
          ? '${e.code}: ${e.message ?? 'Unknown Firebase error'}'
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create quiz. $message')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assessment'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Assessment Title',
                  prefixIcon: Icon(Icons.quiz_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an assessment title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingL),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.subject_outlined),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingL),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('lessons')
                    .snapshots(),
                builder: (context, snapshot) {
                  final firebaseLessons = (snapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                      .map((d) => <String, dynamic>{
                            ...d.data(),
                            'id': d.data()['id'] ?? d.id,
                          })
                      .toList();

                  final lessons = _mergeLessons(firebaseLessons);
                  _cachedLessons = lessons;

                  if (_selectedLessonId.isEmpty && lessons.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final first = lessons.first;
                      setState(() {
                        _selectedLessonId = (first['id'] ?? '').toString();
                        _selectedSubject =
                            (first['subject'] ?? _selectedSubject).toString();
                        _selectedGradeLevel = (first['gradeLevel'] ??
                                first['grade'] ??
                                _selectedGradeLevel)
                            .toString();
                      });
                    });
                  }

                  final selectedLessonExists = lessons.any(
                      (l) => (l['id'] ?? '').toString() == _selectedLessonId);
                  final safeSelectedLessonId = selectedLessonExists
                      ? _selectedLessonId
                      : (lessons.isNotEmpty
                          ? (lessons.first['id'] ?? '').toString()
                          : null);

                  return DropdownButtonFormField<String>(
                    value: safeSelectedLessonId,
                    decoration: const InputDecoration(
                      labelText: 'Lesson',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    items: lessons
                        .map((l) => DropdownMenuItem<String>(
                              value: (l['id'] ?? '').toString(),
                              child: Text((l['title'] ?? '').toString()),
                            ))
                        .toList(),
                    onChanged: lessons.isEmpty
                        ? null
                        : (value) {
                            if (value == null) return;
                            final picked = lessons.firstWhere(
                              (l) => (l['id'] ?? '').toString() == value,
                              orElse: () => lessons.first,
                            );
                            setState(() {
                              _selectedLessonId = value;
                              _selectedSubject =
                                  (picked['subject'] ?? _selectedSubject)
                                      .toString();
                              _selectedGradeLevel = (picked['gradeLevel'] ??
                                      picked['grade'] ??
                                      _selectedGradeLevel)
                                  .toString();
                            });
                          },
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Please select a lesson';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: AppConstants.paddingL),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedSubject = value);
                },
              ),
              const SizedBox(height: AppConstants.paddingL),
              DropdownButtonFormField<String>(
                value: _selectedGradeLevel,
                decoration: const InputDecoration(
                  labelText: 'Grade Level',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: AppConstants.gradeLevels
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedGradeLevel = value);
                },
              ),
              const SizedBox(height: AppConstants.paddingL),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingL),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomButton(
                        text: 'Generate Questions with AI',
                        onPressed: _isGenerating ? null : _generateWithAi,
                        isLoading: _isGenerating,
                        fullWidth: true,
                        backgroundColor: AppColors.adminPrimary,
                        icon: Icons.auto_awesome_outlined,
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Text(
                        _generatedQuestions.isEmpty
                            ? 'No questions generated yet.'
                            : '${_generatedQuestions.length} questions generated.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (_generationError != null) ...[
                        const SizedBox(height: AppConstants.paddingS),
                        Text(
                          _generationError!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
              Card(
                child: SwitchListTile(
                  value: _isPublished,
                  onChanged: (value) => setState(() => _isPublished = value),
                  activeColor: AppColors.adminPrimary,
                  title: const Text('Published'),
                  subtitle: const Text('If off, this will be saved as draft'),
                ),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              CustomButton(
                text: 'Save Assessment',
                onPressed: _isSaving ? null : _saveQuiz,
                isLoading: _isSaving,
                fullWidth: true,
                backgroundColor: AppColors.adminPrimary,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
