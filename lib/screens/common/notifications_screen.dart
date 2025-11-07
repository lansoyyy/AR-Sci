import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class NotificationsScreen extends StatelessWidget {
  final String role;

  const NotificationsScreen({super.key, required this.role});

  Color get _roleColor {
    switch (role) {
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
  Widget build(BuildContext context) {
    // Sample notifications
    final notifications = [
      NotificationItem(
        title: 'New Lesson Available',
        message: 'Physics: Laws of Motion is now available',
        time: '2 hours ago',
        icon: Icons.book_outlined,
        color: AppColors.studentPrimary,
        isRead: false,
      ),
      NotificationItem(
        title: 'Quiz Reminder',
        message: 'Chemistry quiz starts in 1 hour',
        time: '3 hours ago',
        icon: Icons.quiz_outlined,
        color: AppColors.warning,
        isRead: false,
      ),
      NotificationItem(
        title: 'Assignment Graded',
        message: 'Your Biology assignment has been graded',
        time: '1 day ago',
        icon: Icons.assignment_turned_in_outlined,
        color: AppColors.success,
        isRead: true,
      ),
      NotificationItem(
        title: 'System Update',
        message: 'New features have been added to the app',
        time: '2 days ago',
        icon: Icons.system_update_outlined,
        color: AppColors.info,
        isRead: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _roleColor,
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: AppConstants.paddingL),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: AppConstants.fontL,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(notification: notification);
              },
            ),
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      elevation: notification.isRead ? 0 : AppConstants.elevationS,
      color: notification.isRead ? AppColors.surfaceLight : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        onTap: () {
          // Handle notification tap
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: AppConstants.iconM,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: AppConstants.fontL,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.studentPrimary,
                              shape: BoxShape.circle,
                            ),
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
                    const SizedBox(height: AppConstants.paddingS),
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
