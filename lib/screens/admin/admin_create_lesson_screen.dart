import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class AdminCreateLessonScreen extends StatefulWidget {
  const AdminCreateLessonScreen({super.key});

  @override
  State<AdminCreateLessonScreen> createState() =>
      _AdminCreateLessonScreenState();
}

class _AdminCreateLessonScreenState extends State<AdminCreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedSubject = AppConstants.subjects.first;
  String _selectedGradeLevel = AppConstants.gradeLevels.first;
  String _selectedQuarter = 'Quarter 3';
  bool _isPublished = true;
  bool _isSaving = false;

  // Assignment and Scheduling fields
  List<String> _selectedAssignedSections = [];
  DateTime? _availableFrom;
  DateTime? _availableTo;

  // Image upload fields
  final List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      final docRef = FirebaseFirestore.instance.collection('lessons').doc();
      final lessonId = docRef.id;

      // Upload images to Firebase Storage
      final imageUrls = await _uploadImages(lessonId);

      // Upload PDF if selected
      final pdfUrl = await _uploadPdf(lessonId);

      final payload = <String, dynamic>{
        'id': lessonId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'subject': _selectedSubject,
        'gradeLevel': _selectedGradeLevel,
        'quarter': _selectedQuarter,
        'color': _subjectToColorName(_selectedSubject),
        'content': _contentController.text.trim(),
        'imageUrls': imageUrls,
        'pdfUrl': pdfUrl,
        'videoUrls': <String>[],
        'arItems': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'isPublished': _isPublished,
        // Assignment and Scheduling fields
        'assignedSections': _selectedAssignedSections,
        'availableFrom': _availableFrom?.toIso8601String(),
        'availableTo': _availableTo?.toIso8601String(),
        if (currentUser != null) 'createdBy': currentUser.uid,
      };

      await docRef.set(payload);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson created successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      debugPrint('Failed to create lesson: $e');

      final message = e is FirebaseException
          ? '${e.code}: ${e.message ?? 'Unknown Firebase error'}'
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create lesson. $message')),
      );
    }
  }

  Future<List<String>> _uploadImages(String lessonId) async {
    if (_selectedImages.isEmpty) return [];

    final imageUrls = <String>[];
    final storageRef =
        FirebaseStorage.instance.ref().child('lessons/$lessonId');

    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      final fileRef = storageRef
          .child('image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');

      try {
        final file = File(image.path);
        await fileRef.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final url = await fileRef.getDownloadURL();
        imageUrls.add(url);
      } catch (e) {
        debugPrint('Failed to upload image $i: $e');
      }
    }

    return imageUrls;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      debugPrint('Failed to pick images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // PDF upload fields
  File? _selectedPdf;
  String? _selectedPdfName;

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _selectedPdf = File(file.path!);
            _selectedPdfName = file.name;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to pick PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick PDF: $e')),
      );
    }
  }

  void _removePdf() {
    setState(() {
      _selectedPdf = null;
      _selectedPdfName = null;
    });
  }

  Future<String?> _uploadPdf(String lessonId) async {
    if (_selectedPdf == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('lessons/$lessonId')
          .child('material.pdf');

      await storageRef.putFile(
        _selectedPdf!,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final url = await storageRef.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Failed to upload PDF: $e');
      return null;
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
        title: const Text('Create Learning Materials'),
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
              DropdownButtonFormField<String>(
                value: _selectedQuarter,
                decoration: const InputDecoration(
                  labelText: 'Quarter',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Quarter 3', child: Text('Quarter 3')),
                  DropdownMenuItem(
                      value: 'Quarter 4', child: Text('Quarter 4')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedQuarter = value);
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

              // Image Upload Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lesson Images',
                            style: TextStyle(
                              fontSize: AppConstants.fontL,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_selectedImages.isNotEmpty)
                            Text(
                              '${_selectedImages.length} selected',
                              style: TextStyle(
                                fontSize: AppConstants.fontS,
                                color: AppColors.textLight,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      if (_selectedImages.isEmpty)
                        InkWell(
                          onTap: _pickImages,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.textLight.withOpacity(0.5),
                                style: BorderStyle.solid,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusM),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: AppColors.textLight.withOpacity(0.7),
                                ),
                                const SizedBox(height: AppConstants.paddingS),
                                Text(
                                  'Tap to add images',
                                  style: TextStyle(
                                    color: AppColors.textLight.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Wrap(
                              spacing: AppConstants.paddingS,
                              runSpacing: AppConstants.paddingS,
                              children: List.generate(
                                _selectedImages.length,
                                (index) => Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.radiusM),
                                      child: Image.file(
                                        File(_selectedImages[index].path),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: AppColors.textLight
                                                .withOpacity(0.2),
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: AppColors.textLight,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: AppColors.textWhite,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              label: const Text('Add More Images'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.adminPrimary.withOpacity(0.8),
                                foregroundColor: AppColors.textWhite,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // PDF Upload Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lesson PDF',
                            style: TextStyle(
                              fontSize: AppConstants.fontL,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_selectedPdf != null)
                            Text(
                              '1 selected',
                              style: TextStyle(
                                fontSize: AppConstants.fontS,
                                color: AppColors.textLight,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      if (_selectedPdf == null)
                        InkWell(
                          onTap: _pickPdf,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.textLight.withOpacity(0.5),
                                style: BorderStyle.solid,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusM),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_file_outlined,
                                  size: 48,
                                  color: AppColors.textLight.withOpacity(0.7),
                                ),
                                const SizedBox(height: AppConstants.paddingS),
                                Text(
                                  'Tap to upload PDF (Lesson 1, Lesson 2, etc.)',
                                  style: TextStyle(
                                    color: AppColors.textLight.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(AppConstants.paddingM),
                              decoration: BoxDecoration(
                                color: AppColors.adminPrimary.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusM),
                                border: Border.all(
                                    color: AppColors.adminPrimary
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    color: AppColors.error,
                                    size: 40,
                                  ),
                                  const SizedBox(width: AppConstants.paddingM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedPdfName ?? 'PDF selected',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text(
                                          'PDF selected',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _removePdf,
                                    icon: const Icon(Icons.close,
                                        color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Assignment and Scheduling section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign to Sections',
                        style: TextStyle(
                          fontSize: AppConstants.fontL,
                          fontWeight: FontWeight.w600,
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
                            selectedColor: AppColors.adminPrimary,
                            checkmarkColor: AppColors.textWhite,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppConstants.paddingL),
                      const Divider(),
                      const SizedBox(height: AppConstants.paddingM),
                      const Text(
                        'Scheduling',
                        style: TextStyle(
                          fontSize: AppConstants.fontL,
                          fontWeight: FontWeight.w600,
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
                          decoration: InputDecoration(
                            labelText: 'Available From',
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.textLight),
                            ),
                          ),
                          child: Text(
                            _availableFrom == null
                                ? 'Select start date'
                                : '${_availableFrom!.year}-${_availableFrom!.month.toString().padLeft(2, '0')}-${_availableFrom!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _availableTo ??
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: _availableFrom ?? DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _availableTo = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Available To',
                            prefixIcon: const Icon(Icons.event_outlined),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.textLight),
                            ),
                          ),
                          child: Text(
                            _availableTo == null
                                ? 'Select end date'
                                : '${_availableTo!.year}-${_availableTo!.month.toString().padLeft(2, '0')}-${_availableTo!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
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
                text: 'Save Learning Materials',
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

String _subjectToColorName(String subject) {
  final s = subject.toLowerCase();
  if (s.contains('physics')) return 'physics';
  if (s.contains('chemistry')) return 'chemistry';
  if (s.contains('biology')) return 'biology';
  if (s.contains('earth')) return 'earthScience';
  return 'physics';
}
