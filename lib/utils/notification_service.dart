import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  lesson,
  quiz,
  approval,
  rejection,
  system,
  reminder,
  grade,
}

class NotificationService {
  static const String _usersCollection = 'users';
  static const String _notificationsCollection = 'notifications';

  static Future<void> createNotification({
    required String userId,
    required String role,
    required String title,
    required String message,
    required NotificationType type,
    DateTime? deliverAt,
    Map<String, dynamic>? metadata,
  }) async {
    await FirebaseFirestore.instance.collection(_notificationsCollection).add({
      'userId': userId,
      'role': role,
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (deliverAt != null) 'deliverAt': Timestamp.fromDate(deliverAt),
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      if (metadata != null) ...metadata,
    });
  }

  static Future<void> _createBatchNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    if (notifications.isEmpty) {
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    for (final notification in notifications) {
      batch.set(
        firestore.collection(_notificationsCollection).doc(),
        notification,
      );
    }
    await batch.commit();
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _loadTargetStudents({
    List<String> assignedSections = const <String>[],
    List<String> assignedGradeLevels = const <String>[],
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_usersCollection)
        .where('role', isEqualTo: 'student')
        .where('verified', isEqualTo: true)
        .get();

    return snapshot.docs.where((doc) {
      final data = doc.data();
      if (data['notificationsEnabled'] == false) {
        return false;
      }

      final section = (data['section'] ?? '').toString().trim();
      final gradeLevel = (data['gradeLevel'] ?? '').toString().trim();

      final matchesSection = assignedSections.isEmpty ||
          (section.isNotEmpty && assignedSections.contains(section));
      final matchesGrade = assignedGradeLevels.isEmpty ||
          (gradeLevel.isNotEmpty && assignedGradeLevels.contains(gradeLevel));

      return matchesSection && matchesGrade;
    }).toList();
  }

  static Future<void> notifyLessonPublished({
    required String lessonId,
    required String lessonTitle,
    List<String> assignedSections = const <String>[],
    List<String> assignedGradeLevels = const <String>[],
    String? teacherName,
    DateTime? deliverAt,
  }) async {
    final targetStudents = await _loadTargetStudents(
      assignedSections: assignedSections,
      assignedGradeLevels: assignedGradeLevels,
    );

    final notifications = targetStudents.map((student) {
      return <String, dynamic>{
        'userId': student.id,
        'role': 'student',
        'title': 'New Lesson Available',
        'message': teacherName == null || teacherName.trim().isEmpty
            ? 'A new lesson "$lessonTitle" has been published.'
            : '$teacherName published a new lesson: "$lessonTitle".',
        'type': NotificationType.lesson.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (deliverAt != null) 'deliverAt': Timestamp.fromDate(deliverAt),
        'lessonId': lessonId,
        'contentType': 'lesson',
      };
    }).toList();

    await _createBatchNotifications(notifications);
  }

  static Future<void> notifyQuizPublished({
    required String quizId,
    required String quizTitle,
    List<String> assignedSections = const <String>[],
    List<String> assignedGradeLevels = const <String>[],
    String? teacherName,
    DateTime? deliverAt,
  }) async {
    final targetStudents = await _loadTargetStudents(
      assignedSections: assignedSections,
      assignedGradeLevels: assignedGradeLevels,
    );

    final notifications = targetStudents.map((student) {
      return <String, dynamic>{
        'userId': student.id,
        'role': 'student',
        'title': 'Pending Quiz',
        'message': teacherName == null || teacherName.trim().isEmpty
            ? 'A new quiz "$quizTitle" is ready for you.'
            : '$teacherName published a quiz: "$quizTitle".',
        'type': NotificationType.reminder.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (deliverAt != null) 'deliverAt': Timestamp.fromDate(deliverAt),
        'quizId': quizId,
        'contentType': 'quiz',
      };
    }).toList();

    await _createBatchNotifications(notifications);
  }

  static Future<void> notifyQuizScore({
    required String studentId,
    required String quizId,
    required String quizTitle,
    required int score,
    required int totalPoints,
  }) async {
    final studentDoc = await FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(studentId)
        .get();
    final data = studentDoc.data();
    if (data == null || data['notificationsEnabled'] == false) {
      return;
    }

    await createNotification(
      userId: studentId,
      role: 'student',
      title: 'Quiz Score Posted',
      message: 'Your score for "$quizTitle" is $score/$totalPoints.',
      type: NotificationType.grade,
      metadata: {
        'quizId': quizId,
        'contentType': 'quiz',
      },
    );
  }

  static Future<void> notifyStudentApproved({
    required String studentId,
    String? studentName,
  }) async {
    await createNotification(
      userId: studentId,
      role: 'student',
      title: 'Account Approved',
      message: studentName == null || studentName.trim().isEmpty
          ? 'Your account has been verified and approved.'
          : 'Your account has been verified and approved, $studentName.',
      type: NotificationType.approval,
    );
  }

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

  static Future<void> notifyQuizSubmission({
    required String teacherId,
    required String studentName,
    required String quizTitle,
  }) async {
    final teacherDoc = await FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(teacherId)
        .get();
    final data = teacherDoc.data();
    if (data == null || data['notificationsEnabled'] == false) {
      return;
    }

    await createNotification(
      userId: teacherId,
      role: 'teacher',
      title: 'Quiz Submitted',
      message: '$studentName submitted "$quizTitle".',
      type: NotificationType.quiz,
      metadata: {
        'quizTitle': quizTitle,
        'studentName': studentName,
      },
    );
  }

  static Future<void> notifySystemAnnouncement({
    required List<String> userIds,
    required String role,
    required String title,
    required String message,
    DateTime? deliverAt,
    Map<String, dynamic>? metadata,
  }) async {
    if (userIds.isEmpty) {
      return;
    }

    final notifications = <Map<String, dynamic>>[];
    for (final userId in userIds) {
      final userDoc = await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(userId)
          .get();
      final data = userDoc.data();
      if (data == null || data['notificationsEnabled'] == false) {
        continue;
      }

      notifications.add({
        'userId': userId,
        'role': role,
        'title': title,
        'message': message,
        'type': NotificationType.system.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (deliverAt != null) 'deliverAt': Timestamp.fromDate(deliverAt),
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
        if (metadata != null) ...metadata,
      });
    }

    await _createBatchNotifications(notifications);
  }

  static Future<void> notifyLessonReminder({
    required String userId,
    required String lessonTitle,
    DateTime? deliverAt,
  }) async {
    await createNotification(
      userId: userId,
      role: 'student',
      title: 'Lesson Reminder',
      message: 'Continue learning with "$lessonTitle".',
      type: NotificationType.reminder,
      deliverAt: deliverAt,
      metadata: {'lessonTitle': lessonTitle},
    );
  }

  static Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection(_notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  static Future<void> markAllAsRead(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      if (doc.data()['isRead'] == false) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  static Future<void> deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection(_notificationsCollection)
        .doc(notificationId)
        .delete();
  }

  static Future<void> clearAll(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
