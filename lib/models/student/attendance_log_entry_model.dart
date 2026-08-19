/// One row of the "Attendance Log" on the Attendance screen, e.g.
/// "01 Aug 2026, Basic Electrical Wiring, Present, Er. R. Kumar".
///
/// `date` is a real `DateTime` (not just display text) so the
/// calendar on the Attendance screen can match a tapped day to the
/// entries recorded on it.
class AttendanceLogEntryModel {
  final DateTime date;
  final String subject;
  final bool isPresent;
  final String markedByFacultyName;

  const AttendanceLogEntryModel({
    required this.date,
    required this.subject,
    required this.isPresent,
    required this.markedByFacultyName,
  });
}
