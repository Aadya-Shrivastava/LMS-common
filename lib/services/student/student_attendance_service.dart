import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/attendance_log_entry_model.dart';
import 'package:lms/models/student/attendance_settings_model.dart';
import 'package:lms/models/student/subject_attendance_model.dart';

/// Loads the student's attendance records, the campus working days,
/// and the attendance rules.
class StudentAttendanceService {
  final ApiClient _apiClient = ApiClient();

  /// Every class the student was marked present/absent for, most
  /// recent first. From `AppUrls.attendanceRecords`.
  Future<List<AttendanceLogEntryModel>> getAttendanceLog() async {
    final items = jsonList(await _apiClient.get(AppUrls.attendanceRecords));

    final entries = <AttendanceLogEntryModel>[];
    for (final item in items) {
      final date = jsonDate(item['date']);
      if (date == null) continue;

      final status = jsonString(item['status']).toLowerCase();

      entries.add(AttendanceLogEntryModel(
        date: date,
        subject: jsonString(item['subject_name']),
        // A late arrival still counts as attending the class.
        isPresent: status == 'present' || status == 'late',
        // The live API sends "marked_by_name"; the API document shows
        // the name in "marked_by" instead (elsewhere that's an id).
        markedByFacultyName: jsonString(item['marked_by_name']).isNotEmpty
            ? jsonString(item['marked_by_name'])
            : _nameOrEmpty(jsonString(item['marked_by'])),
      ));
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Hides values that are ids (UUIDs) rather than names.
  String _nameOrEmpty(String value) {
    final looksLikeId = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(value);
    return looksLikeId ? '' : value;
  }

  /// Works out each subject's attendance % from the log. There's no
  /// separate API for this, so we count it ourselves.
  List<SubjectAttendanceModel> subjectWiseFromLog(List<AttendanceLogEntryModel> log) {
    final totals = <String, (int present, int total)>{};

    for (final entry in log) {
      final current = totals[entry.subject] ?? (0, 0);
      totals[entry.subject] = (current.$1 + (entry.isPresent ? 1 : 0), current.$2 + 1);
    }

    return [
      for (final MapEntry(key: subject, value: counts) in totals.entries)
        SubjectAttendanceModel(subject: subject, percent: counts.$1 / counts.$2 * 100),
    ];
  }

  /// From `AppUrls.attendanceWorkingDays`.
  Future<List<WorkingDayModel>> getWorkingDays() async {
    final items = jsonList(await _apiClient.get(AppUrls.attendanceWorkingDays));

    return items
        .map((item) => WorkingDayModel(
              day: jsonString(item['day']),
              status: jsonString(item['status']),
              shift: jsonString(item['applicable_shift']),
            ))
        .toList();
  }

  /// From `AppUrls.attendanceRules`. The API sends a list with one
  /// rule set per campus; the student only sees their own campus's, so
  /// we take the first. Null if none is set up.
  Future<AttendanceRulesModel?> getRules() async {
    final items = jsonList(await _apiClient.get(AppUrls.attendanceRules));
    if (items.isEmpty) return null;

    final rules = items.first;
    return AttendanceRulesModel(
      minRequiredPercent: jsonDouble(rules['min_required_attendance_pct']),
      lowAlertPercent: jsonDouble(rules['low_attendance_alert_threshold_pct']),
      examLockPercent: jsonDouble(rules['exam_eligibility_lock_below_pct']),
      lateGraceMinutes: jsonInt(rules['late_checkin_grace_period_mins']),
    );
  }
}
