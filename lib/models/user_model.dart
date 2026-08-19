/// The two kinds of people who can use this app.
enum UserRole { student, faculty }

/// Helper functions to turn a UserRole into text and back again.
/// We need this because we save/load the role as plain text (a String).
extension UserRoleText on UserRole {
  String toText() => this == UserRole.faculty ? 'faculty' : 'student';

  static UserRole fromText(String text) {
    return text == 'faculty' ? UserRole.faculty : UserRole.student;
  }
}

/// Represents one logged-in user, either a student or a faculty member.
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// Example: "Assistant Professor". Only really used for faculty.
  final String designation;

  /// Example: "Computer Science Department".
  final String department;

  /// A link to the user's profile picture. Can be empty.
  final String avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.designation = '',
    this.department = '',
    this.avatarUrl = '',
  });

  /// Builds a UserModel from a JSON map (used when data comes from an API).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRoleText.fromText(json['role'] as String? ?? 'student'),
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  /// Turns this UserModel back into a JSON map (used when sending data).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toText(),
      'designation': designation,
      'department': department,
      'avatarUrl': avatarUrl,
    };
  }
}
