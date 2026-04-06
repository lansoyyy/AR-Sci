import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String role;

  const NotificationsScreen({super.key, required this.role});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = <NotificationItem>[];
  bool _isLoading = true;

  Color get _roleColor {
    switch (widget.role) {
      case 'student':
        return AppColors.studentPrimary;
      case 'teacher':
        return AppColors.teacherPrimary;
      case 'admin':
        return AppColors.adminPrimary;
      default:
        return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _notifications = <NotificationItem>[];
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      final notifications = snapshot.docs
          .map((doc) => _mapNotification(doc))
          .whereType<NotificationItem>()
          .toList()
        ..sort((a, b) => b.sortTime.compareTo(a.sortTime));

      if (!mounted) return;
      setState(() {
        _notifications = notifications.take(50).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  NotificationItem? _mapNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final deliverAt = _parseDateTime(data['deliverAt']);
    if (deliverAt != null && deliverAt.isAfter(DateTime.now())) {
      return null;
    }

    final type = (data['type'] ?? '').toString();
    final contentType = _resolveContentType(data);
    final effectiveTime =
        deliverAt ?? _parseDateTime(data['createdAt']) ?? DateTime.now();
    final senderName = _resolveSenderName(data);
    final priority = (data['priority'] ?? '').toString().trim().toLowerCase();

    return NotificationItem(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      time: _formatTimestamp(effectiveTime),
      icon: _getIconForType(type, contentType),
      color: _getColorForType(type, contentType),
      isRead: data['isRead'] == true,
      typeLabel: _getTypeLabel(type, contentType),
      priorityLabel: priority.isEmpty || priority == 'normal'
          ? null
          : '${priority[0].toUpperCase()}${priority.substring(1)}',
      senderName: senderName,
      sortTime: effectiveTime,
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  String _resolveContentType(Map<String, dynamic> data) {
    final metadata = data['metadata'];
    if (data['contentType'] != null) {
      return data['contentType'].toString().trim().toLowerCase();
    }
    if (metadata is Map && metadata['contentType'] != null) {
      return metadata['contentType'].toString().trim().toLowerCase();
    }
    return (data['type'] ?? 'system').toString().trim().toLowerCase();
  }

  String? _resolveSenderName(Map<String, dynamic> data) {
    final directSender =
        (data['fromTeacher'] ?? data['createdByName'] ?? '').toString().trim();
    if (directSender.isNotEmpty) {
      return directSender;
    }

    final metadata = data['metadata'];
    if (metadata is Map) {
      final metadataSender = (metadata['fromTeacher'] ??
              metadata['createdByName'] ??
              metadata['studentName'] ??
              '')
          .toString()
          .trim();
      if (metadataSender.isNotEmpty) {
        return metadataSender;
      }
    }
    return null;
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index >= 0) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await NotificationService.markAllAsRead(user.uid);

      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _clearNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Notifications'),
          content:
              const Text('Are you sure you want to clear all notifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await NotificationService.clearAll(user.uid);

      if (!mounted) return;
      setState(() => _notifications = <NotificationItem>[]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications cleared')),
      );
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  IconData _getIconForType(String type, String contentType) {
    switch (contentType) {
      case 'lesson':
        return Icons.book_outlined;
      case 'quiz':
        return type == 'grade'
            ? Icons.fact_check_outlined
            : Icons.quiz_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        switch (type.toLowerCase()) {
          case 'reminder':
            return Icons.alarm_outlined;
          case 'grade':
            return Icons.grade_outlined;
          case 'approval':
            return Icons.verified_outlined;
          case 'rejection':
            return Icons.block_outlined;
          case 'ar':
            return Icons.view_in_ar_outlined;
          case 'system':
            return Icons.notifications_active_outlined;
          default:
            return Icons.notifications_outlined;
        }
    }
  }

  Color _getColorForType(String type, String contentType) {
    switch (contentType) {
      case 'lesson':
        return AppColors.studentPrimary;
      case 'quiz':
        return type == 'grade' ? AppColors.info : AppColors.warning;
      case 'announcement':
        return AppColors.adminPrimary;
      default:
        switch (type.toLowerCase()) {
          case 'reminder':
            return AppColors.warning;
          case 'grade':
            return AppColors.info;
          case 'approval':
            return AppColors.success;
          case 'rejection':
            return AppColors.error;
          case 'ar':
            return AppColors.studentPrimary;
          case 'system':
            return AppColors.adminPrimary;
          default:
            return AppColors.textSecondary;
        }
    }
  }

  String _getTypeLabel(String type, String contentType) {
    switch (contentType) {
      case 'lesson':
        return type == 'reminder' ? 'Lesson Reminder' : 'Lesson';
      case 'quiz':
        return type == 'grade' ? 'Score Update' : 'Quiz';
      case 'announcement':
        return 'Announcement';
      default:
        switch (type.toLowerCase()) {
          case 'approval':
            return 'Approval';
          case 'rejection':
            return 'Rejection';
          case 'reminder':
            return 'Reminder';
          case 'system':
            return 'System';
          case 'grade':
            return 'Score Update';
          default:
            return 'Notification';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _roleColor,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.textWhite),
              ),
            ),
          TextButton(
            onPressed: _clearNotifications,
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: AppConstants.paddingL),
                      const Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: AppConstants.fontL,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _roleColor,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationCard(
                        notification: notification,
                        onTap: () {
                          if (!notification.isRead) {
                            _markAsRead(notification.id);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final bool isRead;
  final String typeLabel;
  final String? priorityLabel;
  final String? senderName;
  final DateTime sortTime;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.isRead,
    required this.typeLabel,
    required this.sortTime,
    this.priorityLabel,
    this.senderName,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    IconData? icon,
    Color? color,
    bool? isRead,
    String? typeLabel,
    String? priorityLabel,
    String? senderName,
    DateTime? sortTime,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isRead: isRead ?? this.isRead,
      typeLabel: typeLabel ?? this.typeLabel,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      senderName: senderName ?? this.senderName,
      sortTime: sortTime ?? this.sortTime,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      elevation: notification.isRead ? 0 : AppConstants.elevationS,
      color: notification.isRead
          ? AppColors.surfaceLight
          : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: AppConstants.iconM,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: AppConstants.fontL,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.studentPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Wrap(
                      spacing: AppConstants.paddingS,
                      runSpacing: AppConstants.paddingS,
                      children: [
                        _NotificationTag(
                          label: notification.typeLabel,
                          color: notification.color,
                        ),
                        if (notification.priorityLabel != null)
                          _NotificationTag(
                            label: notification.priorityLabel!,
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    if (notification.senderName != null) ...[
                      Text(
                        notification.senderName!,
                        style: const TextStyle(
                          fontSize: AppConstants.fontS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingXS),
                    ],
                    Text(
                      notification.time,
                      style: const TextStyle(
                        fontSize: AppConstants.fontS,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTag extends StatelessWidget {
  final String label;
  final Color color;

  const _NotificationTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppConstants.fontXS,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
