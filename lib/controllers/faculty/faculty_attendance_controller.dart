import 'package:get/get.dart';
import 'package:lms/models/faculty/assignment_model.dart';
import 'package:lms/models/faculty/attendance_row_model.dart';
import 'package:lms/models/faculty/biometric_entry_model.dart';
import 'package:lms/models/faculty/qr_scan_entry_model.dart';
import 'package:lms/models/faculty/student_assignment_record_model.dart';
import 'package:lms/models/faculty/student_performance_model.dart';
import 'package:lms/services/faculty/attendance_service.dart';
import 'package:lms/services/faculty/performance_service.dart';

/// The three ways attendance can be taken, matching the tabs on the
/// Attendance screen.
enum AttendanceMode { manual, qrCode, biometric }

/// Holds the data for the faculty Attendance and Student Performance
/// screens.
class FacultyAttendanceController extends GetxController {
  final AttendanceService _attendanceService = AttendanceService();
  final PerformanceService _performanceService = PerformanceService();

  // ---- Attendance ----

  final RxBool isLoadingAttendance = true.obs;
  final Rx<AttendanceMode> selectedMode = AttendanceMode.manual.obs;

  /// Which date Manual mode is currently showing/editing - defaults to
  /// today, but the calendar on the Attendance screen can change this
  /// to look at (and edit) a previous day's attendance.
  final Rx<DateTime> selectedAttendanceDate = DateTime.now().obs;

  final RxList<AttendanceRowModel> manualRows = <AttendanceRowModel>[].obs;
  final RxList<QrScanEntryModel> qrScanLog = <QrScanEntryModel>[].obs;
  final RxList<BiometricEntryModel> biometricLog = <BiometricEntryModel>[].obs;

  // ---- Student Performance ----

  final RxBool isLoadingPerformance = true.obs;
  final RxString selectedPerformanceBatch = 'Batch A'.obs;
  final RxList<StudentPerformanceModel> performanceRows =
      <StudentPerformanceModel>[].obs;

  /// The assignment history shown on a single student's detail
  /// screen - only loaded once you open that screen.
  final RxBool isLoadingStudentAssignments = true.obs;
  final RxList<StudentAssignmentRecordModel> studentAssignmentRecords =
      <StudentAssignmentRecordModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAttendance();
    loadPerformance();
  }

  Future<void> loadAttendance() async {
    isLoadingAttendance.value = true;
    final results = await Future.wait([
      _attendanceService.getManualAttendanceRows(selectedAttendanceDate.value),
      _attendanceService.getQrScanLog(),
      _attendanceService.getBiometricLog(),
    ]);
    manualRows.assignAll(results[0] as List<AttendanceRowModel>);
    qrScanLog.assignAll(results[1] as List<QrScanEntryModel>);
    biometricLog.assignAll(results[2] as List<BiometricEntryModel>);
    isLoadingAttendance.value = false;
  }

  void selectMode(AttendanceMode mode) {
    selectedMode.value = mode;
  }

  /// Switches Manual mode to look at a different date, e.g. picking
  /// last Tuesday on the calendar - reloads that day's attendance so
  /// it can be reviewed or corrected.
  Future<void> selectAttendanceDate(DateTime date) async {
    selectedAttendanceDate.value = date;
    isLoadingAttendance.value = true;
    final rows = await _attendanceService.getManualAttendanceRows(date);
    manualRows.assignAll(rows);
    isLoadingAttendance.value = false;
  }

  /// Flips one student's present/absent checkbox in Manual mode.
  void toggleManualPresent(AttendanceRowModel row) {
    row.isPresent = !row.isPresent;
    manualRows.refresh();
  }

  /// Marks every student present in one tap - the faculty member can
  /// then untick anyone who's actually absent, instead of ticking
  /// everyone one by one.
  void markAllPresent() {
    for (final row in manualRows) {
      row.isPresent = true;
    }
    manualRows.refresh();
  }

  Future<void> loadPerformance() async {
    isLoadingPerformance.value = true;
    final rows = await _performanceService.getBatchPerformance(selectedPerformanceBatch.value);
    performanceRows.assignAll(rows);
    isLoadingPerformance.value = false;
  }

  /// Switches the Student Performance screen to a different batch,
  /// e.g. from "Batch A" to "Batch B", and reloads its students.
  Future<void> selectPerformanceBatch(String batch) async {
    if (batch == selectedPerformanceBatch.value) return;
    selectedPerformanceBatch.value = batch;
    await loadPerformance();
  }

  /// Saves the internal marks typed in for one student.
  void saveInternalMarksFor(StudentPerformanceModel row, String marks) {
    row.internalMarks = marks;
    performanceRows.refresh();
  }

  /// Loads one student's assignment history, for their detail screen.
  Future<void> loadAssignmentRecordsFor(String studentName) async {
    isLoadingStudentAssignments.value = true;
    final records = await _performanceService.getAssignmentRecordsFor(studentName);
    studentAssignmentRecords.assignAll(records);
    isLoadingStudentAssignments.value = false;
  }

  /// Saves the marks a faculty member enters while reviewing one of a
  /// student's assignments, and marks it as graded.
  void saveAssignmentRecordMarks(StudentAssignmentRecordModel record, String marks) {
    record.marks = marks;
    record.status = AssignmentStatus.graded;
    studentAssignmentRecords.refresh();
  }
}
