/// Whether an assignment is still accepting submissions or is closed.
enum AssignmentSummaryStatus { active, closed }

/// One row in the faculty "All Assignments" list - a summary of one
/// assignment, not an individual student's submission (see
/// `SubmissionModel` for that).
///
/// `title` and `dueDate` aren't `final` - the "All Assignments" screen
/// lets a faculty member open one of their own assignments and edit
/// its due date directly.
class AssignmentSummaryModel {
  final String id;
  String title;
  final String batch;
  DateTime dueDate;

  final int submittedCount;
  final int totalCount;
  final AssignmentSummaryStatus status;

  AssignmentSummaryModel({
    required this.id,
    required this.title,
    required this.batch,
    required this.dueDate,
    required this.submittedCount,
    required this.totalCount,
    required this.status,
  });

  /// Whether this assignment's due date has already passed.
  bool get isOverdue => DateTime.now().isAfter(dueDate);
}
