import 'package:get/get.dart';
import '../../models/dashboard_list_item_model.dart';
import 'package:lms/models/faculty/live_class_model.dart';
import 'package:lms/models/faculty/submission_model.dart';
import 'package:lms/services/faculty/course_service.dart';
import 'faculty_assignment_controller.dart';
import 'faculty_attendance_controller.dart';
import 'faculty_course_controller.dart';

/// Feeds the faculty dashboard's stats and lists.
///
/// Almost nothing here is stored data of its own - instead, this
/// controller reads directly from the other faculty controllers
/// (Live Classes, Assignments, Attendance), which are the single
/// "source of truth" for that data. That's what makes the dashboard
/// stay dynamic: schedule a class on the Live Classes screen, or grade
/// a submission on the Assignments screen, and the dashboard reflects
/// it immediately - there's only ever one copy of the data, not a
/// separate snapshot that goes stale.
///
/// The one exception is `myStudentsCount`: there's no screen anywhere
/// in the app that changes how many students are enrolled, so that
/// number is loaded once from mock data and just stays as a reference
/// figure, same as it would from a real backend.
class FacultyDashboardController extends GetxController {
  final CourseService _courseService = CourseService();

  // `Get.find` hands back the same live controller instances the other
  // faculty screens use - `FacultyBinding` creates all of them together,
  // for every faculty route (including this dashboard).
  FacultyCourseController get _courseController => Get.find<FacultyCourseController>();
  FacultyAssignmentController get _assignmentController => Get.find<FacultyAssignmentController>();
  FacultyAttendanceController get _attendanceController => Get.find<FacultyAttendanceController>();

  final RxBool isLoading = true.obs;
  final RxInt myStudentsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Loads the one piece of data this controller actually owns. Kept
  /// as its own method so pull-to-refresh has something to call.
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    final courses = await _courseService.getMyCourses();
    myStudentsCount.value =
        courses.fold<int>(0, (sum, course) => sum + course.studentCount);
    isLoading.value = false;
  }

  // ---- Everything below is computed live from the other controllers ----

  int get classesTodayCount => _courseController.scheduledClasses.length;

  int get assignmentsToGradeCount => _assignmentController.activeSubmissions
      .where((submission) => submission.status == SubmissionStatus.pendingReview)
      .length;

  /// The percentage of students currently marked present in Manual
  /// attendance mode, as a number from 0 to 100.
  double get averageAttendance {
    final rows = _attendanceController.manualRows;
    if (rows.isEmpty) return 0;

    final presentCount = rows.where((row) => row.isPresent).length;
    return (presentCount / rows.length) * 100;
  }

  /// Every class that's been scheduled, shown in "Today's Schedule".
  List<DashboardListItem> get todaysSchedule {
    return _courseController.scheduledClasses.map((liveClass) {
      return DashboardListItem(
        title: liveClass.subject,
        subtitle: '${liveClass.batch} · ${liveClass.dateTimeText}',
        status: _listItemStatusFor(liveClass.status),
      );
    }).toList();
  }

  /// Submissions still waiting to be graded, shown in "Pending Grading".
  /// Shrinks in real time as submissions get graded on the Assignments
  /// screen.
  List<DashboardListItem> get pendingGrading {
    return _assignmentController.activeSubmissions
        .where((submission) => submission.status == SubmissionStatus.pendingReview)
        .map((submission) {
      return DashboardListItem(
        title: submission.studentName,
        subtitle: 'Wiring Diagram Submission · ${submission.fileName}',
        status: ListItemStatus.pending,
      );
    }).toList();
  }

  /// Submissions that have just been graded, shown in "Recent
  /// Submissions". Grows in real time as you grade more on the
  /// Assignments screen.
  List<DashboardListItem> get recentSubmissions {
    return _assignmentController.activeSubmissions
        .where((submission) => submission.status == SubmissionStatus.graded)
        .map((submission) {
      return DashboardListItem(
        title: submission.studentName,
        subtitle: 'Wiring Diagram Submission · Graded ${submission.marks}',
        status: ListItemStatus.done,
      );
    }).toList();
  }

  ListItemStatus _listItemStatusFor(LiveClassStatus status) {
    switch (status) {
      case LiveClassStatus.live:
        return ListItemStatus.live;
      case LiveClassStatus.upcoming:
        return ListItemStatus.upcoming;
      case LiveClassStatus.completed:
        return ListItemStatus.done;
    }
  }
}
