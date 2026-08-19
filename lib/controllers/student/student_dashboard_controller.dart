import 'package:get/get.dart';
import '../../models/dashboard_list_item_model.dart';
import 'package:lms/models/student/course_progress_model.dart';
import 'package:lms/models/student/student_dashboard_stats_model.dart';
import 'package:lms/services/student/student_dashboard_service.dart';

/// Feeds the student dashboard's stats and lists - the student-side
/// equivalent of `FacultyDashboardController`.
class StudentDashboardController extends GetxController {
  final StudentDashboardService _service = StudentDashboardService();

  final RxBool isLoading = true.obs;

  final Rx<StudentDashboardStats?> stats = Rx<StudentDashboardStats?>(null);
  final RxList<DashboardListItem> todaysClassSchedule = <DashboardListItem>[].obs;
  final RxList<CourseProgressModel> courseProgress = <CourseProgressModel>[].obs;
  final RxList<DashboardListItem> pendingAssignments = <DashboardListItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Loads everything the dashboard needs, all at once. Kept as its
  /// own method so pull-to-refresh has something to call.
  Future<void> loadDashboardData() async {
    isLoading.value = true;

    final results = await Future.wait([
      _service.getStats(),
      _service.getTodaysClassSchedule(),
      _service.getCourseProgress(),
      _service.getPendingAssignments(),
    ]);

    stats.value = results[0] as StudentDashboardStats;
    todaysClassSchedule.assignAll(results[1] as List<DashboardListItem>);
    courseProgress.assignAll(results[2] as List<CourseProgressModel>);
    pendingAssignments.assignAll(results[3] as List<DashboardListItem>);

    isLoading.value = false;
  }
}
