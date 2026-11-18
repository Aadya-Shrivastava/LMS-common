/// Every backend web address the app uses lives here.
///
/// Keeping all the URLs in one file means if the server address ever
/// changes, we only need to update `baseUrl` below instead of hunting
/// through every service in the app.
///
/// To add a new API, add its path as another `static const String`
/// below (always starting with `/api/` and ending with `/`), then use it
/// like `AppUrls.login` together with `ApiClient`.
///
/// The numbers in the comments ("API 7") match the backend team's
/// "Student Portal API" document (46 APIs, 23 October 2026).
///
/// Every API except Login and Password Reset needs the access token,
/// which `ApiClient` adds automatically. Keep the "/" at the end of
/// each path: without it the server redirects, and the redirect drops
/// the token, so the request fails with 401.
class AppUrls {
  // Private constructor so nobody can accidentally create an AppUrls object.
  // We only ever use the static values below, like AppUrls.login.
  AppUrls._();

  // ---- Server ----

  /// The main address of our backend. Every API path below is added
  /// on to the end of this.
  static const String baseUrl = 'https://api.mgbinstitute.in';

  // ---- Auth ----

  /// API 1 · POST — logs the user in. No access token needed.
  /// Body: { "identifier": "...", "password": "..." }
  /// Returns: `{ "access": "<access_token>", "refresh": "<refresh_token>" }`
  static const String login = '/api/auth/login/';

  /// API 2 · POST — emails a password-reset link. No access token
  /// needed. Body: `{ "email": "..." }`. The reply is the same whether
  /// or not the email is registered.
  static const String passwordReset = '/api/auth/password-reset/';

  /// POST — swaps the refresh token for new tokens when the access
  /// token expires. `ApiClient` calls this automatically.
  /// Body: { "refresh": "..." }
  static const String refreshToken = '/api/auth/refresh/';

  /// API 42 · PUT — changes the password and logs out every other device.
  /// Body: `{ "current_password", "new_password", "confirm_new_password" }`
  static const String changePassword = '/api/auth/change-password/';

  /// API 43 · GET — devices the user is logged in on.
  static const String activeSessions = '/api/auth/sessions/';

  /// API 44 · POST — logs out every other device, keeping this one.
  /// Body: `{ "refresh_token": "..." }`
  static const String logoutOtherSessions = '/api/auth/sessions/logout-all/';

  /// API 45 · POST — logs out on the server.
  /// Body: { "refresh_token": "..." }
  static const String logout = '/api/auth/logout/';

  // ---- Student ----

  /// API 3 · GET — home screen: student info, stats, today's classes,
  /// course progress, pending assignments.
  static const String studentDashboard = '/api/student/students/dashboard/';

  /// API 4 · GET — the student's full record, including the student id
  /// that other APIs (like the fee summary) need.
  static const String studentRecord = '/api/students/students/';

  /// API 5 · GET — personal and academic profile.
  static const String studentProfile = '/api/students/profile/';

  /// API 6 · POST — updates the student's own contact details.
  /// Body: any of `{ "mobile", "guardian_mobile", "address" }`.
  static const String updateProfile = '/api/student/profile/';

  // ---- Learning ----

  /// API 7 · GET — live classes for the student's batch.
  static const String liveClasses = '/api/learning/live-classes/';

  /// API 8 · GET — study materials for the student's batch.
  static const String studyMaterials = '/api/learning/study-materials/';

  /// API 9 · GET — video lessons (`video_link` / `video_file`).
  static const String videoLessons = '/api/academics/video-lessons/';

  /// API 10 · GET — PDF lessons (`pdf_file`).
  static const String pdfLessons = '/api/academics/pdf-lessons/';

  /// API 11 · GET — text lessons (`text_content`).
  static const String textLessons = '/api/academics/text-lessons/';

  /// API 12 · GET — image lessons (`image_file`).
  static const String imageLessons = '/api/academics/image-lessons/';

  /// API 13 · GET — presentation lessons (`slides_file`).
  static const String presentationLessons = '/api/academics/presentation-lessons/';

  /// API 14 · GET — multimedia lessons (`external_url`).
  static const String multimediaLessons = '/api/academics/multimedia-lessons/';

