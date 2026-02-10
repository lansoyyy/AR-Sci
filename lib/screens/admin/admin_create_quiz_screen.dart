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

  // Assignment and Scheduling
  final List<String> _selectedAssignedSections = <String>[];
  DateTime? _availableFrom;
  DateTime? _availableTo;

  bool _isGenerating = false;
  String? _generationError;
  List<Map<String, dynamic>> _generatedQuestions = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _cachedLessons = <Map<String, dynamic>>[];

  // Manual question editing
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();
  String _selectedQuestionType = 'multipleChoice';
  int? _editingQuestionIndex;

  void _addManualQuestion() {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    String correctAnswer = '';
    List<String> options = [];

    if (_selectedQuestionType == 'multipleChoice') {
      options = [
        _optionAController.text.trim(),
        _optionBController.text.trim(),
        _optionCController.text.trim(),
        _optionDController.text.trim(),
      ].where((o) => o.isNotEmpty).toList();

      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least 2 options')),
        );
        return;
      }
      correctAnswer = _correctAnswerController.text.trim();
      if (correctAnswer.isEmpty || !options.contains(correctAnswer)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please enter a valid correct answer from the options')),
        );
        return;
      }
    } else if (_selectedQuestionType == 'trueFalse') {
      options = ['True', 'False'];
      correctAnswer =
          _correctAnswerController.text.trim() == 'False' ? 'False' : 'True';
    } else if (_selectedQuestionType == 'fillInBlank') {
      correctAnswer = _correctAnswerController.text.trim();
      if (correctAnswer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the correct answer')),
        );
        return;
      }
    }

    final newQuestion = {
      'id':
          'q_${DateTime.now().millisecondsSinceEpoch}_${_generatedQuestions.length}',
      'question': questionText,
      'type': _selectedQuestionType,
      'options': options,
      'correctAnswer': correctAnswer,
      'points': 1,
    };

    setState(() {
      if (_editingQuestionIndex != null) {
        _generatedQuestions[_editingQuestionIndex!] = newQuestion;
        _editingQuestionIndex = null;
      } else {
        _generatedQuestions.add(newQuestion);
      }
    });

    _clearQuestionForm();
  }

  void _clearQuestionForm() {
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _correctAnswerController.clear();
    _editingQuestionIndex = null;
  }

  void _editQuestion(int index) {
    final q = _generatedQuestions[index];
    setState(() {
      _editingQuestionIndex = index;
      _selectedQuestionType = q['type'] ?? 'multipleChoice';
      _questionController.text = q['question'] ?? '';
      _correctAnswerController.text = q['correctAnswer'] ?? '';

      final options = (q['options'] as List?)?.cast<String>() ?? [];
      if (options.length > 0) _optionAController.text = options[0];
      if (options.length > 1) _optionBController.text = options[1];
      if (options.length > 2) _optionCController.text = options[2];
      if (options.length > 3) _optionDController.text = options[3];
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _generatedQuestions.removeAt(index);
      if (_editingQuestionIndex == index) {
        _clearQuestionForm();
      }
    });
  }

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
      if (type != 'multipleChoice' &&
          type != 'trueFalse' &&
          type != 'fillInBlank') {
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
        'question':
            questionText.isEmpty ? 'Question ${index + 1}' : questionText,
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
    final lessonMaterial = lessonContent.isNotEmpty
        ? lessonContent
        : _fallbackLessonMaterial(lesson);

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
    return firebaseLessons.where((l) {
      final id = (l['id'] ?? '').toString();
      return id.isNotEmpty && seenIds.add(id);
    }).toList();
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
        'createdAt': FieldValue.serverTimestamp(),
        'isPublished': _isPublished,
        if (currentUser != null) 'createdBy': currentUser.uid,
        // Assignment and Scheduling
        if (_selectedAssignedSections.isNotEmpty)
          'assignedSections': _selectedAssignedSections,
        if (_availableFrom != null)
          'availableFrom': _availableFrom!.toIso8601String(),
        if (_availableTo != null)
          'availableTo': _availableTo!.toIso8601String(),
      };

      await docRef.set(payload);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz created successfully.')),
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
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _correctAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
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
                  labelText: 'Quiz Title',
                  prefixIcon: Icon(Icons.quiz_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a quiz title';
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
              // Assignment and Scheduling Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign to Sections',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Wrap(
                        spacing: AppConstants.paddingS,
                        runSpacing: AppConstants.paddingS,
                        children: AppConstants.studentSections.map((section) {
                          final isSelected =
                              _selectedAssignedSections.contains(section);
                          return FilterChip(
                            label: Text(section),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAssignedSections.add(section);
                                } else {
                                  _selectedAssignedSections.remove(section);
                                }
                              });
                            },
                            selectedColor:
                                AppColors.adminPrimary.withOpacity(0.3),
                            checkmarkColor: AppColors.adminPrimary,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      const Divider(),
                      const SizedBox(height: AppConstants.paddingM),
                      const Text(
                        'Availability Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _availableFrom ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _availableFrom = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Available From',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_availableFrom == null
                              ? 'Select start date'
                              : '${_availableFrom!.year}-${_availableFrom!.month.toString().padLeft(2, '0')}-${_availableFrom!.day.toString().padLeft(2, '0')}'),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _availableTo ??
                                (_availableFrom ?? DateTime.now()),
                            firstDate: _availableFrom ?? DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _availableTo = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Available To',
                            prefixIcon: Icon(Icons.event_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_availableTo == null
                              ? 'Select end date (optional)'
                              : '${_availableTo!.year}-${_availableTo!.month.toString().padLeft(2, '0')}-${_availableTo!.day.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ],
                  ),
                ),
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
              // Manual Question Management Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note),
                          const SizedBox(width: 8),
                          Text(
                            _editingQuestionIndex != null
                                ? 'Edit Question'
                                : 'Add Question Manually',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      DropdownButtonFormField<String>(
                        value: _selectedQuestionType,
                        decoration: const InputDecoration(
                          labelText: 'Question Type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'multipleChoice',
                              child: Text('Multiple Choice')),
                          DropdownMenuItem(
                              value: 'trueFalse', child: Text('True/False')),
                          DropdownMenuItem(
                              value: 'fillInBlank',
                              child: Text('Fill in the Blank')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedQuestionType = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      TextFormField(
                        controller: _questionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          hintText: 'Enter your question here',
                          prefixIcon: Icon(Icons.help_outline),
                        ),
                      ),
                      if (_selectedQuestionType == 'multipleChoice') ...[
                        const SizedBox(height: AppConstants.paddingM),
                        TextFormField(
                          controller: _optionAController,
                          decoration: const InputDecoration(
                            labelText: 'Option A',
                            prefixIcon: Icon(Icons.radio_button_unchecked),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        TextFormField(
                          controller: _optionBController,
                          decoration: const InputDecoration(
                            labelText: 'Option B',
                            prefixIcon: Icon(Icons.radio_button_unchecked),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        TextFormField(
                          controller: _optionCController,
                          decoration: const InputDecoration(
                            labelText: 'Option C',
                            prefixIcon: Icon(Icons.radio_button_unchecked),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        TextFormField(
                          controller: _optionDController,
                          decoration: const InputDecoration(
                            labelText: 'Option D',
                            prefixIcon: Icon(Icons.radio_button_unchecked),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppConstants.paddingM),
                      if (_selectedQuestionType == 'trueFalse')
                        DropdownButtonFormField<String>(
                          value: _correctAnswerController.text.isEmpty
                              ? 'True'
                              : _correctAnswerController.text,
                          decoration: const InputDecoration(
                            labelText: 'Correct Answer',
                            prefixIcon: Icon(Icons.check_circle_outline),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'True', child: Text('True')),
                            DropdownMenuItem(
                                value: 'False', child: Text('False')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _correctAnswerController.text = value;
                            }
                          },
                        )
                      else
                        TextFormField(
                          controller: _correctAnswerController,
                          decoration: InputDecoration(
                            labelText: _selectedQuestionType == 'multipleChoice'
                                ? 'Correct Answer (must match one option)'
                                : 'Correct Answer',
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            hintText: _selectedQuestionType == 'multipleChoice'
                                ? 'Enter the exact text of the correct option'
                                : 'Enter the correct answer',
                          ),
                        ),
                      const SizedBox(height: AppConstants.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _addManualQuestion,
                              icon: Icon(_editingQuestionIndex != null
                                  ? Icons.save
                                  : Icons.add),
                              label: Text(_editingQuestionIndex != null
                                  ? 'Update Question'
                                  : 'Add Question'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.adminPrimary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          if (_editingQuestionIndex != null) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _clearQuestionForm,
                              icon: const Icon(Icons.clear),
                              label: const Text('Cancel'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Questions List
              if (_generatedQuestions.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingL),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Questions (${_generatedQuestions.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        ..._generatedQuestions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final q = entry.value;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.adminPrimary,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              q['question'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Type: ${q['type']} | Answer: ${q['correctAnswer']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.info),
                                  onPressed: () => _editQuestion(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: AppColors.error),
                                  onPressed: () => _deleteQuestion(index),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
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
                text: 'Save Quiz',
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
