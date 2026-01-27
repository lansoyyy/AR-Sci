import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';

class TeacherStudentApprovalScreen extends StatefulWidget {
  const TeacherStudentApprovalScreen({super.key});

  @override
  State<TeacherStudentApprovalScreen> createState() =>
      _TeacherStudentApprovalScreenState();
}

class _TeacherStudentApprovalScreenState
    extends State<TeacherStudentApprovalScreen> {
  final TextEditingController _searchController = TextEditingController();

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('verified', isEqualTo: false);
  }

  Future<void> _approveUser({
    required String userId,
    required String name,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'verified': true,
        'verifiedAt': DateTime.now().toIso8601String(),
        if (currentUser != null) 'verifiedBy': currentUser.uid,
      });

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Students'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search student name or email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final filteredDocs = searchTerm.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data();
                        final name =
                            (data['name'] as String? ?? '').toLowerCase();
                        final email =
                            (data['email'] as String? ?? '').toLowerCase();
                        return name.contains(searchTerm) ||
                            email.contains(searchTerm);
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
                                    ],
                                  ),
                                ),
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
