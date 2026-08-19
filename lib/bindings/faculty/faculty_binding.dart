import 'package:get/get.dart';
import '../../controllers/faculty/faculty_assignment_controller.dart';
import '../../controllers/faculty/faculty_attendance_controller.dart';
import '../../controllers/faculty/faculty_course_controller.dart';
import '../../controllers/faculty/faculty_dashboard_controller.dart';
import '../../controllers/faculty/faculty_notification_controller.dart';
import '../../controllers/faculty/faculty_profile_controller.dart';

/// Creates all the controllers needed by the faculty side of the app.
///
/// Just like StudentBinding, we use `Get.lazyPut` so each controller is
/// only created the first time its screen is actually opened.
class FacultyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FacultyDashboardController>(() => FacultyDashboardController());
    Get.lazyPut<FacultyCourseController>(() => FacultyCourseController());
    Get.lazyPut<FacultyAssignmentController>(() => FacultyAssignmentController());
    Get.lazyPut<FacultyAttendanceController>(() => FacultyAttendanceController());
    Get.lazyPut<FacultyProfileController>(() => FacultyProfileController());
    Get.lazyPut<FacultyNotificationController>(() => FacultyNotificationController());
  }
}
