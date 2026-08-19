/// This file lists every "address" (route) in the app as a simple constant.
///
/// Instead of typing the route name as a plain string everywhere (which is
/// easy to misspell), we type `Routes.login` and let the IDE autocomplete it.
class Routes {
  Routes._();

  // ---- Auth ----
  static const String splash = '/splash';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // ---- Student ----
  static const String studentDashboard = '/student/dashboard';
  static const String studentLiveClasses = '/student/live-classes';
  static const String studentTimetable = '/student/timetable';
  static const String studentCourses = '/student/courses';
  static const String studentAssignments = '/student/assignments';
  static const String studentExamsResults = '/student/exams-results';
  static const String studentAttendance = '/student/attendance';
  static const String studentSelfAttendanceQr = '/student/self-attendance-qr';
  static const String studentFees = '/student/fees';
  static const String studentCertificates = '/student/certificates';
  static const String studentNotifications = '/student/notifications';
  static const String studentProfile = '/student/profile';

  // ---- Faculty ----
  static const String facultyDashboard = '/faculty/dashboard';
  static const String facultyLiveClasses = '/faculty/live-classes';
  static const String facultyTimetable = '/faculty/timetable';
  static const String facultyStudyMaterial = '/faculty/study-material';
  static const String facultyAssignments = '/faculty/assignments';
  static const String facultyQuestionBank = '/faculty/question-bank';
  static const String facultyAttendance = '/faculty/attendance';
  static const String facultyStudentPerformance =
      '/faculty/student-performance';
  static const String facultyStudentDetail = '/faculty/student-detail';
  static const String facultyAccountSettings = '/faculty/account-settings';
  static const String facultyNotifications = '/faculty/notifications';
}
