import 'package:lms/models/faculty/attendance_row_model.dart';
import 'package:lms/models/faculty/biometric_entry_model.dart';
import 'package:lms/models/faculty/qr_scan_entry_model.dart';

/// Provides attendance information for students and courses.
class AttendanceService {
  /// The student list shown in "Manual" attendance mode, with a
  /// checkbox each faculty member ticks to mark someone present - for
  /// one specific date, so picking a different date on the calendar
  /// shows that day's attendance instead of always showing today's.
  ///
  /// There's no backend to remember real attendance history, so who
  /// was present "on" a given date is faked from the date itself (a
  /// simple formula based on the day number) - just enough to make
  /// picking different dates visibly show different data.
  Future<List<AttendanceRowModel>> getManualAttendanceRows(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // A tiny deterministic "was this student present" formula, so the
    // same date always gives the same answer, but different dates give
    // different answers.
    bool wasPresent(int studentSeed) => (date.day + studentSeed) % 4 != 0;

    return [
      AttendanceRowModel(
        studentName: 'Rahul Sharma',
        enrollmentNo: 'ENR-2026-0451',
        monthlyPercent: 92,
        isPresent: wasPresent(0),
      ),
      AttendanceRowModel(
        studentName: 'Suman Nishad',
        enrollmentNo: 'ENR-2026-0454',
        monthlyPercent: 76,
        isPresent: wasPresent(1),
      ),
      AttendanceRowModel(
        studentName: 'Deepak Singh',
        enrollmentNo: 'ENR-2026-0410',
        monthlyPercent: 88,
        isPresent: wasPresent(2),
      ),
      AttendanceRowModel(
        studentName: 'Karan Mehta',
        enrollmentNo: 'ENR-2026-0398',
        monthlyPercent: 95,
        isPresent: wasPresent(3),
      ),
    ];
  }

  /// The live scan log shown in "QR Code" attendance mode.
  Future<List<QrScanEntryModel>> getQrScanLog() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      QrScanEntryModel(
        studentName: 'Rahul Sharma',
        studentInitials: 'RS',
        scannedAtText: '09:01 AM',
        status: 'Present',
      ),
      QrScanEntryModel(
        studentName: 'Karan Mehta',
        studentInitials: 'KM',
        scannedAtText: '09:02 AM',
        status: 'Present',
      ),
      QrScanEntryModel(
        studentName: 'Deepak Singh',
        studentInitials: 'DS',
        scannedAtText: '09:04 AM',
        status: 'Late',
      ),
      QrScanEntryModel(
        studentName: 'Suman Nishad',
        studentInitials: 'SN',
        scannedAtText: '-',
        status: 'Not Scanned',
      ),
    ];
  }

  /// The sync log shown in "Biometric" attendance mode.
  Future<List<BiometricEntryModel>> getBiometricLog() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      BiometricEntryModel(
        studentName: 'Rahul Sharma',
        punchTimeText: '08:59 AM',
        matchStatus: 'Matched',
        attendanceStatus: 'Present',
      ),
      BiometricEntryModel(
        studentName: 'Karan Mehta',
        punchTimeText: '09:00 AM',
        matchStatus: 'Matched',
        attendanceStatus: 'Present',
      ),
      BiometricEntryModel(
        studentName: 'Unregistered ID #4471',
        punchTimeText: '09:03 AM',
        matchStatus: 'Unmatched',
        attendanceStatus: 'Needs review',
      ),
      BiometricEntryModel(
        studentName: 'Suman Nishad',
        punchTimeText: '-',
        matchStatus: 'No Punch',
        attendanceStatus: 'Absent',
      ),
    ];
  }
}
