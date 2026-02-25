import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/notification_service.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  String _selectedRoleFilter = 'all';
  bool _isProcessing = false;
  final List<String> _selectedUserIds = [];

  Query<Map<String, dynamic>> _baseQuery() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('verified', isEqualTo: false);
  }

  Future<void> _approveUser({
    required String userId,
    required String name,
  }) async {
    try {
      final adminUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        if (adminUser != null) 'verifiedBy': adminUser.uid,
      });

      // Notify student of approval
      await NotificationService.notifyStudentApproved(
        studentId: userId,
        studentName: name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approved $name')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to approve user.')));
    }
  }

  Future<void> _approveAllUsers() async {
    setState(() => _isProcessing = true);
    try {
      final snapshot = await _baseQuery().get();
      final adminUser = FirebaseAuth.instance.currentUser;

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
          if (adminUser != null) 'verifiedBy': adminUser.uid,
        });
      }
      await batch.commit();

      // Notify all approved users
      for (var doc in snapshot.docs) {
        final name = doc.data()['name'] ?? 'Unknown';
        await NotificationService.notifyStudentApproved(
          studentId: doc.id,
          studentName: name,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved ${snapshot.docs.length} users successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve users: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectUser({
    required String userId,
    required String name,
    required String reason,
  }) async {
    try {
      final adminUser = FirebaseAuth.instance.currentUser;

      // Create rejection audit log
      await FirebaseFirestore.instance.collection('rejection_logs').add({
        'userId': userId,
        'userName': name,
        'rejectedBy': adminUser?.uid,
        'rejectedAt': FieldValue.serverTimestamp(),
        'reason': reason,
      });

      // Mark user as rejected in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verified': false,
        'rejected': true,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        if (adminUser != null) 'rejectedBy': adminUser.uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejected $name. Account marked for deletion.'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reject user: $e')));
    }
  }

  Future<void> _showRejectDialog({
    required String userId,
    required String name,
  }) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $name?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will reject the account and permanently delete it. '
              'Please provide a reason for rejection.',
            ),
            const SizedBox(height: AppConstants.paddingM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g., Invalid information, duplicate account, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _rejectUser(
        userId: userId,
        name: name,
        reason: reasonController.text.trim(),
      );
    }

    reasonController.dispose();
  }

  void _showCSVStructureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Structure Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CSV Format for Bulk User Import:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const SelectableText(
                  '''name,email,role,gradeLevel,section,subjects,sectionsHandled
John Doe,john.doe@email.com,student,Grade 7,Section A,,
Jane Smith,jane.smith@email.com,teacher,,,Science,Math|Section A|Section B
Bob Wilson,bob.wilson@email.com,student,Grade 8,Section B,,''',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              const Text(
                'Required Columns:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.paddingS),
              const Text('• name: Full name of the user'),
              const Text('• email: Email address (must be unique)'),
              const Text('• role: student, teacher, or admin'),
              const SizedBox(height: AppConstants.paddingM),
              const Text(
                'Optional Columns:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.paddingS),
              const Text('• gradeLevel: Grade level (for students)'),
              const Text('• section: Section (for students)'),
              const Text('• subjects: Subjects taught (for teachers)'),
              const Text('• sectionsHandled: Sections taught (for teachers)'),
              const SizedBox(height: AppConstants.paddingM),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: const Text(
                  'Note: For teachers, use | to separate multiple sections.',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importCSV();
            },
            child: const Text('Import CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      final input = File(file.path!).readAsStringSync();
      final rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('CSV file is empty')));
        return;
      }

      // Parse header
      final headers = rows[0].map((e) => e.toString().toLowerCase()).toList();
      final nameIndex = headers.indexOf('name');
      final emailIndex = headers.indexOf('email');
      final roleIndex = headers.indexOf('role');
      final gradeLevelIndex = headers.indexOf('gradelevel');
      final sectionIndex = headers.indexOf('section');
      final subjectsIndex = headers.indexOf('subjects');
      final sectionsHandledIndex = headers.indexOf('sectionshandled');

      if (nameIndex == -1 || emailIndex == -1 || roleIndex == -1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV must contain name, email, and role columns'),
          ),
        );
        return;
      }

      setState(() => _isProcessing = true);

      final adminUser = FirebaseAuth.instance.currentUser;
      final batch = FirebaseFirestore.instance.batch();
      int successCount = 0;
      List<String> errors = [];

      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.length <= nameIndex) continue;

          final name = row[nameIndex]?.toString().trim() ?? '';
          final email = row[emailIndex]?.toString().trim() ?? '';
          final role = row[roleIndex]?.toString().trim().toLowerCase() ?? '';

          if (name.isEmpty || email.isEmpty || role.isEmpty) {
            errors.add('Row $i: Missing required fields');
            continue;
          }

          if (!['student', 'teacher', 'admin'].contains(role)) {
            errors.add('Row $i: Invalid role "$role"');
            continue;
          }

          final userData = <String, dynamic>{
            'name': name,
            'email': email,
            'role': role,
            'verified': false,
            'createdAt': FieldValue.serverTimestamp(),
            if (adminUser != null) 'importedBy': adminUser.uid,
          };

          // Add optional fields for students
          if (role == 'student') {
            if (gradeLevelIndex != -1 && row.length > gradeLevelIndex) {
              userData['gradeLevel'] = row[gradeLevelIndex]?.toString().trim();
            }
            if (sectionIndex != -1 && row.length > sectionIndex) {
              userData['section'] = row[sectionIndex]?.toString().trim();
            }
          }

          // Add optional fields for teachers
          if (role == 'teacher') {
            if (subjectsIndex != -1 && row.length > subjectsIndex) {
              final subjectsStr = row[subjectsIndex]?.toString().trim() ?? '';
              if (subjectsStr.isNotEmpty) {
                userData['subjects'] =
                    subjectsStr.split('|').map((s) => s.trim()).toList();
              }
            }
            if (sectionsHandledIndex != -1 &&
                row.length > sectionsHandledIndex) {
              final sectionsStr =
                  row[sectionsHandledIndex]?.toString().trim() ?? '';
              if (sectionsStr.isNotEmpty) {
                userData['sectionsHandled'] =
                    sectionsStr.split('|').map((s) => s.trim()).toList();
              }
            }
          }

          final docRef = FirebaseFirestore.instance.collection('users').doc();
          batch.set(docRef, userData);
          successCount++;
        } catch (e) {
          errors.add('Row $i: $e');
        }
      }

      await batch.commit();

      if (!mounted) return;

      String message = 'Successfully imported $successCount users';
      if (errors.isNotEmpty) {
        message += '. ${errors.length} errors occurred.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              errors.isEmpty ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 3),
          action: errors.isNotEmpty
              ? SnackBarAction(
                  label: 'View Errors',
                  textColor: AppColors.textWhite,
                  onPressed: () => _showImportErrors(errors),
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import CSV: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showImportErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Errors'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: errors.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• ${errors[index]}',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _approveSelectedUsers() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No users selected')));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      final batch = FirebaseFirestore.instance.batch();

      for (final userId in _selectedUserIds) {
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {
            'verified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
            if (adminUser != null) 'verifiedBy': adminUser.uid,
          },
        );
      }
      await batch.commit();

      // Notify approved users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(
            FieldPath.documentId,
            whereIn: _selectedUserIds.take(10).toList(),
          )
          .get();

      for (final doc in usersSnapshot.docs) {
        final name = doc.data()['name'] ?? 'Unknown';
        await NotificationService.notifyStudentApproved(
          studentId: doc.id,
          studentName: name,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved ${_selectedUserIds.length} users'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _selectedUserIds.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve users: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Accounts'),
        backgroundColor: AppColors.adminPrimary,
        actions: [
          if (_selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppConstants.paddingM),
              child: Center(
                child: Chip(
                  label: Text('${_selectedUserIds.length} selected'),
                  backgroundColor:
                      AppColors.adminPrimary.withValues(alpha: 0.2),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() => _selectedUserIds.clear()),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _RoleChip(
                        label: 'All',
                        isSelected: _selectedRoleFilter == 'all',
                        onTap: () =>
                            setState(() => _selectedRoleFilter = 'all'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: _RoleChip(
                        label: 'Students',
                        isSelected: _selectedRoleFilter == 'student',
                        onTap: () =>
                            setState(() => _selectedRoleFilter = 'student'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: _RoleChip(
                        label: 'Teachers',
                        isSelected: _selectedRoleFilter == 'teacher',
                        onTap: () =>
                            setState(() => _selectedRoleFilter = 'teacher'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingM),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isProcessing ? null : _showCSVStructureDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.adminPrimary,
                          foregroundColor: AppColors.textWhite,
                        ),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Import CSV'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _approveAllUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textWhite,
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Click Lang'),
                      ),
                    ),
                  ],
                ),
                if (_selectedUserIds.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.paddingM),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _approveSelectedUsers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.textWhite,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        'Approve ${_selectedUserIds.length} Selected',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _baseQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingL),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: AppConstants.paddingM),
                          Text(
                            'Error loading accounts',
                            style: TextStyle(
                              fontSize: AppConstants.fontL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingS),
                          Text(
                            '${snapshot.error}',
                            style: const TextStyle(
                              fontSize: AppConstants.fontM,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                final docs = _selectedRoleFilter == 'all'
                    ? allDocs
                    : allDocs.where((doc) {
                        final data = doc.data();
                        final role = (data['role'] as String?) ?? 'student';
                        return role == _selectedRoleFilter;
                      }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.paddingL),
                      child: Text(
                        'No pending accounts.',
                        style: TextStyle(
                          fontSize: AppConstants.fontL,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final name = (data['name'] as String?) ?? 'Unknown';
                    final email = (data['email'] as String?) ?? '';
                    final role = (data['role'] as String?) ?? 'student';
                    final createdAtValue = data['createdAt'];
                    final isSelected = _selectedUserIds.contains(doc.id);

                    DateTime? createdAt;
                    if (createdAtValue is Timestamp) {
                      createdAt = createdAtValue.toDate();
                    } else if (createdAtValue is String) {
                      createdAt = DateTime.tryParse(createdAtValue);
                    }

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.paddingM,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) =>
                                      _toggleUserSelection(doc.id),
                                  activeColor: AppColors.adminPrimary,
                                ),
                                CircleAvatar(
                                  backgroundColor: AppColors.adminPrimary
                                      .withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: AppColors.adminPrimary,
                                  ),
                                ),
                                const SizedBox(width: AppConstants.paddingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: AppConstants.fontL,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppConstants.paddingXS,
                                      ),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.paddingM,
                                    vertical: AppConstants.paddingS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusRound,
                                    ),
                                  ),
                                  child: const Text(
                                    'PENDING',
                                    style: TextStyle(
                                      fontSize: AppConstants.fontS,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            Row(
                              children: [
                                _InfoPill(
                                  icon: Icons.badge_outlined,
                                  text: role.toUpperCase(),
                                ),
                                const SizedBox(width: AppConstants.paddingS),
                                if (createdAt != null)
                                  _InfoPill(
                                    icon: Icons.schedule,
                                    text:
                                        "${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}",
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approveUser(
                                      userId: doc.id,
                                      name: name,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: AppColors.textWhite,
                                    ),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Approve'),
                                  ),
                                ),
                                const SizedBox(width: AppConstants.paddingS),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showRejectDialog(
                                      userId: doc.id,
                                      name: name,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                        color: AppColors.error,
                                      ),
                                    ),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Reject'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? AppColors.adminPrimary : AppColors.surfaceLight,
        foregroundColor:
            isSelected ? AppColors.textWhite : AppColors.textPrimary,
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(label),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppConstants.paddingS),
          Text(
            text,
            style: const TextStyle(
              fontSize: AppConstants.fontS,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
