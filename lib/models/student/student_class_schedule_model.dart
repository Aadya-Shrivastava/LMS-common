/// Whether a class on today's schedule is happening right now or is
/// still coming up later today.
enum StudentClassStatus { live, upcoming }

/// One row of the student's "Today's Schedule" on the Live Classes
/// screen, e.g. "09:00-10:00 AM, Basic Electrical Wiring, Er. R.
/// Kumar, Google Meet, Live".
class StudentClassScheduleModel {
  final String timeRange;
  final String subject;
  final String facultyName;
  final String platform;
  final StudentClassStatus status;
  final String meetingLink;

  const StudentClassScheduleModel({
    required this.timeRange,
    required this.subject,
    required this.facultyName,
    required this.platform,
    required this.status,
    this.meetingLink = '',
  });
}
