import 'package:get/get.dart';
import '../../bindings/student/student_binding.dart';
import '../../screens/auth/forgot_password/forgot_password_screen.dart';
import '../../screens/auth/login/login_screen.dart';
import '../../screens/auth/splash/splash_screen.dart';
import '../../screens/student/assignments/student_assignments_screen.dart';
import '../../screens/student/assignments/student_exams_results_screen.dart';
import '../../screens/student/attendance/student_attendance_screen.dart';
// Self attendance is switched off for now (see the route below).
// import '../../screens/student/attendance/student_self_attendance_qr_screen.dart';
import '../../screens/student/courses/student_courses_screen.dart';
import '../../screens/student/courses/student_live_classes_screen.dart';
import '../../screens/student/courses/student_timetable_screen.dart';
import '../../screens/student/dashboard/student_dashboard_screen.dart';
import '../../screens/student/notifications/student_notifications_screen.dart';
import '../../screens/student/placements/student_placements_screen.dart';
import '../../screens/student/profile/student_account_settings_screen.dart';
import '../../screens/student/profile/student_certificates_screen.dart';
import '../../screens/student/profile/student_fees_screen.dart';
import '../../screens/student/profile/student_profile_screen.dart';
import 'app_routes.dart';

/// This is the app's "map": it connects every route name from
/// `app_routes.dart` to the actual screen widget that should be shown,
/// and to the binding that should prepare its controller(s) first.
///
/// `GetMaterialApp` reads this list once, and from then on we can
/// navigate anywhere in the app just by calling `Get.toNamed(...)`.
class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    // ---- Auth ----
    GetPage(name: Routes.splash, page: () => const SplashScreen()),
    GetPage(name: Routes.login, page: () => const LoginScreen()),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),

    // ---- Student ----
    GetPage(
      name: Routes.studentDashboard,
      page: () => const StudentDashboardScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentLiveClasses,
      page: () => const StudentLiveClassesScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentTimetable,
      page: () => const StudentTimetableScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentCourses,
      page: () => const StudentCoursesScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentAssignments,
      page: () => const StudentAssignmentsScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentExamsResults,
      page: () => const StudentExamsResultsScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentAttendance,
      page: () => const StudentAttendanceScreen(),
      binding: StudentBinding(),
    ),
    // Self attendance is switched off for now (no backend API yet).
    // GetPage(
    //   name: Routes.studentSelfAttendanceQr,
    //   page: () => const StudentSelfAttendanceQrScreen(),
    //   binding: StudentBinding(),
    // ),
    GetPage(
      name: Routes.studentFees,
      page: () => const StudentFeesScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentCertificates,
      page: () => const StudentCertificatesScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentPlacements,
      page: () => const StudentPlacementsScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentNotifications,
      page: () => const StudentNotificationsScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentProfile,
      page: () => const StudentProfileScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.studentAccountSettings,
      page: () => const StudentAccountSettingsScreen(),
      binding: StudentBinding(),
    ),

  ];
}