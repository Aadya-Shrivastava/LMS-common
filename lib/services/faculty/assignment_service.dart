import 'package:lms/models/faculty/assignment_model.dart';
import 'package:lms/models/faculty/assignment_summary_model.dart';
import '../../models/dashboard_list_item_model.dart';
import 'package:lms/models/faculty/submission_model.dart';

/// Provides information about assignments: what's been given out,
/// what still needs grading, and what's recently been submitted.
class AssignmentService {
  /// The full list shown in the "All Assignments" table, on the main
  /// Assignments screen.
  Future<List<AssignmentSummaryModel>> getAssignmentSummaries() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      AssignmentSummaryModel(
        id: 'as1',
        title: 'Wiring Diagram Submission',
        batch: 'Batch A',
        dueDate: DateTime(2026, 8, 2),
        submittedCount: 28,
        totalCount: 42,
        status: AssignmentSummaryStatus.active,
      ),
      AssignmentSummaryModel(
        id: 'as2',
        title: 'Circuit Analysis Worksheet',
        batch: 'Batch A',
        dueDate: DateTime(2026, 7, 22),
        submittedCount: 42,
        totalCount: 42,
        status: AssignmentSummaryStatus.closed,
      ),
    ];
  }

  /// The full student roster for one batch - used to work out which
  /// students *haven't* submitted the active assignment yet, so they
  /// can be shown as "Missing" (or "Overdue") in the Submissions list.
  List<String> getBatchRoster(String batch) {
    switch (batch) {
      case 'Batch B':
        return ['Anjali Verma', 'Mohit Rana', 'Priya Nair'];
      case 'Batch A':
      default:
        return ['Rahul Sharma', 'Suman Nishad', 'Deepak Singh', 'Karan Mehta'];
    }
  }

  /// The per-student submissions for one assignment, so the faculty
  /// member can grade them - this is what's shown when the currently
  /// active assignment is "Wiring Diagram Submission".
  Future<List<SubmissionModel>> getSubmissionsForActiveAssignment() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      SubmissionModel(
        studentName: 'Rahul Sharma',
        studentInitials: 'RS',
        submittedAtText: '01 Aug, 08:40 AM',
        fileName: 'wiring_rahul.pdf',
        status: SubmissionStatus.pendingReview,
      ),
      SubmissionModel(
        studentName: 'Suman Nishad',
        studentInitials: 'SN',
        submittedAtText: '31 Jul, 06:20 PM',
        fileName: 'wiring_suman.pdf',
        status: SubmissionStatus.pendingReview,
      ),
      SubmissionModel(
        studentName: 'Deepak Singh',
        studentInitials: 'DS',
        submittedAtText: '29 Jul, 10:10 AM',
        fileName: 'wiring_deepak.pdf',
        status: SubmissionStatus.graded,
        marks: '18/20',
      ),
    ];
  }

  Future<List<AssignmentModel>> getAssignmentsToGrade() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      AssignmentModel(
        id: 'a1',
        title: 'Linked List Implementation',
        courseName: 'Data Structures',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        status: AssignmentStatus.submitted,
      ),
      AssignmentModel(
        id: 'a2',
        title: 'ER Diagram Assignment',
        courseName: 'Database Systems',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: AssignmentStatus.submitted,
      ),
    ];
  }

  /// Rows shown in the "Pending Grading" list on the faculty dashboard.
  Future<List<DashboardListItem>> getPendingGradingItems() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const [
      DashboardListItem(
        title: 'Linked List Implementation',
        subtitle: 'Data Structures • 24 submissions waiting',
        status: ListItemStatus.pending,
      ),
      DashboardListItem(
        title: 'ER Diagram Assignment',
        subtitle: 'Database Systems • 12 submissions waiting',
        status: ListItemStatus.pending,
      ),
      DashboardListItem(
        title: 'Process Scheduling Quiz',
        subtitle: 'Operating Systems • 5 submissions waiting',
        status: ListItemStatus.review,
      ),
    ];
  }

  /// Rows shown in the "Recent Submissions" list on the faculty dashboard.
  Future<List<DashboardListItem>> getRecentSubmissions() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const [
      DashboardListItem(
        title: 'Priya Nair',
        subtitle: 'Linked List Implementation • Submitted on time',
        status: ListItemStatus.done,
      ),
      DashboardListItem(
        title: 'Arjun Mehta',
        subtitle: 'ER Diagram Assignment • Submitted on time',
        status: ListItemStatus.done,
      ),
      DashboardListItem(
        title: 'Sara Khan',
        subtitle: 'Process Scheduling Quiz • Submitted late',
        status: ListItemStatus.review,
      ),
    ];
  }
}
