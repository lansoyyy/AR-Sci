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
  final String teacherId;
  final DateTime createdAt;
  final DateTime? scheduledDate;
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
    required this.teacherId,
    required this.createdAt,
    this.scheduledDate,
    this.isPublished = false,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
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
      teacherId: json['teacherId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
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
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'pdfUrl': pdfUrl,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'isPublished': isPublished,
    };
  }
}
