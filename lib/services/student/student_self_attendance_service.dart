import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/self_attendance_model.dart';

/// Provides the current live class (API 25) and the student's
/// self-marked attendance log (still sample data - the API document
/// has no self-attendance log or "mark attendance" API).
class StudentSelfAttendanceService {
  final ApiClient _apiClient = ApiClient();

  /// The class happening right now, or null when there's none (the
  /// API says "No Class" outside class hours) or it can't be loaded.
  Future<CurrentSessionModel?> getCurrentSession() async {
    final Map<String, dynamic> json;
    try {
      json = jsonMap(await _apiClient.get(AppUrls.attendanceCurrentSession));
    } on ApiException {
      return null;
    }

    final status = jsonString(json['status']);
    if (json.isEmpty || status.toLowerCase() == 'no class') return null;

    // "Electricak - BATCH A" -> subject "Electricak", batch "BATCH A".
    final sessionName = jsonString(json['session_name']);
    final split = sessionName.lastIndexOf(' - ');
    final timeWindow = jsonString(json['time_window']);

    return CurrentSessionModel(
      subject: split == -1 ? sessionName : sessionName.substring(0, split),
      batch: split == -1 ? '' : sessionName.substring(split + 3),
      facultyName: jsonString(json['faculty_name']),
      timeRange: timeWindow.toUpperCase() == 'N/A' ? '' : timeWindow,
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
