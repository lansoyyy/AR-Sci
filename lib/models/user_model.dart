import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // student, teacher, admin
  final String? photoUrl;
  final String? gradeLevel; // For students
  final String? section; // For students
  final String? subject; // For teachers (legacy, single subject)
  final List<String>? subjects; // For teachers (multiple subjects)
  final List<String>? sectionsHandled; // For teachers (sections they teach)
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.gradeLevel,
    this.section,
    this.subject,
    this.subjects,
    this.sectionsHandled,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      photoUrl: json['photoUrl'],
      gradeLevel: json['gradeLevel'],
      section: json['section'],
      subject: json['subject'],
      subjects:
          json['subjects'] != null ? List<String>.from(json['subjects']) : null,
      sectionsHandled: json['sectionsHandled'] != null
          ? List<String>.from(json['sectionsHandled'])
          : null,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'gradeLevel': gradeLevel,
      'section': section,
      'subject': subject,
      'subjects': subjects,
      'sectionsHandled': sectionsHandled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
