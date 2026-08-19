import 'package:get/get.dart';
import 'package:lms/models/student/self_attendance_model.dart';
import 'package:lms/services/student/student_self_attendance_service.dart';

/// The filter cards above the "History" tab's log.
enum SelfAttendanceFilter { all, present, notMarked }

/// Holds the current live session (if any) and the student's
/// self-marked attendance log, and lets the student mark their own
/// attendance via QR code or app location.
///
/// Also holds which filter, month, and (optionally) exact day are
/// currently selected on the History tab.
class StudentSelfAttendanceController extends GetxController {
  final StudentSelfAttendanceService _service = StudentSelfAttendanceService();

  final RxBool isLoading = true.obs;
  final Rx<CurrentSessionModel?> currentSession = Rx<CurrentSessionModel?>(null);
  final RxList<SelfAttendanceLogEntryModel> selfAttendanceLog =
      <SelfAttendanceLogEntryModel>[].obs;

  final Rx<SelfAttendanceFilter> activeFilter = SelfAttendanceFilter.all.obs;

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
  List<SelfAttendanceLogEntryModel> get filteredLog {
    return selfAttendanceLog.where((entry) {
      final matchesMonth =
          entry.date.year == selectedMonth.value.year &&
          entry.date.month == selectedMonth.value.month;

      final matchesFilter = switch (activeFilter.value) {
        SelfAttendanceFilter.present => entry.isPresent,
        SelfAttendanceFilter.notMarked => !entry.isPresent,
        SelfAttendanceFilter.all => true,
      };

      final date = selectedDate.value;
      final matchesDate = date == null || _isSameDay(entry.date, date);

      return matchesMonth && matchesFilter && matchesDate;
    }).toList();
  }

  /// Every log entry in the selected month, ignoring the status
  /// filter - used to compute the filter cards' own numbers, so they
  /// always describe "this month" regardless of which one is selected.
  List<SelfAttendanceLogEntryModel> get _selectedMonthEntries {
    return selfAttendanceLog
        .where((entry) =>
            entry.date.year == selectedMonth.value.year &&
            entry.date.month == selectedMonth.value.month)
        .toList();
  }

  int get allCountForSelectedMonth => _selectedMonthEntries.length;

  int get presentCountForSelectedMonth =>
      _selectedMonthEntries.where((entry) => entry.isPresent).length;

  int get notMarkedCountForSelectedMonth =>
      _selectedMonthEntries.where((entry) => !entry.isPresent).length;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void onInit() {
    super.onInit();
    loadSelfAttendance();
  }

  Future<void> loadSelfAttendance() async {
    isLoading.value = true;

    final results = await Future.wait([
      _service.getCurrentSession(),
      _service.getSelfAttendanceLog(),
    ]);

    currentSession.value = results[0] as CurrentSessionModel?;
    selfAttendanceLog.assignAll(results[1] as List<SelfAttendanceLogEntryModel>);

    isLoading.value = false;
  }

  /// Marks attendance for the current session using the given mode,
  /// and adds a new row to the top of the log - there's no real
  /// backend yet, so this is a local-only mock mark.
  void markCurrentSession(SelfAttendanceMode mode) {
    final session = currentSession.value;
    if (session == null) return;

    selfAttendanceLog.insert(
      0,
      SelfAttendanceLogEntryModel(
        date: DateTime.now(),
        subject: session.subject,
        mode: mode,
        timeText: _timeNowText(),
        isPresent: true,
      ),
    );
  }

  String _timeNowText() {
    final now = DateTime.now();
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  void selectFilter(SelfAttendanceFilter filter) {
    activeFilter.value = filter;
  }

  /// Switches the month shown by the log/filter cards. Clears any
  /// exact day pick, since that day likely belonged to a different month.
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
