import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/notification_service.dart';

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState
    extends State<TeacherAnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSending = false;
  bool _isLoadingProfile = true;
  String _selectedPriority = 'normal';
  String _selectedTemplate = 'custom';
  String _targetAudience = 'students';
  List<String> _teacherSections = <String>[];
  List<String> _selectedSections = <String>[];

  final List<Map<String, String>> _priorities = [
    {'id': 'low', 'name': 'Low'},
    {'id': 'normal', 'name': 'Normal'},
    {'id': 'high', 'name': 'High'},
    {'id': 'urgent', 'name': 'Urgent'},
  ];

  final List<Map<String, String>> _targets = [
    {'id': 'students', 'name': 'My Sections'},
    {'id': 'specific_sections', 'name': 'Specific Sections'},
    {'id': 'all', 'name': 'All Students'},
  ];

  final List<Map<String, String>> _templates = [
    {
      'id': 'custom',
      'name': 'Custom Message',
      'title': '',
      'message': '',
    },
    {
      'id': 'pending_quiz',
      'name': 'Pending Quiz Reminder',
      'title': 'Pending Quiz Reminder',
      'message':
          'Please complete your pending quiz as soon as possible and review the lesson materials before submitting.',
    },
    {
      'id': 'lesson_reminder',
      'name': 'Lesson Reminder',
      'title': 'Lesson Reminder',
      'message':
          'A lesson is available for your section. Review the lesson content and save your notes before marking it complete.',
    },
    {
      'id': 'score_follow_up',
      'name': 'Score Follow-up',
      'title': 'Quiz Scores Released',
      'message':
          'Your quiz scores have been posted. Review the results and check the feedback your teacher has made visible.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() => _isLoadingProfile = false);
        return;
      }

      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final sections = (teacherDoc.data()?['sectionsHandled'] as List<dynamic>?)
              ?.map((entry) => entry.toString().trim())
              .where((entry) => entry.isNotEmpty)
              .toSet()
              .toList() ??
          <String>[];

      if (!mounted) return;
      setState(() {
        _teacherSections = sections;
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load teacher profile: $e')),
      );
    }
  }

  void _applyTemplate(String templateId) {
    final template = _templates.firstWhere(
      (item) => item['id'] == templateId,
      orElse: () => _templates.first,
    );

    setState(() {
      _selectedTemplate = templateId;
      if (templateId != 'custom') {
        _titleController.text = template['title'] ?? '';
        _messageController.text = template['message'] ?? '';
      }
    });
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();

      final teacherName = teacherDoc.data()?['name'] as String? ?? 'Teacher';
      final sections = (teacherDoc.data()?['sectionsHandled'] as List<dynamic>?)
              ?.map((entry) => entry.toString().trim())
              .where((entry) => entry.isNotEmpty)
              .toList() ??
          <String>[];
      final targetSections = _targetAudience == 'specific_sections'
          ? _selectedSections
          : _targetAudience == 'students'
              ? sections
              : <String>[];

      final announcementRef = await FirebaseFirestore.instance
          .collection('teacher_announcements')
          .add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'priority': _selectedPriority,
        'templateId': _selectedTemplate,
        'targetAudience': _targetAudience,
        'teacherSections': sections,
        'targetSections': targetSections,
        'createdBy': currentUser?.uid,
        'createdByName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('verified', isEqualTo: true)
          .get();

      final targetStudents = studentsSnapshot.docs.where((student) {
        if (_targetAudience == 'all') {
          return true;
        }

        final grade = (student.data()['gradeLevel'] ?? '').toString();
        final section = (student.data()['section'] ?? '').toString();
        if (targetSections.isEmpty) {
          return true;
        }

        return targetSections.contains(grade) ||
            targetSections.contains(section);
      }).toList();

      if (targetStudents.isEmpty) {
        if (!mounted) return;
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No students match the selected target audience.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      await NotificationService.notifySystemAnnouncement(
        userIds: targetStudents.map((student) => student.id).toList(),
        role: 'student',
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        metadata: {
          'announcementId': announcementRef.id,
          'createdBy': currentUser?.uid,
          'priority': _selectedPriority,
          'fromTeacher': teacherName,
          'targetSections': targetSections,
          'contentType': 'announcement',
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Announcement sent to ${targetStudents.length} students'),
          backgroundColor: AppColors.success,
        ),
      );

      _titleController.clear();
      _messageController.clear();
      setState(() {
        _selectedPriority = 'normal';
        _selectedTemplate = 'custom';
        _targetAudience = 'students';
        _selectedSections = <String>[];
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
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text(
          'This will remove the announcement and any linked notification entries.',
        ),
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
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('announcementId', isEqualTo: id)
          .where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final notification in notifications.docs) {
        batch.delete(notification.reference);
      }
      batch.delete(FirebaseFirestore.instance
          .collection('teacher_announcements')
          .doc(id));
      await batch.commit();

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
        return AppColors.teacherPrimary;
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
        title: const Text('Send Announcements'),
        backgroundColor: AppColors.teacherPrimary,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
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
                    DropdownButtonFormField<String>(
                      value: _selectedTemplate,
                      decoration: const InputDecoration(
                        labelText: 'Template',
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                      items: _templates.map((template) {
                        return DropdownMenuItem<String>(
                          value: template['id'],
                          child: Text(template['name'] ?? 'Template'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        _applyTemplate(value);
                      },
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
                      items: _priorities.map((priority) {
                        return DropdownMenuItem<String>(
                          value: priority['id'],
                          child: Row(
                            children: [
                              Icon(
                                _getPriorityIcon(priority['id']!),
                                color: _getPriorityColor(priority['id']!),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(priority['name']!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedPriority = value);
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    DropdownButtonFormField<String>(
                      value: _targetAudience,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience',
                        prefixIcon: Icon(Icons.people),
                      ),
                      items: _targets.map((target) {
                        return DropdownMenuItem<String>(
                          value: target['id'],
                          child: Text(target['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _targetAudience = value);
                      },
                    ),
                    if (_targetAudience == 'specific_sections') ...[
                      const SizedBox(height: AppConstants.paddingL),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Sections',
                          style: TextStyle(
                            fontSize: AppConstants.fontM,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Wrap(
                        spacing: AppConstants.paddingS,
                        runSpacing: AppConstants.paddingS,
                        children: (_teacherSections.isEmpty
                                ? AppConstants.studentSections
                                : _teacherSections)
                            .map((section) {
                          final isSelected =
                              _selectedSections.contains(section);
                          return FilterChip(
                            label: Text(section),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (!_selectedSections.contains(section)) {
                                    _selectedSections.add(section);
                                  }
                                } else {
                                  _selectedSections.remove(section);
                                }
                              });
                            },
                            selectedColor: AppColors.teacherPrimary
                                .withValues(alpha: 0.18),
                            checkmarkColor: AppColors.teacherPrimary,
                          );
                        }).toList(),
                      ),
                    ],
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
                label: Text(_isSending ? 'Sending...' : 'Send to Students'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teacherPrimary,
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
    final teacherId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('teacher_announcements')
          .where('createdBy', isEqualTo: teacherId)
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
            final targetSections =
                ((data['targetSections'] as List?) ?? const [])
                    .map((entry) => entry.toString())
                    .where((entry) => entry.trim().isNotEmpty)
                    .toList();

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
                    const SizedBox(height: 4),
                    Text(
                      data['message'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (targetSections.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppConstants.paddingS,
                        runSpacing: AppConstants.paddingS,
                        children: targetSections
                            .map(
                              (section) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.paddingS,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teacherPrimary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusRound,
                                  ),
                                ),
                                child: Text(
                                  section,
                                  style: const TextStyle(
                                    fontSize: AppConstants.fontS,
                                    color: AppColors.teacherPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.people,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          data['targetAudience'] as String? ?? 'students',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time,
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
                    const PopupMenuItem<String>(
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