  /// API 15 · GET — download lessons (a `files` list per lesson).
  static const String downloadLessons = '/api/academics/download-lessons/';

  // ---- Timetable ----

  /// API 46 · GET — every timetable period for the student's batch.
  static const String timetableEntries = '/api/timetable/entries/';

  // ---- Assignments ----

  /// API 16 · GET — the student's assignments with submission status,
  /// marks and feedback.
  static const String myAssignments = '/api/assignments/assignments/student_assignments/';

  /// API 17 · GET — the student's submitted assignments.
  /// POST (form-data) — hands one in: `assignment` (the assignment id)
  /// and `file` (the student's file).
  static const String assignmentSubmissions = '/api/assignments/submissions/';

  // ---- Exams ----

  /// API 18 · GET — every online exam for the student's batch.
  static const String exams = '/api/exams/exams/';

  /// API 19 · GET — only the exams still to come.
  static const String upcomingExams = '/api/exams/exams/upcoming/';

  /// API 20 · GET — the student's exam attempts (score, timing, answers).
  static const String examAttempts = '/api/exams/attempts/';

  /// API 21 · GET — every answer the student submitted.
  static const String examAnswers = '/api/exams/answers/';

  /// API 22 · GET — finished exams with score and status.
  static const String examHistory = '/api/exams/attempts/history/';

  /// API 23 · GET — the campus grading scale (grade bands).
  static const String examGrades = '/api/exams/grades/';

  // ---- Attendance ----

  /// API 24 · GET — one record per marked class.
  static const String attendanceRecords = '/api/attendance/records/';

  /// API 25 · GET — the class happening right now and its status.
  static const String attendanceCurrentSession = '/api/attendance/records/current_session/';

  /// API 26 · GET — which weekdays are working days.
  static const String attendanceWorkingDays = '/api/attendance/working-days/';

  /// API 27 · GET — minimum attendance %, alert thresholds, etc.
  static const String attendanceRules = '/api/attendance/attendance-rules/';

  // ---- Fees ----

  /// API 28 · GET — every fee charged to the student.
  static const String studentFees = '/api/fees/student-fees/';

  /// API 29 · GET — payment receipts.
  static const String feePayments = '/api/fees/fee-payments/';

  /// API 30 · GET — each fee head paid inside a payment.
  static const String feePaymentItems = '/api/fees/fee-payment-items/';

  /// API 31 · GET — total / paid / due for one student. Needs the
  /// student id from API 4 (`studentRecord`).
  static String feeSummary(String studentId) => '/api/student/student/$studentId/fee_summary/';

  // ---- Certificates ----

  /// API 33 · GET — the student's certificate requests.
  /// API 32 · POST — asks for a new certificate.
  /// Body: `{ "certificate_type": "Course Completion" }`
  static const String certificateRequests = '/api/certificates/requests/';

  /// API 34 · POST — creates an issued-certificate record.
  /// Body: `{ "title": "...", "student": "<student id>" }`
  static const String issuedCertificates = '/api/certificates/issued/';

  /// API 35 · GET — the issued certificate as a rendered document
  /// (not JSON). `id` is the issued-certificate id from API 34.
  static String downloadIssuedCertificate(String id) => '/api/certificates/issued/$id/download/';

  // ---- Placements ----

  /// API 36 · GET — placement drives.
  static const String placementDrives = '/api/placements/placement-drives/';

  /// API 37 · GET — the student's placement applications.
  /// API 38 · POST — applies to a drive. Body: `{ "job": <drive id> }`
  static const String placementApplications = '/api/placements/applications/';

  /// API 39 · GET — students who have been placed.
  static const String placedStudents = '/api/placements/placed-students/';

  // ---- Communication ----

  /// API 40 · GET — notifications for the student.
  static const String notifications = '/api/communication/notifications/';

  /// API 41 · POST — marks every notification as read.
  static const String markAllNotificationsRead = '/api/communication/notifications/mark_all_read/';

  // ---- Helpers ----

  /// Joins `baseUrl` and an API path into a full web address, e.g.
  /// `AppUrls.full(AppUrls.login)` gives
  /// "https://api.mgbinstitute.in/api/auth/login/".
  static Uri full(String path) => Uri.parse('$baseUrl$path');
}
