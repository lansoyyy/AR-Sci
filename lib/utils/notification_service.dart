import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Notification types for different events
enum NotificationType {
  lesson,
  quiz,
  approval,
  rejection,
  system,
  reminder,
}

/// Service for creating and managing notifications across the app
class NotificationService {
  /// Create a notification for a user
  static Future<void> createNotification({
    required String userId,
    required String role,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'role': role,
        'title': title,
        'message': message,
        'type': type.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (metadata != null) ...metadata,
      });
    } catch (e) {
      // Silently fail to avoid disrupting user flow
      // In production, this should be logged to error tracking service
    }
  }

  /// Create notification for new lesson
  static Future<void> notifyNewLesson({
    required String teacherId,
    required List<String> studentIds,
    required String lessonTitle,
  }) async {
    for (final studentId in studentIds) {
      await createNotification(
        userId: studentId,
        role: 'student',
        title: 'New Lesson Available',
        message: 'A new lesson "$lessonTitle" has been added.',
        type: NotificationType.lesson,
        metadata: {'lessonId': lessonTitle},
      );
    }
  }

  /// Create notification for new quiz
  static Future<void> notifyNewQuiz({
    required String teacherId,
    required List<String> studentIds,
    required String quizTitle,
  }) async {
    for (final studentId in studentIds) {
      await createNotification(
        userId: studentId,
        role: 'student',
        title: 'New Quiz Available',
        message: 'A new quiz "$quizTitle" is now available.',
        type: NotificationType.quiz,
        metadata: {'quizId': quizTitle},
      );
    }
  }

  /// Create notification for student approval
  static Future<void> notifyStudentApproved({
    required String studentId,
    required String studentName,
  }) async {
    await createNotification(
      userId: studentId,
      role: 'student',
      title: 'Account Approved',
      message: 'Your account has been verified and approved.',
      type: NotificationType.approval,
    );
  }

  /// Create notification for student rejection
  static Future<void> notifyStudentRejected({
    required String studentId,
    required String reason,
  }) async {
    await createNotification(
      userId: studentId,
      role: 'student',
      title: 'Account Rejected',
      message: 'Your account registration was not approved.',
      type: NotificationType.rejection,
      metadata: {'reason': reason},
    );
  }

  /// Create notification for teacher when student submits quiz
  static Future<void> notifyQuizSubmission({
    required String teacherId,
    required String studentName,
    required String quizTitle,
  }) async {
    await createNotification(
      userId: teacherId,
      role: 'teacher',
      title: 'Quiz Submitted',
      message: '$studentName has submitted quiz "$quizTitle".',
      type: NotificationType.quiz,
      metadata: {'studentName': studentName, 'quizTitle': quizTitle},
    );
  }

  /// Create notification for system announcement
  static Future<void> notifySystemAnnouncement({
    required List<String> userIds,
    required String role,
    required String title,
    required String message,
  }) async {
    for (final userId in userIds) {
      await createNotification(
        userId: userId,
        role: role,
        title: title,
        message: message,
        type: NotificationType.system,
      );
    }
  }

  /// Create notification for lesson progress reminder
  static Future<void> notifyLessonReminder({
    required String userId,
    required String lessonTitle,
  }) async {
    await createNotification(
      userId: userId,
      role: 'student',
      title: 'Lesson Reminder',
      message: 'Continue learning with lesson "$lessonTitle".',
      type: NotificationType.reminder,
      metadata: {'lessonTitle': lessonTitle},
    );
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      // Silently fail
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        if (doc.data()['isRead'] == false) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all notifications for a user
  static Future<void> clearAll(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }
}
