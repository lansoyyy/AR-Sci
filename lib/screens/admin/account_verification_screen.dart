import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/admin_session.dart';
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

  bool _isPendingUser(Map<String, dynamic> data) {
    return data['verified'] != true &&
        data['rejected'] != true &&
        data['deleted'] != true &&
        data['deactivated'] != true;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyRoleFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_selectedRoleFilter == 'all') {
      return docs;
    }

    return docs.where((doc) {
      final role = (doc.data()['role'] as String?) ?? 'student';
      return role == _selectedRoleFilter;
    }).toList();
  }

  String _readCsvValue(List<dynamic> row, int index) {
    if (index < 0 || row.length <= index) {
      return '';
    }

    return (row[index] ?? '').toString().trim();
  }

  Future<void> _approveUser({
    required String userId,
    required String name,
  }) async {
    try {
      final adminUserId = await AdminSession.resolveActorId(role: 'admin');

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        if (adminUserId != null) 'verifiedBy': adminUserId,
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
    final snapshot = await _baseQuery().get();
    final pendingDocs = _applyRoleFilter(
      snapshot.docs.where((doc) => _isPendingUser(doc.data())).toList(),
    );

    if (pendingDocs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending accounts to approve')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve All Pending Accounts?'),
        content: Text(
          'Approve ${pendingDocs.length} ${_selectedRoleFilter == 'all' ? 'pending accounts' : '${_selectedRoleFilter}s'} now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final adminUserId = await AdminSession.resolveActorId(role: 'admin');
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in pendingDocs) {
        batch.update(doc.reference, {
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
          'rejected': false,
          if (adminUserId != null) 'verifiedBy': adminUserId,
        });
      }
      await batch.commit();

      for (final doc in pendingDocs) {
        final name = (doc.data()['name'] ?? 'Unknown').toString();
        await NotificationService.notifyStudentApproved(
          studentId: doc.id,
          studentName: name,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved ${pendingDocs.length} users successfully'),
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
      final adminUserId = await AdminSession.resolveActorId(role: 'admin');

      // Create rejection audit log
      await FirebaseFirestore.instance.collection('rejection_logs').add({
        'userId': userId,
        'userName': name,
        'rejectedBy': adminUserId,
        'rejectedAt': FieldValue.serverTimestamp(),
        'reason': reason,
      });

      // Mark user as rejected in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verified': false,
        'rejected': true,
        'accountStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        if (adminUserId != null) 'rejectedBy': adminUserId,
      });

      await NotificationService.notifyStudentRejected(
        studentId: userId,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejected $name. Account removed from approval queue.'),
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
              'This will reject the account and keep it out of the pending approval list. '
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
      final preview = await _prepareImportPreview(input);

      if (!mounted) return;

      final confirmed = await _showImportPreviewDialog(preview);
      if (confirmed != true || preview.importableCount == 0) {
        return;
      }

      setState(() => _isProcessing = true);

      final adminUser = FirebaseAuth.instance.currentUser;
      final batch = FirebaseFirestore.instance.batch();
      for (final operation in preview.operations) {
        final payload = <String, dynamic>{
          ...operation.userData,
          'importedAt': FieldValue.serverTimestamp(),
          if (adminUser != null) 'importedBy': adminUser.uid,
        };

        if (operation.createNew) {
          batch.set(
            FirebaseFirestore.instance.collection('users').doc(),
            {
              ...payload,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        } else if (operation.reference != null) {
          batch.set(
            operation.reference!,
            {
              ...payload,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();

      if (!mounted) return;

      final message = StringBuffer(
        'Imported ${preview.importableCount} account${preview.importableCount == 1 ? '' : 's'}',
      );
      if (preview.alreadyApprovedUsers > 0) {
        message.write(
          '. ${preview.alreadyApprovedUsers} already approved',
        );
      }
      if (preview.skippedUsers > 0) {
        message.write('. ${preview.skippedUsers} skipped');
      }
      if (preview.errors.isNotEmpty) {
        message.write('. ${preview.errors.length} invalid rows');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.toString()),
          backgroundColor: preview.errors.isEmpty && preview.skippedUsers == 0
              ? AppColors.success
              : AppColors.warning,
          duration: const Duration(seconds: 4),
          action: preview.errors.isNotEmpty ||
                  preview.alreadyApprovedUsers > 0 ||
                  preview.skippedUsers > 0
              ? SnackBarAction(
                  label: 'View Report',
                  textColor: AppColors.textWhite,
                  onPressed: () => _showImportReport(preview),
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

  Future<_CsvImportPreview> _prepareImportPreview(String input) async {
    final rows = const CsvToListConverter().convert(input);
    if (rows.isEmpty) {
      throw const FormatException('CSV file is empty');
    }

    final headers =
        rows.first.map((entry) => entry.toString().toLowerCase()).toList();
    final nameIndex = headers.indexOf('name');
    final emailIndex = headers.indexOf('email');
    final roleIndex = headers.indexOf('role');
    final gradeLevelIndex = headers.indexOf('gradelevel');
    final sectionIndex = headers.indexOf('section');
    final subjectsIndex = headers.indexOf('subjects');
    final sectionsHandledIndex = headers.indexOf('sectionshandled');

    if (nameIndex == -1 || emailIndex == -1 || roleIndex == -1) {
      throw const FormatException(
        'CSV must contain name, email, and role columns',
      );
    }

    final existingUsers =
        await FirebaseFirestore.instance.collection('users').get();
    final existingByEmail =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in existingUsers.docs) {
      final email = (doc.data()['email'] ?? '').toString().trim().toLowerCase();
      if (email.isNotEmpty) {
        existingByEmail[email] = doc;
      }
    }

    final adminUser = FirebaseAuth.instance.currentUser;
    final operations = <_CsvImportOperation>[];
    final errors = <String>[];
    final seenEmails = <String>{};
    var newUsers = 0;
    var updatedPendingUsers = 0;
    var alreadyApprovedUsers = 0;
    var skippedUsers = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final rowNumber = i + 1;
      final isBlankRow = row.every(
        (cell) => cell == null || cell.toString().trim().isEmpty,
      );
      if (isBlankRow) {
        continue;
      }

      final name = _readCsvValue(row, nameIndex);
      final email = _readCsvValue(row, emailIndex).toLowerCase();
      final role = _readCsvValue(row, roleIndex).toLowerCase();

      if (name.isEmpty || email.isEmpty || role.isEmpty) {
        errors.add('Row $rowNumber: Missing required fields');
        continue;
      }

      if (!seenEmails.add(email)) {
        errors.add('Row $rowNumber: Duplicate email "$email" in CSV');
        continue;
      }

      if (!['student', 'teacher', 'admin'].contains(role)) {
        errors.add('Row $rowNumber: Invalid role "$role"');
        continue;
      }

      final userData = <String, dynamic>{
        'name': name,
        'email': email,
        'role': role,
        'verified': false,
        'rejected': false,
        'deleted': false,
        'deactivated': false,
        'accountStatus': 'pending',
        if (adminUser != null) 'importedBy': adminUser.uid,
      };

      if (role == 'student') {
        final gradeLevel = _readCsvValue(row, gradeLevelIndex);
        final section = _readCsvValue(row, sectionIndex);
        if (gradeLevel.isNotEmpty) {
          userData['gradeLevel'] = gradeLevel;
        }
        if (section.isNotEmpty) {
          userData['section'] = section;
        }
      }

      if (role == 'teacher') {
        final subjects = _readCsvValue(row, subjectsIndex)
            .split('|')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        final sectionsHandled = _readCsvValue(row, sectionsHandledIndex)
            .split('|')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (subjects.isNotEmpty) {
          userData['subjects'] = subjects;
        }
        if (sectionsHandled.isNotEmpty) {
          userData['sectionsHandled'] = sectionsHandled;
        }
      }

      final existingDoc = existingByEmail[email];
      if (existingDoc == null) {
        operations.add(
          _CsvImportOperation(
            createNew: true,
            rowNumber: rowNumber,
            email: email,
            userData: userData,
          ),
        );
        newUsers++;
        continue;
      }

      final existingData = existingDoc.data();
      if (existingData['deleted'] == true ||
          existingData['deactivated'] == true ||
          existingData['rejected'] == true) {
        skippedUsers++;
        continue;
      }

      if (existingData['verified'] == true) {
        alreadyApprovedUsers++;
        continue;
      }

      operations.add(
        _CsvImportOperation(
          createNew: false,
          rowNumber: rowNumber,
          email: email,
          userData: userData,
          reference: existingDoc.reference,
        ),
      );
      updatedPendingUsers++;
    }

    return _CsvImportPreview(
      newUsers: newUsers,
      updatedPendingUsers: updatedPendingUsers,
      alreadyApprovedUsers: alreadyApprovedUsers,
      skippedUsers: skippedUsers,
      errors: errors,
      operations: operations,
    );
  }

  Future<bool?> _showImportPreviewDialog(_CsvImportPreview preview) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review CSV Import'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New accounts: ${preview.newUsers}'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Updated pending accounts: ${preview.updatedPendingUsers}'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Already approved: ${preview.alreadyApprovedUsers}'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Skipped existing accounts: ${preview.skippedUsers}'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Invalid rows: ${preview.errors.length}'),
              const SizedBox(height: AppConstants.paddingM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Text(
                  preview.importableCount == 0
                      ? 'Nothing new can be imported from this CSV.'
                      : '${preview.importableCount} account${preview.importableCount == 1 ? '' : 's'} will be imported when you continue.',
                ),
              ),
              if (preview.errors.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingM),
                const Text(
                  'Issues Found',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppConstants.paddingS),
                ...preview.errors.take(5).map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $error'),
                      ),
                    ),
                if (preview.errors.length > 5)
                  Text(
                    '...and ${preview.errors.length - 5} more',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: preview.importableCount == 0
                ? null
                : () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Import Accounts'),
          ),
        ],
      ),
    );
  }

  void _showImportReport(_CsvImportPreview preview) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New accounts: ${preview.newUsers}'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Updated pending accounts: ${preview.updatedPendingUsers}'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Already approved: ${preview.alreadyApprovedUsers}'),
              const SizedBox(height: AppConstants.paddingS),
              Text('Skipped existing accounts: ${preview.skippedUsers}'),
              if (preview.errors.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingM),
                const Text(
                  'Invalid Rows',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppConstants.paddingS),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: preview.errors.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '• ${preview.errors[index]}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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

      for (final userId in _selectedUserIds) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final name = (doc.data()?['name'] ?? 'Unknown').toString();
        await NotificationService.notifyStudentApproved(
          studentId: userId,
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
                        label: const Text('Approve All Pending'),
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
                final docs = _applyRoleFilter(
                  allDocs.where((doc) => _isPendingUser(doc.data())).toList(),
                );

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.paddingL),
                      child: Text(
                        'No pending accounts for this filter.',
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

class _CsvImportOperation {
  final bool createNew;
  final int rowNumber;
  final String email;
  final Map<String, dynamic> userData;
  final DocumentReference<Map<String, dynamic>>? reference;

  const _CsvImportOperation({
    required this.createNew,
    required this.rowNumber,
    required this.email,
    required this.userData,
    this.reference,
  });
}

class _CsvImportPreview {
  final int newUsers;
  final int updatedPendingUsers;
  final int alreadyApprovedUsers;
  final int skippedUsers;
  final List<String> errors;
  final List<_CsvImportOperation> operations;

  const _CsvImportPreview({
    required this.newUsers,
    required this.updatedPendingUsers,
    required this.alreadyApprovedUsers,
    required this.skippedUsers,
    required this.errors,
    required this.operations,
  });

  int get importableCount => newUsers + updatedPendingUsers;
}
