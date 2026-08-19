import '../../models/dashboard_list_item_model.dart';
import '../../models/faculty/course_model.dart';

/// Provides information about courses and class schedules.
///
/// For now every method below returns fake ("mock") data after a short
/// delay, so the app feels realistic even without a real backend.
class CourseService {
  Future<List<CourseModel>> getMyCourses() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const [
      CourseModel(
        id: 'c1',
        name: 'Data Structures',
        code: 'CS201',
        studentCount: 62,
      ),
      CourseModel(
        id: 'c2',
        name: 'Database Systems',
        code: 'CS305',
        studentCount: 48,
      ),
      CourseModel(
        id: 'c3',
        name: 'Operating Systems',
        code: 'CS310',
        studentCount: 38,
      ),
    ];
  }

  /// Returns the list of classes happening today, used by the
  /// "Today's Schedule" section on the faculty dashboard.
  Future<List<DashboardListItem>> getTodaysSchedule() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const [
      // We don't repeat "Live"/"Upcoming" in the subtitle text - the
      // colored status chip next to each row already says that.
      DashboardListItem(
        title: 'Data Structures - CS201',
        subtitle: '10:00 AM · Room 204',
        status: ListItemStatus.live,
      ),
      DashboardListItem(
        title: 'Database Systems - CS305',
        subtitle: '1:00 PM · Room 108',
        status: ListItemStatus.upcoming,
      ),
      DashboardListItem(
        title: 'Operating Systems - CS310',
        subtitle: '3:00 PM · Room 210',
        status: ListItemStatus.upcoming,
      ),
    ];
  }
}
