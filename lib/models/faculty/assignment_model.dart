/// How far along an assignment is.
enum AssignmentStatus { pending, submitted, graded }

/// Turns an AssignmentStatus into text and back, for saving/loading.
extension AssignmentStatusText on AssignmentStatus {
  String toText() => name;

  static AssignmentStatus fromText(String text) {
    return AssignmentStatus.values.firstWhere(
      (status) => status.name == text,
      orElse: () => AssignmentStatus.pending,
    );
  }
}

/// Represents one assignment given to students.
class AssignmentModel {
  final String id;
  final String title;
  final String courseName;
  final DateTime dueDate;
  final AssignmentStatus status;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.courseName,
    required this.dueDate,
    this.status = AssignmentStatus.pending,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      courseName: json['courseName'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: AssignmentStatusText.fromText(
        json['status'] as String? ?? 'pending',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'courseName': courseName,
      'dueDate': dueDate.toIso8601String(),
      'status': status.toText(),
    };
  }
}
