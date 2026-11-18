import 'package:get/get.dart';
import '../../controllers/student/student_assignment_controller.dart';
import '../../controllers/student/student_attendance_controller.dart';
import '../../controllers/student/student_certificate_controller.dart';
import '../../controllers/student/student_course_controller.dart';
import '../../controllers/student/student_dashboard_controller.dart';
import '../../controllers/student/student_exam_controller.dart';
import '../../controllers/student/student_fee_controller.dart';
import '../../controllers/student/student_notification_controller.dart';
import '../../controllers/student/student_placement_controller.dart';
import '../../controllers/student/student_profile_controller.dart';
// Self attendance is switched off for now.
// import '../../controllers/student/student_self_attendance_controller.dart';

/// Creates all the controllers needed by the student side of the app.
///
/// We use `Get.lazyPut` instead of `Get.put`, which means each
/// controller is only actually created the first time its screen is
/// opened, instead of all at once when the app starts.
class StudentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentDashboardController>(() => StudentDashboardController());
    Get.lazyPut<StudentCourseController>(() => StudentCourseController());
    Get.lazyPut<StudentAssignmentController>(() => StudentAssignmentController());
    Get.lazyPut<StudentExamController>(() => StudentExamController());
    Get.lazyPut<StudentAttendanceController>(() => StudentAttendanceController());
    // Get.lazyPut<StudentSelfAttendanceController>(() => StudentSelfAttendanceController());
    Get.lazyPut<StudentFeeController>(() => StudentFeeController());
    Get.lazyPut<StudentCertificateController>(() => StudentCertificateController());
    Get.lazyPut<StudentProfileController>(() => StudentProfileController());
    Get.lazyPut<StudentNotificationController>(() => StudentNotificationController());
    Get.lazyPut<StudentPlacementController>(() => StudentPlacementController());
  }
}
