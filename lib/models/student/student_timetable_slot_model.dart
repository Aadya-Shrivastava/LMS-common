/// What kind of row a timetable slot is - an actual class, a free
/// period, or a break between classes.
enum StudentTimetableSlotKind { classSlot, free, breakSlot }

/// One row of the student's timetable for a single day, e.g.
/// "Period 1, 09:00-09:45, Basic Electrical Wiring, Er. R. Kumar,
/// Room R-101".
class StudentTimetableSlotModel {
  final String period;
  final String timeRange;
  final StudentTimetableSlotKind kind;

  /// Only set when `kind` is `classSlot`.
  final String? subject;
  final String? facultyName;
  final String? room;

  /// True when this class is held online (Google Meet/Zoom) instead of
  /// in a physical room - that's what makes the "Join" button show up.
  final bool isOnline;

  /// The meeting link to open when "Join" is tapped. Only set when
  /// `isOnline` is true.
  final String? meetingLink;

  const StudentTimetableSlotModel({
    required this.period,
    required this.timeRange,
    required this.kind,
    this.subject,
    this.facultyName,
    this.room,
    this.isOnline = false,
    this.meetingLink,
  });
}
