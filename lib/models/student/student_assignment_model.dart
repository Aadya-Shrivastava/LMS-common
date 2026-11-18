/// Whether an assignment is still waiting on the student, has been
/// submitted, or has been graded. "Overdue" isn't its own value here -
/// it's worked out from `dueDate` on the fly (see `isOverdue` below),
/// the same way the faculty side treats overdue assignments.
enum StudentAssignmentStatus { pending, submitted, graded }

/// One assignment shown on the student's Assignments screen.
class StudentAssignmentModel {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final StudentAssignmentStatus status;

  /// Only set once `status` is `graded`, e.g. "18/20".
  final String? marksText;

  /// The most marks this assignment can get, or 0 if not set.
  final int maxMarks;

  /// The faculty's instructions. Can be empty.
  final String description;

  /// A link to the question file the faculty attached. Can be empty.
  final String fileUrl;

  /// Who set the assignment. Can be empty.
  final String facultyName;

  /// The faculty's comments once it's checked. Can be empty.
  final String feedback;

  /// When the student handed it in, or null if they haven't.
  final DateTime? submittedAt;

  /// A link to the file the student handed in. Can be empty.
  final String submittedFileUrl;

  const StudentAssignmentModel({
    this.facultyName = '',
    this.feedback = '',
    this.submittedAt,
    this.submittedFileUrl = '',
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    this.marksText,
    this.maxMarks = 0,
    this.description = '',
    this.fileUrl = '',
  });

  /// True once the student has handed it in (graded or not).
  bool get isDone => status != StudentAssignmentStatus.pending;

  /// True once the due date has passed and the student still hasn't
  /// submitted anything. Computed from the current time instead of
  /// being stored, so an assignment automatically flips over to
  /// "Overdue" the moment its due date passes.
  bool get isOverdue =>
      status == StudentAssignmentStatus.pending && DateTime.now().isAfter(dueDate);
}
