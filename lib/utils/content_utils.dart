import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/formatted_content_block.dart';
import '../models/user_model.dart';

DateTime? parseFlexibleDate(dynamic value) {
  if (value == null) {
    return null;
  }
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

List<String> stringListFromDynamic(dynamic value) {
  if (value is List) {
    return value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
  return const <String>[];
}

bool isPublishedNow(Map<String, dynamic> content, {DateTime? now}) {
  if (content['isPublished'] != true) {
    return false;
  }

  final currentTime = now ?? DateTime.now();
  final availableFrom = parseFlexibleDate(content['availableFrom']) ??
      parseFlexibleDate(content['scheduledDate']);
  final availableTo = parseFlexibleDate(content['availableTo']);

  if (availableFrom != null && currentTime.isBefore(availableFrom)) {
    return false;
  }

  if (availableTo != null && currentTime.isAfter(availableTo)) {
    return false;
  }

  return true;
}

bool matchesStudentAssignment(
  Map<String, dynamic> content,
  UserModel? student,
) {
  if (student == null) {
    return false;
  }

  final assignedSections = stringListFromDynamic(content['assignedSections']);
  final assignedGradeLevels =
      stringListFromDynamic(content['assignedGradeLevels']);
  final legacyGradeLevel =
      (content['gradeLevel'] ?? content['grade'] ?? '').toString().trim();

  final studentSection = student.section?.trim() ?? '';
  final studentGradeLevel = student.gradeLevel?.trim() ?? '';

  if (assignedGradeLevels.isNotEmpty &&
      !assignedGradeLevels.contains(studentGradeLevel)) {
    return false;
  }

  if (assignedSections.isNotEmpty &&
      !assignedSections.contains(studentSection)) {
    return false;
  }

  if (assignedGradeLevels.isEmpty &&
      legacyGradeLevel.isNotEmpty &&
      legacyGradeLevel != studentGradeLevel) {
    return false;
  }

  return true;
}

bool canStudentAccessContent(
  Map<String, dynamic> content,
  UserModel? student, {
  DateTime? now,
}) {
  return isPublishedNow(content, now: now) &&
      matchesStudentAssignment(content, student);
}

bool hasLessonLearningContent(Map<String, dynamic> lesson) {
  final contentText = (lesson['content'] ?? '').toString().trim();
  final contentBlocks =
      FormattedContentBlock.listFromJson(lesson['contentBlocks']);
  final imageUrls = stringListFromDynamic(lesson['imageUrls']);
  final videoUrls = stringListFromDynamic(lesson['videoUrls']);
  final arItems = stringListFromDynamic(lesson['arItems']);
  final materialUrl =
      (lesson['materialUrl'] ?? lesson['pdfUrl'] ?? '').toString().trim();
  final arModelUrl = (lesson['arModelUrl'] ?? '').toString().trim();

  return contentText.isNotEmpty ||
      contentBlocks.isNotEmpty ||
      imageUrls.isNotEmpty ||
      videoUrls.isNotEmpty ||
      arItems.isNotEmpty ||
      materialUrl.isNotEmpty ||
      arModelUrl.isNotEmpty;
}

String effectiveMaterialUrl(Map<String, dynamic> lesson) {
  return (lesson['materialUrl'] ?? lesson['pdfUrl'] ?? '').toString();
}

String effectiveMaterialName(Map<String, dynamic> lesson) {
  final explicitName = (lesson['materialName'] ?? '').toString().trim();
  if (explicitName.isNotEmpty) {
    return explicitName;
  }

  final url = effectiveMaterialUrl(lesson);
  if (url.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(url);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }

  return url.split('/').last;
}

String effectiveMaterialType(Map<String, dynamic> lesson) {
  final explicitType = (lesson['materialType'] ?? '').toString().trim();
  if (explicitType.isNotEmpty) {
    return explicitType.toLowerCase();
  }

  final name = effectiveMaterialName(lesson).toLowerCase();
  if (name.endsWith('.docx')) {
    return 'docx';
  }
  if (name.endsWith('.doc')) {
    return 'doc';
  }
  if (name.endsWith('.pdf')) {
    return 'pdf';
  }
  return 'file';
}
