import 'package:get/get.dart';
import '../../core/network/saved_then_fresh.dart';
import 'package:lms/models/student/attendance_log_entry_model.dart';
import 'package:lms/models/student/attendance_settings_model.dart';
import 'package:lms/models/student/subject_attendance_model.dart';
import 'package:lms/services/student/student_attendance_service.dart';

/// The 4 filter cards above the Attendance screen's content. The
/// first 3 filter the attendance log by status; `subjectWise` swaps
/// the log out for the subject-wise breakdown instead.
enum AttendanceFilter { overall, present, absent, subjectWise }

/// Holds the student's attendance data - the full daily log and a
/// subject-wise breakdown - plus which filter and which month/day are
/// currently selected.
class StudentAttendanceController extends GetxController {
  final StudentAttendanceService _service = StudentAttendanceService();

  final RxBool isLoading = true.obs;
  final RxList<SubjectAttendanceModel> subjectWiseAttendance = <SubjectAttendanceModel>[].obs;
  final RxList<AttendanceLogEntryModel> attendanceLog = <AttendanceLogEntryModel>[].obs;
  final RxList<WorkingDayModel> workingDays = <WorkingDayModel>[].obs;
  final Rx<AttendanceRulesModel?> rules = Rx<AttendanceRulesModel?>(null);

  final RxnString errorMessage = RxnString();

  /// True once the data has loaded at least once, so a failed refresh
  /// keeps showing the old data instead of an error page.
  bool hasLoaded = false;

  /// The minimum attendance % the campus requires. Falls back to 75%,
  /// the usual shortage threshold, if the campus hasn't set one.
  double get minRequiredPercent {
    final value = rules.value?.minRequiredPercent ?? 0;
    return value > 0 ? value : 75;
  }

  final Rx<AttendanceFilter> activeFilter = AttendanceFilter.overall.obs;

  /// The month currently shown, always normalized to the 1st of that
  /// month. Defaults to the current month.
  final Rx<DateTime> selectedMonth = Rx<DateTime>(_firstOfCurrentMonth());

  /// The exact day picked from the date picker, or null if the student
  /// hasn't narrowed down to one specific day.
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  /// The last 6 months (oldest first, ending at the current month) -
  /// what the sliding month picker shows.
  List<DateTime> get availableMonths {
    final now = DateTime.now();
    return List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
  }

  /// The log narrowed down to the selected month, the selected status
  /// filter, and (if picked) the exact selected day.
  List<AttendanceLogEntryModel> get filteredLog {
    return attendanceLog.where((entry) {
      final matchesMonth =
          entry.date.year == selectedMonth.value.year &&
          entry.date.month == selectedMonth.value.month;

      final matchesFilter = switch (activeFilter.value) {
        AttendanceFilter.present => entry.isPresent,
        AttendanceFilter.absent => !entry.isPresent,
        AttendanceFilter.overall || AttendanceFilter.subjectWise => true,
      };

      final date = selectedDate.value;
      final matchesDate = date == null || _isSameDay(entry.date, date);

      return matchesMonth && matchesFilter && matchesDate;
    }).toList();
  }

  /// Every log entry in the selected month, ignoring the status
  /// filter - used to compute the Overall/Present/Absent card values,
  /// so those numbers always describe "this month" regardless of
  /// which card happens to be selected.
  List<AttendanceLogEntryModel> get _selectedMonthEntries {
    return attendanceLog
        .where((entry) =>
            entry.date.year == selectedMonth.value.year &&
            entry.date.month == selectedMonth.value.month)
        .toList();
  }

  int get presentCountForSelectedMonth =>
      _selectedMonthEntries.where((entry) => entry.isPresent).length;

  int get absentCountForSelectedMonth =>
      _selectedMonthEntries.where((entry) => !entry.isPresent).length;

  int get overallPercentForSelectedMonth {
    final total = _selectedMonthEntries.length;
    if (total == 0) return 0;
    return ((presentCountForSelectedMonth / total) * 100).round();
  }

  /// The selected month's entries grouped by day-of-month - what the
  /// attendance calendar uses to color each day.
  Map<int, List<AttendanceLogEntryModel>> get entriesByDayForSelectedMonth {
    final map = <int, List<AttendanceLogEntryModel>>{};
    for (final entry in _selectedMonthEntries) {
      map.putIfAbsent(entry.date.day, () => []).add(entry);
    }
    return map;
  }

  /// Tapping a calendar day narrows the log to it; tapping the same
  /// day again clears that pick.
  void toggleDate(DateTime day) {
    final current = selectedDate.value;
    if (current != null && _isSameDay(current, day)) {
      clearSelectedDate();
    } else {
      selectDate(day);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void onInit() {
    super.onInit();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    isLoading.value = true;
    errorMessage.value = null;

    errorMessage.value = await loadSavedThenFresh(
      () => Future.wait([
        _service.getAttendanceLog(),
        _service.getWorkingDays(),
        _service.getRules(),
      ]),
      (results) {
        final log = results[0] as List<AttendanceLogEntryModel>;
        attendanceLog.assignAll(log);
        subjectWiseAttendance.assignAll(_service.subjectWiseFromLog(log));
        workingDays.assignAll(results[1] as List<WorkingDayModel>);
        rules.value = results[2] as AttendanceRulesModel?;
        hasLoaded = true;
        isLoading.value = false;
      },
    );
    isLoading.value = false;
  }

  void selectFilter(AttendanceFilter filter) {
    activeFilter.value = filter;
  }

  /// Switches the month shown by the log/stat cards. Clears any exact
  /// day pick, since that day likely belonged to a different month.
  void selectMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month, 1);
    selectedDate.value = null;
  }

  /// Picks one exact day from the date picker - also moves the month
  /// picker to match, so the two stay in sync.
  void selectDate(DateTime day) {
    selectedDate.value = day;
    selectedMonth.value = DateTime(day.year, day.month, 1);
  }

  /// Clears the picked day, so the log goes back to showing the whole
  /// selected month.
  void clearSelectedDate() {
    selectedDate.value = null;
  }
}

DateTime _firstOfCurrentMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}
