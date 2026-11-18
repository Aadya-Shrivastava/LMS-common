/// Whether a class is happening right now, still coming up, or over.
enum StudentClassStatus { live, upcoming, completed, cancelled }

/// One live class on the Live Classes screen, e.g. "09:00-10:00 AM,
/// Basic Electrical Wiring, Er. R. Kumar, Google Meet, Live".
class StudentClassScheduleModel {
  /// How early before the start time the Join button opens.
  static const Duration joinEarly = Duration(minutes: 10);

  /// The live class id from the API. Also used as the reminder's id.
  final int id;
  final String timeRange;
  final String subject;
  final String facultyName;
  final String platform;

  /// The status when the list was loaded. Use `isLiveNow` / `canJoin`
  /// for anything time-sensitive, since time moves on while the screen
  /// stays open.
  final StudentClassStatus status;
  final String meetingLink;

  /// Null when the API's date or time couldn't be read.
  final DateTime? startsAt;
  final DateTime? endsAt;

  const StudentClassScheduleModel({
    this.id = 0,
    required this.timeRange,
    required this.subject,
    required this.facultyName,
    required this.platform,
    required this.status,
    this.meetingLink = '',
    this.startsAt,
    this.endsAt,
  });

  bool get isOver =>
      status == StudentClassStatus.completed || status == StudentClassStatus.cancelled;

  /// True while the class is running: marked live by the server, or the
  /// current time is between its start and end.
  bool isLiveNow([DateTime? now]) {
    if (isOver) return false;
    if (status == StudentClassStatus.live) return true;
    now ??= DateTime.now();
    final start = startsAt;
    final end = endsAt;
    return start != null && end != null && !now.isBefore(start) && now.isBefore(end);
  }

  /// True from `joinEarly` before the start until the class ends.
  bool canJoin([DateTime? now]) {
    if (isOver) return false;
    now ??= DateTime.now();
    if (isLiveNow(now)) return true;
    final start = startsAt;
    final end = endsAt;
    return start != null &&
        !now.isBefore(start.subtract(joinEarly)) &&
        (end == null || now.isBefore(end));
  }
}
