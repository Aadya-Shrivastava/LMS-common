/// Whether an assignment is still waiting on the student, or has
/// already been graded. "Overdue" isn't its own value here - it's
/// worked out from `dueDate` on the fly (see `isOverdue` below), the
/// same way the faculty side treats overdue assignments.
enum StudentAssignmentStatus { pending, graded }

/// One assignment shown on the student's Assignments screen.
class StudentAssignmentModel {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final StudentAssignmentStatus status;

  /// Only set once `status` is `graded`, e.g. "18/20".
  final String? marksText;

  const StudentAssignmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    this.marksText,
  });

  /// True once the due date has passed and the student still hasn't
  /// submitted anything. Computed from the current time instead of
  /// being stored, so an assignment automatically flips over to
  /// "Overdue" the moment its due date passes.
  bool get isOverdue =>
      status == StudentAssignmentStatus.pending && DateTime.now().isAfter(dueDate);
}
