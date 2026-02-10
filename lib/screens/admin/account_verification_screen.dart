import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved $name')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve user.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject user: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Accounts'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: _RoleChip(
                    label: 'All',
                    isSelected: _selectedRoleFilter == 'all',
                    onTap: () => setState(() => _selectedRoleFilter = 'all'),
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

                    DateTime? createdAt;
                    if (createdAtValue is Timestamp) {
                      createdAt = createdAtValue.toDate();
                    } else if (createdAtValue is String) {
                      createdAt = DateTime.tryParse(createdAtValue);
                    }

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
                                      AppColors.adminPrimary.withOpacity(0.15),
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
                                          height: AppConstants.paddingXS),
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
                                    color: AppColors.warning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radiusRound),
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

  const _InfoPill({
    required this.icon,
    required this.text,
  });

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
