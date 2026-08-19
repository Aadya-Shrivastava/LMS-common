/// The 4 headline numbers shown at the top of the student dashboard.
class StudentDashboardStats {
  final double attendancePercent;
  final String assignmentsDoneText;
  final int upcomingExamsCount;
  final String feeDueText;

  const StudentDashboardStats({
    required this.attendancePercent,
    required this.assignmentsDoneText,
    required this.upcomingExamsCount,
    required this.feeDueText,
  });
}
