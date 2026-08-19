import '../../models/dashboard_list_item_model.dart';
import 'package:lms/models/student/course_progress_model.dart';
import 'package:lms/models/student/student_dashboard_stats_model.dart';

/// Provides everything shown on the student dashboard: the headline
/// stats, today's class schedule, course progress, and pending
/// assignments.
class StudentDashboardService {
  Future<StudentDashboardStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const StudentDashboardStats(
      attendancePercent: 92,
      assignmentsDoneText: '6/8',
      upcomingExamsCount: 2,
      feeDueText: '₹3,000',
    );
  }

  /// Shown in "Today's Class Schedule".
  Future<List<DashboardListItem>> getTodaysClassSchedule() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      DashboardListItem(
        title: 'Basic Electrical Wiring',
        subtitle: '09:00 AM · Er. R. Kumar',
        status: ListItemStatus.live,
      ),
      DashboardListItem(
        title: 'Workshop Safety',
        subtitle: '11:00 AM · S. Pandey',
        status: ListItemStatus.upcoming,
      ),
      DashboardListItem(
        title: 'Employability Skills',
        subtitle: '02:00 PM · N. Singh',
        status: ListItemStatus.upcoming,
      ),
    ];
  }

  /// Shown in "Course Progress" - how far through each course the
  /// student is, as a percentage.
  Future<List<CourseProgressModel>> getCourseProgress() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      CourseProgressModel(courseName: 'Basic Electrical Wiring', percentComplete: 72),
      CourseProgressModel(courseName: 'Workshop Safety', percentComplete: 60),
      CourseProgressModel(courseName: 'Employability Skills', percentComplete: 90),
    ];
  }

  /// Shown in "Pending Assignments".
  Future<List<DashboardListItem>> getPendingAssignments() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      DashboardListItem(
        title: 'Wiring Diagram Submission',
        subtitle: 'Basic Electrical Wiring',
        status: ListItemStatus.upcoming,
      ),
      DashboardListItem(
        title: 'Safety Protocol Report',
        subtitle: 'Workshop Safety',
        status: ListItemStatus.overdue,
      ),
    ];
  }
}
