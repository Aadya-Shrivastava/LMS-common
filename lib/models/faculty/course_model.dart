/// Represents one course/subject, e.g. "Data Structures".
class CourseModel {
  final String id;
  final String name;

  /// Example: "CS201".
  final String code;

  /// How many students are enrolled in this course.
  final int studentCount;

  const CourseModel({
    required this.id,
    required this.name,
    required this.code,
    this.studentCount = 0,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      studentCount: json['studentCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'studentCount': studentCount,
    };
  }
}
