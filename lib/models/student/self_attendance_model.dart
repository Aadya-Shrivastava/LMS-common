/// How a self-marked attendance entry was captured.
enum SelfAttendanceMode { qrCode, appLocation }

/// One row of "My Self-Marked Attendance Log", e.g. "01 Aug 2026,
/// Basic Electrical Wiring, QR Code, 09:01 AM, Present".
///
/// `date` is a real `DateTime` (not just display text) so the History
/// tab's month picker and date picker can filter by it.
class SelfAttendanceLogEntryModel {
  final DateTime date;
  final String subject;
  final SelfAttendanceMode mode;

  /// Empty when attendance was never marked for that class.
  final String timeText;
  final bool isPresent;

  const SelfAttendanceLogEntryModel({
    required this.date,
    required this.subject,
    required this.mode,
    required this.timeText,
    required this.isPresent,
  });
}

/// The class currently in session, shown at the top of the Self
/// Attendance screen so the student knows what they're marking
/// attendance for.
class CurrentSessionModel {
  final String subject;
  final String batch;
  final String facultyName;
  final String timeRange;

  const CurrentSessionModel({
    required this.subject,
    required this.batch,
    required this.facultyName,
    required this.timeRange,
  });
}
