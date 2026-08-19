import 'package:lms/models/student/self_attendance_model.dart';

/// Provides the current live class (if any) and the student's
/// self-marked attendance log.
class StudentSelfAttendanceService {
  Future<CurrentSessionModel?> getCurrentSession() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const CurrentSessionModel(
      subject: 'Basic Electrical Wiring',
      batch: 'Batch A',
      facultyName: 'Er. R. Kumar',
      timeRange: '09:00 - 10:00 AM',
    );
  }

  /// One entry per working day (Sundays are off), going back 6 months
  /// from today - enough working days for the History tab's month
  /// picker to have real data for every month it lists.
  Future<List<SelfAttendanceLogEntryModel>> getSelfAttendanceLog() async {
    await Future.delayed(const Duration(milliseconds: 300));

    const subjects = ['Basic Electrical Wiring', 'Workshop Safety', 'Employability Skills'];
    const modes = [SelfAttendanceMode.qrCode, SelfAttendanceMode.appLocation];

    final today = DateTime.now();
    final start = DateTime(today.year, today.month - 5, 1);

    final entries = <SelfAttendanceLogEntryModel>[];
    var dayIndex = 0;

    for (var date = start;
        !date.isAfter(today);
        date = date.add(const Duration(days: 1))) {
      // No classes on Sundays.
      if (date.weekday == DateTime.sunday) continue;

      final subject = subjects[dayIndex % subjects.length];
      final mode = modes[dayIndex % modes.length];
      // Deterministic pattern (not random) so the log looks the same
      // every time the screen reloads: every 8th working day is a miss.
      final isPresent = dayIndex % 8 != 5;

      entries.add(SelfAttendanceLogEntryModel(
        date: date,
        subject: subject,
        mode: mode,
        timeText: isPresent ? '09:0${dayIndex % 9} AM' : '',
        isPresent: isPresent,
      ));

      dayIndex++;
    }

    // Most recent day first, matching how the prototype's log reads.
    return entries.reversed.toList();
  }
}
