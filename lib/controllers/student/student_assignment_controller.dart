import 'package:get/get.dart';
import 'package:lms/models/student/student_assignment_model.dart';
import 'package:lms/services/student/student_assignment_service.dart';

/// The 4 filter cards at the top of the Assignments screen.
enum StudentAssignmentFilter { total, submitted, pending, overdue }

/// Holds the student's assignment list, plus which filter card is
/// currently selected.
class StudentAssignmentController extends GetxController {
  final StudentAssignmentService _service = StudentAssignmentService();

  final RxBool isLoading = true.obs;
  final RxList<StudentAssignmentModel> assignments = <StudentAssignmentModel>[].obs;
  final Rx<StudentAssignmentFilter> activeFilter = StudentAssignmentFilter.total.obs;

  int get totalCount => assignments.length;

  int get submittedCount =>
      assignments.where((a) => a.status == StudentAssignmentStatus.graded).length;

  int get pendingCount =>
      assignments.where((a) => a.status == StudentAssignmentStatus.pending && !a.isOverdue).length;

  int get overdueCount => assignments.where((a) => a.isOverdue).length;

  /// The list after the currently-selected filter card is applied.
  List<StudentAssignmentModel> get filteredAssignments {
    switch (activeFilter.value) {
      case StudentAssignmentFilter.total:
        return assignments;
      case StudentAssignmentFilter.submitted:
        return assignments.where((a) => a.status == StudentAssignmentStatus.graded).toList();
      case StudentAssignmentFilter.pending:
        return assignments
            .where((a) => a.status == StudentAssignmentStatus.pending && !a.isOverdue)
            .toList();
      case StudentAssignmentFilter.overdue:
        return assignments.where((a) => a.isOverdue).toList();
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadAssignments();
  }

  Future<void> loadAssignments() async {
    isLoading.value = true;
    final items = await _service.getAssignments();
    assignments.assignAll(items);
    isLoading.value = false;
  }

  void selectFilter(StudentAssignmentFilter filter) {
    activeFilter.value = filter;
  }
}
