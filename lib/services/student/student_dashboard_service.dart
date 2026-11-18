import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/json_parsers.dart';
import '../../models/dashboard_list_item_model.dart';
import 'package:lms/models/student/course_progress_model.dart';
import 'package:lms/models/student/student_dashboard_stats_model.dart';

/// Who the student is, as sent by the dashboard API - used to fill in
/// the name/course/batch shown in the header and drawer.
class StudentDashboardInfo {
  final String fullName;
  final String course;
  final String batchText;

  const StudentDashboardInfo({
    required this.fullName,
    required this.course,
    required this.batchText,
  });
}

/// Everything the dashboard API sends back, already turned into the
/// models the dashboard screen uses.
class StudentDashboardData {
  final StudentDashboardInfo info;
  final StudentDashboardStats stats;
  final List<DashboardListItem> todaysClassSchedule;
  final List<CourseProgressModel> courseProgress;
  final List<DashboardListItem> pendingAssignments;

  const StudentDashboardData({
    required this.info,
    required this.stats,
    required this.todaysClassSchedule,
    required this.courseProgress,
    required this.pendingAssignments,
  });
}

/// Loads the student dashboard from `AppUrls.studentDashboard`.
class StudentDashboardService {
  final ApiClient _apiClient = ApiClient();

  Future<StudentDashboardData> getDashboard() async {
    final json = jsonMap(await _apiClient.get(AppUrls.studentDashboard));

    final info = jsonMap(json['student_info']);
    final stats = jsonMap(json['stats']);

    final batchParts = [
      jsonString(info['batch_name']),
      jsonString(info['semester_name']),
    ].where((part) => part.isNotEmpty);

    return StudentDashboardData(
      info: StudentDashboardInfo(
        fullName: '${jsonString(info['first_name'])} ${jsonString(info['last_name'])}'.trim(),
        course: jsonString(info['course_name']),
        batchText: batchParts.join(' · '),
      ),
      stats: StudentDashboardStats(
        attendancePercent: jsonDouble(stats['attendance_percentage']),
        assignmentsDoneText:
            '${jsonInt(stats['assignments_done'])}/${jsonInt(stats['assignments_total'])}',
        upcomingExamsCount: jsonInt(stats['upcoming_exams']),
        feeDueText: '₹${jsonDouble(stats['fee_due']).round()}',
      ),
      todaysClassSchedule: jsonList(json['today_classes']).map(_classItem).toList(),
      courseProgress: jsonList(json['course_progress'])
          .map((item) => CourseProgressModel(
                courseName: jsonString(item['subject']),
                percentComplete: jsonDouble(item['percentage']),
              ))
          .toList(),
      pendingAssignments: jsonList(json['pending_assignments'])
          .map((item) => DashboardListItem(
                title: jsonString(item['title']),
                subtitle: jsonString(item['status']),
                status: item['is_overdue'] == true
                    ? ListItemStatus.overdue
                    : ListItemStatus.upcoming,
              ))
          .toList(),
    );
  }

  /// One of today's classes. The API document doesn't show one, so the
  /// field names follow the live-classes API, which is the same data.
  DashboardListItem _classItem(Map<String, dynamic> item) {
    final title = [item['subject_name'], item['subject'], item['topic']]
        .map(jsonString)
        .firstWhere((text) => text.isNotEmpty, orElse: () => 'Class');

    final time = formatTimeText(jsonString(item['start_time'] ?? item['time']));
    final faculty = jsonString(item['faculty_name'] ?? item['faculty']);

    final status = jsonString(item['status']).toLowerCase();

    return DashboardListItem(
      title: title,
      subtitle: [time, faculty].where((part) => part.isNotEmpty).join(' · '),
      status: status == 'live' || status == 'ongoing'
          ? ListItemStatus.live
          : status == 'completed'
              ? ListItemStatus.done
              : ListItemStatus.upcoming,
    );
  }
}
