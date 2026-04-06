import 'package:cloud_firestore/cloud_firestore.dart';

import 'formatted_content_block.dart';

class LessonModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String gradeLevel;
  final String content;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String? pdfUrl;
  final String? materialUrl;
  final String? materialName;
  final String? materialType;
  final List<FormattedContentBlock> contentBlocks;
  final String teacherId;
  final List<String> assignedSections;
  final List<String> assignedGradeLevels;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool isPublished;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.gradeLevel,
    required this.content,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.pdfUrl,
    this.materialUrl,
    this.materialName,
    this.materialType,
    this.contentBlocks = const [],
    required this.teacherId,
    this.assignedSections = const [],
    this.assignedGradeLevels = const [],
    required this.createdAt,
    this.scheduledDate,
    this.availableFrom,
    this.availableTo,
    this.isPublished = false,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    DateTime? _parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return LessonModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      gradeLevel: json['gradeLevel'] ?? '',
      content: json['content'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      pdfUrl: json['pdfUrl'] as String?,
      materialUrl: (json['materialUrl'] ?? json['pdfUrl']) as String?,
      materialName: json['materialName'] as String?,
      materialType: json['materialType'] as String?,
      contentBlocks: FormattedContentBlock.listFromJson(
        json['contentBlocks'],
        fallbackText: (json['content'] ?? '').toString(),
      ),
      teacherId: json['teacherId'] ?? '',
      assignedSections: List<String>.from(json['assignedSections'] ?? []),
      assignedGradeLevels: List<String>.from(json['assignedGradeLevels'] ?? []),
      createdAt: _parseDate(json['createdAt']),
      scheduledDate: _parseOptionalDate(json['scheduledDate']),
      availableFrom: _parseOptionalDate(json['availableFrom']),
      availableTo: _parseOptionalDate(json['availableTo']),
      isPublished: json['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'gradeLevel': gradeLevel,
      'content': content,
      'contentBlocks': FormattedContentBlock.listToJson(contentBlocks),
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'pdfUrl': pdfUrl,
      'materialUrl': materialUrl ?? pdfUrl,
      'materialName': materialName,
      'materialType': materialType,
      'teacherId': teacherId,
      'assignedSections': assignedSections,
      'assignedGradeLevels': assignedGradeLevels,
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'availableFrom': availableFrom?.toIso8601String(),
      'availableTo': availableTo?.toIso8601String(),
      'isPublished': isPublished,
    };
  }
}
