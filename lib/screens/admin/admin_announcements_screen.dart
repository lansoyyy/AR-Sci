import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String _selectedPriority = 'normal';
  String _targetAudience = 'all';

  final List<Map<String, String>> _priorities = [
    {'id': 'low', 'name': 'Low', 'color': 'grey'},
    {'id': 'normal', 'name': 'Normal', 'color': 'blue'},
    {'id': 'high', 'name': 'High', 'color': 'orange'},
    {'id': 'urgent', 'name': 'Urgent', 'color': 'red'},
  ];

  final List<Map<String, String>> _targets = [
    {'id': 'all', 'name': 'All Users'},
    {'id': 'student', 'name': 'Students Only'},
    {'id': 'teacher', 'name': 'Teachers Only'},
    {'id': 'admin', 'name': 'Admins Only'},
  ];

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();

      final adminName = adminDoc.data()?['name'] as String? ?? 'Administrator';

      // Create the announcement
      final announcementRef =
          await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'priority': _selectedPriority,
        'targetAudience': _targetAudience,
        'createdBy': currentUser?.uid,
        'createdByName': adminName,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Create notifications for target users in the global notifications collection
      final batch = FirebaseFirestore.instance.batch();

      Query<Map<String, dynamic>> usersQuery =
          FirebaseFirestore.instance.collection('users');

      if (_targetAudience != 'all') {
        usersQuery = usersQuery.where('role', isEqualTo: _targetAudience);
      }

      final usersSnapshot = await usersQuery.get();

      for (final user in usersSnapshot.docs) {
        final userData = user.data();
        final userRole = userData['role'] as String? ?? 'student';

        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc();

        batch.set(notificationRef, {
          'userId': user.id,
          'role': userRole,
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'type': 'system',
          'announcementId': announcementRef.id,
          'priority': _selectedPriority,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Announcement sent to ${usersSnapshot.docs.length} users'),
          backgroundColor: AppColors.success,
        ),
      );

      _titleController.clear();
      _messageController.clear();
      setState(() {
        _selectedPriority = 'normal';
        _targetAudience = 'all';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send announcement: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text(
            'This will remove the announcement and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(id)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'low':
        return AppColors.textSecondary;
      default:
        return AppColors.adminPrimary;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.notifications_active;
      case 'low':
        return Icons.notifications_none;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Announcements'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.add_circle), text: 'New'),
                Tab(icon: Icon(Icons.history), text: 'History'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNewAnnouncementTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewAnnouncementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Announcement',
                      style: TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                        hintText: 'Enter announcement title',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        prefixIcon: Icon(Icons.message),
                        hintText: 'Enter your announcement message',
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Message is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _priorities.map((p) {
                        return DropdownMenuItem(
                          value: p['id'],
                          child: Row(
                            children: [
                              Icon(
                                _getPriorityIcon(p['id']!),
                                color: _getPriorityColor(p['id']!),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(p['name']!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPriority = value!);
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    DropdownButtonFormField<String>(
                      value: _targetAudience,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience',
                        prefixIcon: Icon(Icons.people),
                      ),
                      items: _targets.map((t) {
                        return DropdownMenuItem(
                          value: t['id'],
                          child: Text(t['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _targetAudience = value!);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendAnnouncement,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'Sending...' : 'Send Announcement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.data?.docs ?? [];

        if (announcements.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingXL),
              child: Text(
                'No announcements yet.\nCreate your first announcement!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            final data = announcement.data();
            final priority = data['priority'] as String? ?? 'normal';
            final createdAt = data['createdAt'] as Timestamp?;
            final isActive = data['isActive'] as bool? ?? true;

            return Card(
              margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getPriorityColor(priority),
                  child: Icon(
                    _getPriorityIcon(priority),
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  data['title'] as String? ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          data['targetAudience'] as String? ?? 'all',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          createdAt != null
                              ? _formatDate(createdAt.toDate())
                              : 'Unknown',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteAnnouncement(announcement.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.month}/${date.day}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
