import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/text_utils.dart';

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
  final bool notificationsEnabled;
  final String? profilePhotoUrl;
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
    this.notificationsEnabled = true,
    this.profilePhotoUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: normalizePersonName((json['name'] ?? '').toString()),
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      photoUrl: json['photoUrl'] ?? json['profilePhotoUrl'],
      gradeLevel: json['gradeLevel'],
      section: json['section'],
      subject: json['subject'],
      subjects: json['subjects'] != null
          ? normalizeTextList(List<String>.from(json['subjects']))
          : null,
      sectionsHandled: json['sectionsHandled'] != null
          ? normalizeTextList(List<String>.from(json['sectionsHandled']))
          : null,
      notificationsEnabled: json['notificationsEnabled'] != false,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': normalizePersonName(name),
      'email': email,
      'role': role,
      'photoUrl': photoUrl ?? profilePhotoUrl,
      'gradeLevel': gradeLevel,
      'section': section,
      'subject': subject,
      'subjects': subjects != null ? normalizeTextList(subjects!) : null,
      'sectionsHandled':
          sectionsHandled != null ? normalizeTextList(sectionsHandled!) : null,
      'notificationsEnabled': notificationsEnabled,
      'profilePhotoUrl': profilePhotoUrl ?? photoUrl,
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
