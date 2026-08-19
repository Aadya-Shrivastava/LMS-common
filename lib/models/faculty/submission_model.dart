/// Whether a student's submission has been graded yet - or, for
/// `missing`, whether they haven't submitted anything at all.
enum SubmissionStatus { pendingReview, graded, missing }

/// One student's submission for a single assignment, shown in the
/// faculty grading list.
///
/// `marks` is not `final` - typing a mark into the grading screen and
/// tapping "Save" updates it directly on this object.
class SubmissionModel {
  final String studentName;
  final String studentInitials;

  /// Shown as text, e.g. "01 Aug, 08:40 AM".
  final String submittedAtText;

  final String fileName;
  SubmissionStatus status;
  String marks;

  SubmissionModel({
    required this.studentName,
    required this.studentInitials,
    required this.submittedAtText,
    required this.fileName,
    required this.status,
    this.marks = '',
  });
}
