/// One student's row in the "Mark Attendance" list.
///
/// `isPresent` is not `final` - the attendance screen changes it
/// directly (by ticking the checkbox) and then tells its GetX list to
/// refresh, instead of rebuilding a whole new object every time.
class AttendanceRowModel {
  final String studentName;
  final String enrollmentNo;
  final int monthlyPercent;
  bool isPresent;

  AttendanceRowModel({
    required this.studentName,
    required this.enrollmentNo,
    required this.monthlyPercent,
    required this.isPresent,
  });
}
