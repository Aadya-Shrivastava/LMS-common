import 'dart:async';
import 'package:get/get.dart';
import '../../core/network/saved_then_fresh.dart';
import '../../models/dashboard_list_item_model.dart';
import '../auth_controller.dart';
import 'package:lms/models/student/course_progress_model.dart';
import 'package:lms/models/student/student_dashboard_stats_model.dart';
import 'package:lms/services/student/student_dashboard_service.dart';

/// Feeds the student dashboard's stats and lists - the student-side
/// equivalent of `FacultyDashboardController`.
class StudentDashboardController extends GetxController {
  final StudentDashboardService _service = StudentDashboardService();

  final RxBool isLoading = true.obs;

  /// Set when loading failed, so the screen can show it with a retry
  /// button. Null when everything loaded fine.
  final RxnString errorMessage = RxnString();

  final Rx<StudentDashboardStats?> stats = Rx<StudentDashboardStats?>(null);
  final RxList<DashboardListItem> todaysClassSchedule = <DashboardListItem>[].obs;
  final RxList<CourseProgressModel> courseProgress = <CourseProgressModel>[].obs;
  final RxList<DashboardListItem> pendingAssignments = <DashboardListItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Loads everything the dashboard needs in one API call. Kept as its
  /// own method so pull-to-refresh has something to call.
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    errorMessage.value = null;

    errorMessage.value = await loadSavedThenFresh(_service.getDashboard, (data) {
      stats.value = data.stats;
      todaysClassSchedule.assignAll(data.todaysClassSchedule);
      courseProgress.assignAll(data.courseProgress);
      pendingAssignments.assignAll(data.pendingAssignments);
      isLoading.value = false;

      // The login API doesn't say who the student is, so fill in their
      // real name/course/batch from here.
      unawaited(Get.find<AuthController>().updateUserDetails(
        name: data.info.fullName,
        department: data.info.course,
        designation: data.info.batchText,
      ));
    });
    isLoading.value = false;
  }
}
