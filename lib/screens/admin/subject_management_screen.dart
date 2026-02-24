import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isAdding = false;
  List<Map<String, dynamic>> _subjects = [];
  String? _editingSubjectId;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .orderBy('name')
          .get();

      if (mounted) {
        setState(() {
          _subjects = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] as String? ?? '',
              'code': data['code'] as String? ?? '',
              'description': data['description'] as String? ?? '',
              'gradeLevels': List<String>.from(data['gradeLevels'] ?? []),
              'createdAt': data['createdAt'],
            };
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subjects: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final subjectData = {
        'name': _subjectController.text.trim(),
        'code': _codeController.text.trim().toUpperCase(),
        'description': _descriptionController.text.trim(),
        'gradeLevels': <String>[], // Can be expanded later
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      };

      await FirebaseFirestore.instance.collection('subjects').add(subjectData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      _clearForm();
      await _loadSubjects();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding subject: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateSubject() async {
    if (!_formKey.currentState!.validate() || _editingSubjectId == null) return;

    setState(() => _isLoading = true);
    try {
      final subjectData = {
        'name': _subjectController.text.trim(),
        'code': _codeController.text.trim().toUpperCase(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      };

      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_editingSubjectId)
          .update(subjectData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      _clearForm();
      await _loadSubjects();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating subject: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteSubject(String subjectId, String subjectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "$subjectName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .delete();

      await _loadSubjects();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject deleted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting subject: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _editSubject(Map<String, dynamic> subject) {
    setState(() {
      _editingSubjectId = subject['id'] as String;
      _subjectController.text = subject['name'] as String;
      _codeController.text = subject['code'] as String;
      _descriptionController.text = subject['description'] as String;
      _isAdding = true;
    });
  }

  void _clearForm() {
    setState(() {
      _editingSubjectId = null;
      _subjectController.clear();
      _codeController.clear();
      _descriptionController.clear();
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Management'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: Column(
        children: [
          // Add/Edit Subject Form
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.1),
              border: Border(
                bottom:
                    BorderSide(color: AppColors.adminPrimary.withOpacity(0.3)),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingSubjectId == null
                            ? 'Add New Subject'
                            : 'Edit Subject',
                        style: const TextStyle(
                          fontSize: AppConstants.fontL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.adminPrimary,
                        ),
                      ),
                      if (_isAdding)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearForm,
                        ),
                    ],
                  ),
                  if (_isAdding) ...[
                    const SizedBox(height: AppConstants.paddingM),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter subject name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code',
                        prefixIcon: Icon(Icons.code),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter subject code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: _editingSubjectId == null
                                ? 'Add Subject'
                                : 'Update Subject',
                            onPressed: _editingSubjectId == null
                                ? _addSubject
                                : _updateSubject,
                            isLoading: _isLoading,
                            backgroundColor: AppColors.adminPrimary,
                          ),
                        ),
                        if (_editingSubjectId != null) ...[
                          const SizedBox(width: AppConstants.paddingM),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearForm,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(
                                    color: AppColors.adminPrimary),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isAdding = true),
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Subject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Subjects List
          Expanded(
            child: _subjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 80,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.paddingL),
                        Text(
                          'No subjects yet',
                          style: TextStyle(
                            fontSize: AppConstants.fontL,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        Text(
                          'Click "Add New Subject" to get started',
                          style: TextStyle(
                            fontSize: AppConstants.fontM,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: AppConstants.paddingM),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.adminPrimary.withOpacity(0.1),
                            child: Text(
                              subject['code'] as String? ?? 'N/A',
                              style: const TextStyle(
                                color: AppColors.adminPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            subject['name'] as String? ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppConstants.fontL,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (subject['description'] != null &&
                                  (subject['description'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    subject['description'] as String,
                                    style: TextStyle(
                                      fontSize: AppConstants.fontS,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppColors.adminPrimary),
                                onPressed: () => _editSubject(subject),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AppColors.error),
                                onPressed: () => _deleteSubject(
                                  subject['id'] as String,
                                  subject['name'] as String? ?? 'Unknown',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
