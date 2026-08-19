import 'package:lms/models/student/attendance_log_entry_model.dart';
import 'package:lms/models/student/subject_attendance_model.dart';

/// Provides the student's attendance record: the subject-wise
/// breakdown, and the full daily log (spanning the last several
/// months, so there's real data behind the month picker).
class StudentAttendanceService {
  /// The prototype only shows overall/monthly attendance - this
  /// subject-wise breakdown is additional, so a student can see which
  /// specific subject is dragging their overall percentage down.
  Future<List<SubjectAttendanceModel>> getSubjectWiseAttendance() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      SubjectAttendanceModel(subject: 'Basic Electrical Wiring', percent: 94),
      SubjectAttendanceModel(subject: 'Workshop Safety', percent: 87),
      SubjectAttendanceModel(subject: 'Employability Skills', percent: 96),
    ];
  }

  /// One entry per working day (Sundays are off), going back 6 months
  /// from today - enough working days for the month picker to have
  /// real data for every month it lists.
  Future<List<AttendanceLogEntryModel>> getAttendanceLog() async {
    await Future.delayed(const Duration(milliseconds: 300));

    const subjects = [
      ('Basic Electrical Wiring', 'Er. R. Kumar'),
      ('Workshop Safety', 'S. Pandey'),
      ('Employability Skills', 'N. Singh'),
    ];

    final today = DateTime.now();
    final start = DateTime(today.year, today.month - 5, 1);

    final entries = <AttendanceLogEntryModel>[];
    var dayIndex = 0;

    for (var date = start;
        !date.isAfter(today);
        date = date.add(const Duration(days: 1))) {
      // No classes on Sundays.
      if (date.weekday == DateTime.sunday) continue;

      final subject = subjects[dayIndex % subjects.length];
      // Deterministic pattern (not random) so the log looks the same
      // every time the screen reloads: every 7th working day is a miss.
      final isPresent = dayIndex % 7 != 4;

      entries.add(AttendanceLogEntryModel(
        date: date,
        subject: subject.$1,
        isPresent: isPresent,
        markedByFacultyName: subject.$2,
      ));

      dayIndex++;
    }

    // Most recent day first, matching how the prototype's log reads.
    return entries.reversed.toList();
  }
}
