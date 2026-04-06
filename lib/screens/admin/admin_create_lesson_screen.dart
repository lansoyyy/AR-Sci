import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/formatted_content_block.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/content_utils.dart';
import '../../utils/notification_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/formatted_content_editor.dart';

class AdminCreateLessonScreen extends StatefulWidget {
  final String role;
  final String? lessonId;
  final Map<String, dynamic>? initialData;

  const AdminCreateLessonScreen({
    super.key,
    this.role = 'admin',
    this.lessonId,
    this.initialData,
  });

  @override
  State<AdminCreateLessonScreen> createState() =>
      _AdminCreateLessonScreenState();
}

class _AdminCreateLessonScreenState extends State<AdminCreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedSubject = AppConstants.subjects.first;
  String _selectedGradeLevel = AppConstants.gradeLevels.first;
  String _selectedQuarter = 'Quarter 3';
  bool _isPublished = true;
  bool _isSaving = false;
  bool _isInitializing = true;
  bool _wasPublished = false;

  List<String> _selectedAssignedSections = <String>[];
  DateTime? _availableFrom;
  DateTime? _availableTo;
  List<FormattedContentBlock> _contentBlocks = <FormattedContentBlock>[];

  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = <String>[];

  File? _selectedMaterialFile;
  String? _selectedMaterialName;
  String? _selectedMaterialType;
  String? _existingMaterialUrl;
  String? _existingMaterialName;
  String? _existingMaterialType;
  String? _existingCreatedBy;
  String? _existingTeacherId;
  List<String> _existingVideoUrls = <String>[];
  List<String> _existingArItems = <String>[];

  bool get _isEditMode {
    return (widget.lessonId ?? '').trim().isNotEmpty ||
        widget.initialData != null;
  }

  Color get _accentColor {
    return widget.role == 'teacher'
        ? AppColors.teacherPrimary
        : AppColors.adminPrimary;
  }

  String get _screenTitle {
    if (_isEditMode) {
      return 'Edit Learning Materials';
    }
    return widget.role == 'teacher'
        ? 'Create Learning Materials'
        : 'Create Learning Materials';
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    try {
      Map<String, dynamic>? data = widget.initialData;
      final lessonId = widget.lessonId?.trim() ?? '';

      if (data == null && lessonId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(lessonId)
            .get();
        if (doc.exists) {
          data = {
            ...?doc.data(),
            'id': doc.data()?['id'] ?? doc.id,
          };
        }
      }

      if (data != null) {
        _applyInitialData(data);
      }
    } catch (e) {
      debugPrint('Failed to initialize lesson editor: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _applyInitialData(Map<String, dynamic> lesson) {
    _titleController.text = (lesson['title'] ?? '').toString();
    _descriptionController.text = (lesson['description'] ?? '').toString();
    _selectedSubject = (lesson['subject'] ?? _selectedSubject).toString();
    _selectedGradeLevel =
        (lesson['gradeLevel'] ?? lesson['grade'] ?? _selectedGradeLevel)
            .toString();
    _selectedQuarter = (lesson['quarter'] ?? _selectedQuarter).toString();
    _isPublished = lesson['isPublished'] == true;
    _wasPublished = _isPublished;
    _selectedAssignedSections =
        stringListFromDynamic(lesson['assignedSections']);
    _availableFrom = parseFlexibleDate(lesson['availableFrom']);
    _availableTo = parseFlexibleDate(lesson['availableTo']);
    _contentBlocks = FormattedContentBlock.listFromJson(
      lesson['contentBlocks'],
      fallbackText: (lesson['content'] ?? '').toString(),
    );
    _existingImageUrls
      ..clear()
      ..addAll(stringListFromDynamic(lesson['imageUrls']));
    _existingMaterialUrl = effectiveMaterialUrl(lesson).trim().isEmpty
        ? null
        : effectiveMaterialUrl(lesson).trim();
    _existingMaterialName = effectiveMaterialName(lesson).trim().isEmpty
        ? null
        : effectiveMaterialName(lesson).trim();
    _existingMaterialType = effectiveMaterialType(lesson).trim().isEmpty
        ? null
        : effectiveMaterialType(lesson).trim();
    _existingCreatedBy = (lesson['createdBy'] ?? '').toString().trim();
    _existingTeacherId =
        (lesson['teacherId'] ?? _existingCreatedBy ?? '').toString().trim();
    _existingVideoUrls = stringListFromDynamic(lesson['videoUrls']);
    _existingArItems = stringListFromDynamic(lesson['arItems']);
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to save learning materials.');
      }

      final docRef = _isEditMode
          ? FirebaseFirestore.instance.collection('lessons').doc(
              widget.lessonId?.trim().isNotEmpty == true
                  ? widget.lessonId!.trim()
                  : (widget.initialData?['id'] ?? '').toString())
          : FirebaseFirestore.instance.collection('lessons').doc();
      final lessonId = docRef.id;

      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final teacherName =
          (teacherDoc.data()?['name'] ?? 'Teacher').toString().trim();

      final uploadedImageUrls = await _uploadImages(lessonId);
      final material = await _uploadMaterial(lessonId);
      final filteredContentBlocks =
          _contentBlocks.where((block) => block.hasMeaningfulContent).toList();

      final materialUrl = material?.url ?? _existingMaterialUrl;
      final materialName = material?.name ?? _existingMaterialName;
      final materialType = material?.type ?? _existingMaterialType;

      final payload = <String, dynamic>{
        'id': lessonId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'subject': _selectedSubject,
        'gradeLevel': _selectedGradeLevel,
        'assignedGradeLevels': <String>[_selectedGradeLevel],
        'quarter': _selectedQuarter,
        'color': _subjectToColorName(_selectedSubject),
        'content': FormattedContentBlock.plainText(filteredContentBlocks),
        'contentBlocks':
            FormattedContentBlock.listToJson(filteredContentBlocks),
        'imageUrls': <String>[
          ..._existingImageUrls,
          ...uploadedImageUrls,
        ],
        'materialUrl': materialUrl,
        'materialName': materialName,
        'materialType': materialType,
        'pdfUrl': materialType == 'pdf' ? materialUrl : null,
        'videoUrls': _existingVideoUrls,
        'arItems': _existingArItems,
        'teacherId': _existingTeacherId?.isNotEmpty == true
            ? _existingTeacherId
            : currentUser.uid,
        'createdBy': _existingCreatedBy?.isNotEmpty == true
            ? _existingCreatedBy
            : currentUser.uid,
        'createdByName': teacherName,
        'isPublished': _isPublished,
        'assignedSections': _selectedAssignedSections,
        'availableFrom': _availableFrom?.toIso8601String(),
        'availableTo': _availableTo?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!_isEditMode) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(payload, SetOptions(merge: true));

      if (_isPublished && !_wasPublished) {
        await NotificationService.notifyLessonPublished(
          lessonId: lessonId,
          lessonTitle: _titleController.text.trim(),
          assignedSections: _selectedAssignedSections,
          assignedGradeLevels: <String>[_selectedGradeLevel],
          teacherName: teacherName,
          deliverAt: _availableFrom,
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Learning materials updated successfully.'
                : 'Learning materials created successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      final message = e is FirebaseException
          ? '${e.code}: ${e.message ?? 'Unknown Firebase error'}'
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save learning materials. $message')),
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

  Future<String?> _pickInlineImageAndUpload() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return null;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (pickedFile == null) {
        return null;
      }

      final extension = pickedFile.path.split('.').last.toLowerCase();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('lesson_content_images/${currentUser.uid}')
          .child('${DateTime.now().millisecondsSinceEpoch}.$extension');

      await storageRef.putFile(
        File(pickedFile.path),
        SettableMetadata(contentType: 'image/$extension'),
      );

      return storageRef.getDownloadURL();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
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

  Future<void> _pickMaterial() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final extension = file.extension?.toLowerCase() ?? 'file';
          setState(() {
            _selectedMaterialFile = File(file.path!);
            _selectedMaterialName = file.name;
            _selectedMaterialType = extension;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to pick material: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  void _removeMaterial() {
    setState(() {
      _selectedMaterialFile = null;
      _selectedMaterialName = null;
      _selectedMaterialType = null;
      _existingMaterialUrl = null;
      _existingMaterialName = null;
      _existingMaterialType = null;
    });
  }

  Future<_UploadedMaterial?> _uploadMaterial(String lessonId) async {
    if (_selectedMaterialFile == null) return null;

    try {
      final extension = _selectedMaterialType ?? 'file';
      final storageRef =
          FirebaseStorage.instance.ref().child('lessons/$lessonId').child(
                'material.$extension',
              );

      await storageRef.putFile(
        _selectedMaterialFile!,
        SettableMetadata(contentType: _contentTypeForExtension(extension)),
      );
      final url = await storageRef.getDownloadURL();
      return _UploadedMaterial(
        url: url,
        name: _selectedMaterialName ?? 'material.$extension',
        type: extension,
      );
    } catch (e) {
      debugPrint('Failed to upload material: $e');
      return null;
    }
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
        backgroundColor: _accentColor,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          .map((subject) => DropdownMenuItem<String>(
                                value: subject,
                                child: Text(subject),
                              ))
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
                          .map((grade) => DropdownMenuItem<String>(
                                value: grade,
                                child: Text(grade),
                              ))
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
                        DropdownMenuItem<String>(
                          value: 'Quarter 3',
                          child: Text('Quarter 3'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Quarter 4',
                          child: Text('Quarter 4'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedQuarter = value);
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Formatted Lesson Content',
                              style: TextStyle(
                                fontSize: AppConstants.fontL,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingS),
                            const Text(
                              'Create text notes with formatting and inline images. Changes are saved with the lesson.',
                              style: TextStyle(
                                fontSize: AppConstants.fontS,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            FormattedContentEditor(
                              blocks: _contentBlocks,
                              allowImages: true,
                              onAddImage: _pickInlineImageAndUpload,
                              emptyLabel:
                                  'Add text blocks and optional images for the lesson content.',
                              onChanged: (blocks) {
                                setState(() => _contentBlocks = blocks);
                              },
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Gallery Images',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontL,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_existingImageUrls.length + _selectedImages.length} attached',
                                  style: const TextStyle(
                                    fontSize: AppConstants.fontS,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            if (_existingImageUrls.isEmpty &&
                                _selectedImages.isEmpty)
                              InkWell(
                                onTap: _pickImages,
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusM),
                                child: Container(
                                  height: 140,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          AppColors.textLight.withOpacity(0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radiusM),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 48),
                                      SizedBox(height: AppConstants.paddingS),
                                      Text('Tap to attach lesson images'),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              Wrap(
                                spacing: AppConstants.paddingS,
                                runSpacing: AppConstants.paddingS,
                                children: [
                                  ..._existingImageUrls
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return _RemoteImageTile(
                                      imageUrl: entry.value,
                                      onRemove: () {
                                        setState(() {
                                          _existingImageUrls
                                              .removeAt(entry.key);
                                        });
                                      },
                                    );
                                  }),
                                  ..._selectedImages
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return _LocalImageTile(
                                      filePath: entry.value.path,
                                      onRemove: () => _removeImage(entry.key),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: AppConstants.paddingM),
                            ],
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(
                                    Icons.add_photo_alternate_outlined),
                                label: const Text('Add Images'),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lesson File',
                              style: TextStyle(
                                fontSize: AppConstants.fontL,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingS),
                            const Text(
                              'Attach a PDF, DOC, or DOCX file for students to open from the lesson.',
                              style: TextStyle(
                                fontSize: AppConstants.fontS,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            if (_selectedMaterialFile == null &&
                                _existingMaterialUrl == null)
                              InkWell(
                                onTap: _pickMaterial,
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusM),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          AppColors.textLight.withOpacity(0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radiusM),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload_file_outlined,
                                          size: 44),
                                      SizedBox(height: AppConstants.paddingS),
                                      Text('Tap to attach a lesson file'),
                                    ],
                                  ),
                                ),
                              )
                            else
                              _MaterialTile(
                                fileName: _selectedMaterialName ??
                                    _existingMaterialName ??
                                    'Attached file',
                                fileType: (_selectedMaterialType ??
                                        _existingMaterialType ??
                                        'file')
                                    .toUpperCase(),
                                onRemove: _removeMaterial,
                              ),
                            const SizedBox(height: AppConstants.paddingM),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _pickMaterial,
                                icon: const Icon(Icons.attach_file_outlined),
                                label: Text(
                                  _selectedMaterialFile == null &&
                                          _existingMaterialUrl == null
                                      ? 'Attach File'
                                      : 'Replace File',
                                ),
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
                              children:
                                  AppConstants.studentSections.map((section) {
                                final isSelected =
                                    _selectedAssignedSections.contains(section);
                                return FilterChip(
                                  label: Text(section),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        if (!_selectedAssignedSections
                                            .contains(section)) {
                                          _selectedAssignedSections
                                              .add(section);
                                        }
                                      } else {
                                        _selectedAssignedSections
                                            .remove(section);
                                      }
                                    });
                                  },
                                  selectedColor: _accentColor.withOpacity(0.18),
                                  checkmarkColor: _accentColor,
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
                            _DateField(
                              label: 'Available From',
                              value: _availableFrom,
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
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            _DateField(
                              label: 'Available To',
                              value: _availableTo,
                              emptyLabel: 'Select end date (optional)',
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    Card(
                      child: SwitchListTile(
                        value: _isPublished,
                        onChanged: (value) =>
                            setState(() => _isPublished = value),
                        activeColor: _accentColor,
                        title: const Text('Published'),
                        subtitle: const Text(
                          'Published lessons can notify assigned students automatically.',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXL),
                    CustomButton(
                      text: _isEditMode
                          ? 'Update Learning Materials'
                          : 'Save Learning Materials',
                      onPressed: _isSaving ? null : _saveLesson,
                      isLoading: _isSaving,
                      fullWidth: true,
                      backgroundColor: _accentColor,
                      icon: Icons.save_outlined,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _UploadedMaterial {
  final String url;
  final String name;
  final String type;

  const _UploadedMaterial({
    required this.url,
    required this.name,
    required this.type,
  });
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String emptyLabel;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.emptyLabel = 'Select date',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
        ),
        child: Text(
          value == null
              ? emptyLabel
              : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}

class _RemoteImageTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRemove;

  const _RemoteImageTile({
    required this.imageUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100,
                height: 100,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.broken_image_outlined),
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocalImageTile extends StatelessWidget {
  final String filePath;
  final VoidCallback onRemove;

  const _LocalImageTile({
    required this.filePath,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Image.file(
            File(filePath),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100,
                height: 100,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.broken_image_outlined),
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final String fileName;
  final String fileType;
  final VoidCallback onRemove;

  const _MaterialTile({
    required this.fileName,
    required this.fileType,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            fileType == 'PDF'
                ? Icons.picture_as_pdf
                : Icons.description_outlined,
            color: fileType == 'PDF' ? AppColors.error : AppColors.info,
            size: 36,
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  fileType,
                  style: const TextStyle(
                    fontSize: AppConstants.fontS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: AppColors.error),
          ),
        ],
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
