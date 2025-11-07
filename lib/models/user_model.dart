class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // student, teacher, admin
  final String? photoUrl;
  final String? gradeLevel; // For students
  final String? subject; // For teachers
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.gradeLevel,
    this.subject,
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
      subject: json['subject'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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
      'subject': subject,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
