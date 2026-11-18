/// One row of the campus's working-days calendar, e.g. "Monday,
/// Working, Morning Shift".
class WorkingDayModel {
  final String day;
  final String status;
  final String shift;

  const WorkingDayModel({
    required this.day,
    required this.status,
    required this.shift,
  });

  bool get isWorking => status.toLowerCase() == 'working';
}

/// The campus's attendance rules, e.g. "you need 75% to pass".
class AttendanceRulesModel {
  /// Below this the student has an attendance shortage.
  final double minRequiredPercent;

  /// Below this the student gets a low-attendance warning.
  final double lowAlertPercent;

  /// Below this the student can't sit exams.
  final double examLockPercent;

  /// How late a student can check in and still be marked on time.
  final int lateGraceMinutes;

  const AttendanceRulesModel({
    required this.minRequiredPercent,
    required this.lowAlertPercent,
    required this.examLockPercent,
    required this.lateGraceMinutes,
  });
}
