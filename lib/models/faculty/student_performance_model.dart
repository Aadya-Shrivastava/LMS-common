/// One student's row in the "Student Performance" overview table.
///
/// `internalMarks` is not `final` - editing the marks field and tapping
/// "Save Internal Marks" updates it directly on this object.
class StudentPerformanceModel {
  final String studentName;
  final String studentInitials;
  final int attendancePercent;
  final String assignmentsCompletedText;
  String internalMarks;
  final String grade;

  StudentPerformanceModel({
    required this.studentName,
    required this.studentInitials,
    required this.attendancePercent,
    required this.assignmentsCompletedText,
    required this.internalMarks,
    required this.grade,
  });
}
