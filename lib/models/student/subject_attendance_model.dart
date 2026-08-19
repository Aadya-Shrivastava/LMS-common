/// One subject's attendance percentage - shown as a progress bar in
/// the "Subject-wise Attendance" section of the Attendance screen.
class SubjectAttendanceModel {
  final String subject;

  /// A number from 0 to 100.
  final double percent;

  const SubjectAttendanceModel({required this.subject, required this.percent});
}
