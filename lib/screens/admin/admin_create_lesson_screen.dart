import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class AdminCreateLessonScreen extends StatefulWidget {
  const AdminCreateLessonScreen({super.key});

  @override
  State<AdminCreateLessonScreen> createState() => _AdminCreateLessonScreenState();
}

class _AdminCreateLessonScreenState extends State<AdminCreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedSubject = AppConstants.subjects.first;
  String _selectedGradeLevel = AppConstants.gradeLevels.first;
  bool _isPublished = true;
  bool _isSaving = false;

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'subject': _selectedSubject,
        'gradeLevel': _selectedGradeLevel,
        'content': _contentController.text.trim(),
        'imageUrls': <String>[],
        'videoUrls': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
        'isPublished': _isPublished,
        if (currentUser != null) 'createdBy': currentUser.uid,
      };

      final docRef = await FirebaseFirestore.instance.collection('lessons').add(payload);
      await docRef.update({'id': docRef.id});

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson created successfully.')),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create lesson.')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lesson'),
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
                  labelText: 'Lesson Title',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a lesson title';
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
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 8,
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
                text: 'Save Lesson',
                onPressed: _isSaving ? null : _saveLesson,
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
