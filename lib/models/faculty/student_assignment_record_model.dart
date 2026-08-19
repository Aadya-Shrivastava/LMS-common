import 'assignment_model.dart';

/// One assignment as it relates to a single student, shown on that
/// student's detail screen - e.g. "Wiring Diagram Submission - Graded,
/// 18/20". Reuses `AssignmentStatus` (pending/submitted/graded) since
/// it's the same idea as the general assignment model, just scoped to
/// one student.
class StudentAssignmentRecordModel {
  final String title;
  final String dueDateText;
  AssignmentStatus status;
  String marks;

  StudentAssignmentRecordModel({
    required this.title,
    required this.dueDateText,
    required this.status,
    this.marks = '',
  });
}
