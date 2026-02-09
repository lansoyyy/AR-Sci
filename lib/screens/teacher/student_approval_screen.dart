import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/notification_service.dart';

class TeacherStudentApprovalScreen extends StatefulWidget {
  const TeacherStudentApprovalScreen({super.key});

  @override
  State<TeacherStudentApprovalScreen> createState() =>
      _TeacherStudentApprovalScreenState();
}

class _TeacherStudentApprovalScreenState
    extends State<TeacherStudentApprovalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSectionFilter = 'all';
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _currentUser = UserModel.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<String>? get _teacherSections => _currentUser?.sectionsHandled;

  Query<Map<String, dynamic>> _query() {
    // Teachers can only approve students in their sections
    // Since Firestore doesn't support OR queries, we query all and filter in memory
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('verified', isEqualTo: false);
  }

  bool _isStudentInTeacherScope(Map<String, dynamic> studentData) {
    // If teacher has no sections specified, they can approve all students
    if (_teacherSections == null || _teacherSections!.isEmpty) {
      return true;
    }

    // Check if student's grade level or section matches any of teacher's sections
    final studentGrade = studentData['gradeLevel'] as String?;
    final studentSection = studentData['section'] as String?;

    if (studentGrade != null && _teacherSections!.contains(studentGrade)) {
      return true;
    }
    if (studentSection != null && _teacherSections!.contains(studentSection)) {
      return true;
    }

    return false;
  }

  Future<void> _approveUser({
    required String userId,
    required String name,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        if (currentUser != null) 'verifiedBy': currentUser.uid,
      });

      // Notify student of approval
      await NotificationService.notifyStudentApproved(
        studentId: userId,
        studentName: name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved $name')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve student.')),
      );
    }
  }

  Future<void> _rejectUser({
    required String userId,
    required String name,
    required String reason,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // Create rejection audit log
      await FirebaseFirestore.instance.collection('rejection_logs').add({
        'userId': userId,
        'userName': name,
        'rejectedBy': currentUser?.uid,
        'rejectedAt': FieldValue.serverTimestamp(),
        'reason': reason,
        'rejectedByRole': 'teacher',
      });

      // Mark user as rejected in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verified': false,
        'rejected': true,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        if (currentUser != null) 'rejectedBy': currentUser.uid,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject student: $e')),
      );
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
              'This will reject the student account. '
              'Please provide a reason for rejection.',
            ),
            const SizedBox(height: AppConstants.paddingM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g., Invalid information, wrong section, etc.',
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = _searchController.text.trim().toLowerCase();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Approve Students'),
          backgroundColor: AppColors.teacherPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Students'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSectionFilter,
                  decoration: const InputDecoration(
                    hintText: 'Filter by section',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Sections'),
                    ),
                    ...AppConstants.studentSections.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedSectionFilter = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search student name or email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query().snapshots(),
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
                            'Error loading students',
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

                final docs = snapshot.data?.docs ?? [];
                final scopeFilteredDocs = docs.where((doc) {
                  return _isStudentInTeacherScope(doc.data());
                }).toList();

                final filteredDocs = scopeFilteredDocs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  final section = (data['section'] as String? ?? '');

                  final matchesSearch = searchTerm.isEmpty
                      ? true
                      : name.contains(searchTerm) || email.contains(searchTerm);

                  final matchesSection = _selectedSectionFilter == 'all'
                      ? true
                      : section == _selectedSectionFilter;

                  return matchesSearch && matchesSection;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.paddingL),
                      child: Text(
                        'No pending student accounts.',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();

                    final name = (data['name'] as String?) ?? 'Unknown';
                    final email = (data['email'] as String?) ?? '';
                    final grade = (data['gradeLevel'] as String?) ?? '';
                    final section = (data['section'] as String?) ?? '';

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: AppConstants.paddingM),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppColors.teacherPrimary.withOpacity(0.12),
                                  child: const Icon(
                                    Icons.school_outlined,
                                    color: AppColors.teacherPrimary,
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
                                          height: AppConstants.paddingXS),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (grade.isNotEmpty) ...[
                                        const SizedBox(
                                            height: AppConstants.paddingXS),
                                        Text(
                                          grade,
                                          style: const TextStyle(
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                      if (section.isNotEmpty) ...[
                                        const SizedBox(
                                            height: AppConstants.paddingXS),
                                        Text(
                                          section,
                                          style: const TextStyle(
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
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
                                    const SizedBox(width: AppConstants.paddingS),
                                    OutlinedButton.icon(
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
                                  ],
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
