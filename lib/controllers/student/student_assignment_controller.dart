import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/network/saved_then_fresh.dart';
import 'package:lms/models/student/student_assignment_model.dart';
import 'package:lms/services/student/student_assignment_service.dart';

/// The 4 filter cards at the top of the Assignments screen.
enum StudentAssignmentFilter { total, submitted, pending, overdue }

/// Holds the student's assignment list, plus which filter card is
/// currently selected.
class StudentAssignmentController extends GetxController {
  final StudentAssignmentService _service = StudentAssignmentService();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  /// True once the list has loaded at least once, so a failed refresh
  /// keeps showing the old list instead of an error page.
  bool hasLoaded = false;

  final RxList<StudentAssignmentModel> assignments = <StudentAssignmentModel>[].obs;
  final Rx<StudentAssignmentFilter> activeFilter = StudentAssignmentFilter.total.obs;

  int get totalCount => assignments.length;

  int get submittedCount =>
      assignments.where((a) => a.isDone).length;

  int get pendingCount =>
      assignments.where((a) => a.status == StudentAssignmentStatus.pending && !a.isOverdue).length;

  int get overdueCount => assignments.where((a) => a.isOverdue).length;

  /// The list after the currently-selected filter card is applied.
  List<StudentAssignmentModel> get filteredAssignments {
    switch (activeFilter.value) {
      case StudentAssignmentFilter.total:
        return assignments;
      case StudentAssignmentFilter.submitted:
        return assignments.where((a) => a.isDone).toList();
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
    errorMessage.value = null;

    errorMessage.value = await loadSavedThenFresh(_service.getAssignments, (data) {
      assignments.assignAll(data);
      hasLoaded = true;
      isLoading.value = false;
    });
    isLoading.value = false;
  }

  /// Uploads the student's file for `assignment`, then reloads the list
  /// so it shows as submitted. Returns an error message, or null if it
  /// worked.
  Future<String?> submitAssignment(
    StudentAssignmentModel assignment, {
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      await _service.submitAssignment(
        assignmentId: assignment.id,
        fileBytes: fileBytes,
        fileName: fileName,
      );
    } catch (e) {
      return ApiClient.messageFor(e);
    }
    await loadAssignments();
    return null;
  }

  void selectFilter(StudentAssignmentFilter filter) {
    activeFilter.value = filter;
  }
}
