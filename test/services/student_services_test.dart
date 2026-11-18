// Tests that every student service turns the backend's replies (the
// fixtures in test/fixtures/) into the right values for the screens.
//
// If the backend renames or changes a field, the matching test here
// fails instead of a screen quietly going blank.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lms/core/constants/app_urls.dart';
import 'package:lms/core/network/api_client.dart';
import 'package:lms/services/auth_service.dart';
import 'package:lms/services/student/student_self_attendance_service.dart';
import 'package:lms/models/dashboard_list_item_model.dart';
import 'package:lms/models/student/certificate_model.dart';
import 'package:lms/models/student/student_assignment_model.dart';
import 'package:lms/models/student/student_class_schedule_model.dart';
import 'package:lms/models/student/student_study_material_model.dart';
import 'package:lms/services/student/student_assignment_service.dart';
import 'package:lms/services/student/student_attendance_service.dart';
import 'package:lms/services/student/student_certificate_service.dart';
import 'package:lms/services/student/student_course_service.dart';
import 'package:lms/services/student/student_dashboard_service.dart';
import 'package:lms/services/student/student_exam_service.dart';
import 'package:lms/services/student/student_fee_service.dart';
import 'package:lms/services/student/student_notification_service.dart';
import 'package:lms/services/student/student_placement_service.dart';
import 'package:lms/services/student/student_profile_service.dart';
import 'package:lms/services/student/student_record_service.dart';

import '../helpers/fake_server.dart';

/// Runs `body` against the fake backend.
Future<T> api<T>(Future<T> Function() body) => withServer(fakeServer(), body);

void main() {
  setUp(resetApiState);

  test('dashboard (API 2)', () async {
    final data = await api(() => StudentDashboardService().getDashboard());

    expect(data.info.fullName, 'Test Student');
    expect(data.info.course, 'COURSE  ITI');
    expect(data.info.batchText, 'BATCH A · SEMESTER 1');
    expect(data.stats.attendancePercent, 75);
    expect(data.stats.assignmentsDoneText, '1/6');
    expect(data.stats.upcomingExamsCount, 1);
    expect(data.stats.feeDueText, '₹0');
    expect(data.courseProgress.single.courseName, 'Electricak');
    expect(data.courseProgress.single.percentComplete, 12);
    expect(data.pendingAssignments, hasLength(5));
    expect(data.pendingAssignments.first.status, ListItemStatus.overdue);
    expect(data.pendingAssignments.last.status, ListItemStatus.upcoming);
  });

  group('student record (API 3) and sessions (API 28)', () {
    test('reads the record and remembers the student id', () async {
      final record = await api(() => StudentRecordService().getRecord());

      expect(record.id, testStudentId);
      expect(record.attendanceText, '75%');
      expect(record.feeStatus, 'No Dues');
      expect(record.overallGrade, 'A');
      expect(record.documentsPending, hasLength(4));

      // Cached: no second request.
      final requests = <http.Request>[];
      final id = await withServer(
        fakeServer(requests: requests),
        () => StudentRecordService().getStudentId(),
      );
      expect(id, testStudentId);
      expect(requests, isEmpty);
    });

    test('lists logged-in devices, newest first', () async {
      final sessions = await api(() => StudentRecordService().getActiveSessions());

      expect(sessions, hasLength(3));
      expect(sessions.first.deviceName, 'Windows - Unknown Browser');
      expect(sessions.first.expiresAt, isNotNull);
    });
  });

  test('profile (API 4)', () async {
    final profile = await api(() => StudentProfileService().getProfile());

    expect(profile.fullName, 'Test Student');
    expect(profile.rollNo, '100001');
    expect(profile.registrationNo, 'REG-000001');
    expect(profile.dateOfBirthText, '01 Jan 2005');
    expect(profile.branch, 'FITTER');
    expect(profile.bloodGroup, 'A+');
    expect(profile.address, '—', reason: 'empty fields show a dash');
    expect(profile.photoUrl, startsWith('http'));
  });

  group('learning (APIs 5, 6)', () {
    test('live classes: finished classes without a recording are left out', () async {
      final result = await api(() => StudentCourseService().getLiveClasses());

      // Every class in the fixture is "Completed" with no recording.
      expect(result.schedule, isEmpty);
      expect(result.recorded, isEmpty);
    });

    test('study materials, newest first, with their links', () async {
      final all = await api(() => StudentCourseService().getStudyMaterials());
      final materials = all.where((m) => m.id.startsWith('material-')).toList();

      expect(materials, hasLength(5));
      expect(materials.first.title, 'ASSIG -1016');
      expect(materials.first.uploadedByFacultyName, 'Test Faculty');
      expect(materials.where((m) => m.url.isNotEmpty), hasLength(3));
      expect(materials.where((m) => m.type == StudentMaterialType.pdf), isNotEmpty);
    });

    test('finished live classes without a recording show as past classes', () async {
      final result = await api(() => StudentCourseService().getLiveClasses());

      // The fixture's 5 classes are all "Completed" with no recording.
      expect(result.schedule, isEmpty);
      expect(result.recorded, isEmpty);
      expect(result.past, hasLength(5));
      expect(result.past.first.subject, contains('Wiring Basics - Session 5'), reason: 'newest first');
      expect(result.past.every((c) => c.status == StudentClassStatus.completed), isTrue);
    });

    test('lessons (APIs 9-15) are merged in; a failing lesson API is skipped', () async {
      // The fake server has video, text and download lessons; the PDF,
      // image, presentation and multimedia APIs answer 404.
      final all = await api(() => StudentCourseService().getStudyMaterials());
      final lessons = all.where((m) => !m.id.startsWith('material-')).toList();

      final video = lessons.singleWhere((m) => m.type == StudentMaterialType.video);
      expect(video.url, 'https://www.youtube.com/watch?v=aVobvbxYF9g');

      final text = lessons.singleWhere((m) => m.type == StudentMaterialType.text);
      expect(text.url, isEmpty);
      expect(text.textContent, "Ohm's law\nV = IR");

      final downloads = lessons.where((m) => m.id.startsWith('download-')).toList();
      expect(downloads.map((m) => m.title), [
        'Images Of Notes · notes_1.png',
        'Images Of Notes · notes_2.png',
      ]);
      expect(downloads.map((m) => m.id).toSet(), hasLength(2), reason: 'ids stay unique');
    });

    test('timetable (API 46) grouped by day, in time order', () async {
      final timetable = await api(() => StudentCourseService().getTimetable());

      expect(timetable.keys.take(6), [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
      ]);
      expect(timetable['Monday']!.map((s) => s.timeRange), ['09:00-10:00', '15:00-16:00']);
      expect(timetable['Monday']!.last.period, 'P7');
      expect(timetable['Monday']!.first.room, 'room 1');
      expect(timetable['Tuesday']!.single.isOnline, isTrue);
      expect(timetable['Tuesday']!.single.room, 'Online');
      expect(timetable['Wednesday'], isEmpty);
    });
  });

  test('current session (API 25) is null when there is no class', () async {
    expect(await api(() => StudentSelfAttendanceService().getCurrentSession()), isNull);

    final live = fakeServer(
      handler: (request) async => http.Response(
        '{"session_name":"Electricak - BATCH A","faculty_name":"Test Faculty",'
        '"time_window":"09:00 - 10:00","status":"Ongoing"}',
        200,
      ),
    );
    final session = await withServer(live, () => StudentSelfAttendanceService().getCurrentSession());
    expect(session!.subject, 'Electricak');
    expect(session.batch, 'BATCH A');
    expect(session.timeRange, '09:00 - 10:00');
  });

  test('grading scale (API 23), best grade first, inactive bands hidden', () async {
    final bands = await api(() => StudentExamService().getGradingScale());

    expect(bands.map((b) => b.grade), ['A+', 'A']);
    expect(bands.first.gradePoint, 9);
  });

  test('mark all notifications read (API 41)', () async {
    final requests = <http.Request>[];
    final server = fakeServer(
      requests: requests,
      handler: (request) async =>
          request.method == 'POST' ? http.Response('{"status":"success"}', 200) : null,
    );

    await withServer(server, () => StudentNotificationService().markAllRead());

    expect(requests.single.url.path, AppUrls.markAllNotificationsRead);
  });

  test('registration no. comes only from registration_no, never enrollment_no', () async {
    final profile = await withServer(
      fakeServer(
        handler: (request) async => http.Response('{"enrollment_no":"ADM-010202","roll_no":"982837"}', 200),
      ),
      () => StudentProfileService().getProfile(),
    );

    expect(profile.registrationNo, '—');
    expect(profile.rollNo, '982837');
  });

  test('assignment upload (API 17 POST) sends form-data: assignment + file', () async {
    final requests = <http.Request>[];
    final server = fakeServer(
      requests: requests,
      // The reply the real server gave in the Postman test.
      handler: (request) async => request.method == 'POST'
          ? http.Response(
              '{"id":3,"assignment":10,"student_name":"Puneet",'
              '"file":"http://leariningmanagementsystem.whatido.in/media/submissions/NOTES_OF_DOCKERS_YBk7EPL.pdf",'
              '"submitted_at":"2026-11-03T13:02:34.556380+05:30","marks":null,"feedback":"","status":"pending"}',
              201,
            )
          : null,
    );

    await withServer(
      server,
      () => StudentAssignmentService().submitAssignment(
        assignmentId: '10',
        fileBytes: 'PDF-DATA'.codeUnits,
        fileName: 'NOTES OF DOCKERS.pdf',
      ),
    );

    final request = requests.single;
    expect(request.url.path, AppUrls.assignmentSubmissions);
    expect(request.headers['content-type'], startsWith('multipart/form-data'));
    expect(request.headers['authorization'], startsWith('Bearer '));
    expect(request.body, contains('name="assignment"\r\n\r\n10'));
    expect(request.body, contains('name="file"; filename="NOTES OF DOCKERS.pdf"'));
    expect(request.body, contains('PDF-DATA'));
  });

  test('assignment upload shows the server\'s reason when it fails', () async {
    final server = fakeServer(
      handler: (request) async => http.Response('{"file":["File too large."]}', 400),
    );

    expect(
      () => withServer(
        server,
        () => StudentAssignmentService().submitAssignment(
          assignmentId: '10',
          fileBytes: [1, 2, 3],
          fileName: 'a.pdf',
        ),
      ),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'File too large.')),
    );
  });

  test('update profile (API 6) sends the contact details', () async {
    final requests = <http.Request>[];
    final server = fakeServer(
      requests: requests,
      handler: (request) async => request.method == 'POST'
          ? http.Response('{"message":"Profile updated successfully"}', 200)
          : null,
    );

    final message = await withServer(
      server,
      () => StudentProfileService().updateContactDetails(
        mobile: '9000000000',
        guardianMobile: '9000000001',
        address: 'Test Address',
      ),
    );

    expect(message, 'Profile updated successfully');
    expect(requests.single.url.path, AppUrls.updateProfile);
    expect(
      requests.single.body,
      '{"mobile":"9000000000","guardian_mobile":"9000000001","address":"Test Address"}',
    );
  });

  group('auth (APIs 2, 42, 44)', () {
    test('password reset is sent without a token', () async {
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (request) async => http.Response('{"detail":"Link sent."}', 200),
      );

      final message = await withServer(
        server,
        () => AuthService().requestPasswordReset('test@example.com'),
      );

      expect(message, 'Link sent.');
      expect(requests.single.url.path, AppUrls.passwordReset);
      expect(requests.single.headers['Authorization'], isNull);
      expect(requests.single.body, '{"email":"test@example.com"}');
    });

    test('change password is a PUT with all three fields', () async {
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (request) async => http.Response('{"detail":"Password updated."}', 200),
      );

      await withServer(
        server,
        () => AuthService().changePassword(
          currentPassword: 'old',
          newPassword: 'new',
          confirmNewPassword: 'new',
        ),
      );

      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, AppUrls.changePassword);
      expect(
        requests.single.body,
        '{"current_password":"old","new_password":"new","confirm_new_password":"new"}',
      );
    });

    test('a wrong current password shows the server message', () async {
      final server = fakeServer(
        handler: (request) async =>
            http.Response('{"current_password":["Current password is incorrect."]}', 400),
      );

      expect(
        () => withServer(
          server,
          () => AuthService().changePassword(
            currentPassword: 'bad',
            newPassword: 'new',
            confirmNewPassword: 'new',
          ),
        ),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Current password is incorrect.')),
      );
    });

    test('log out other devices sends the refresh token', () async {
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (request) async =>
            http.Response('{"detail":"Logged out of 2 other sessions."}', 200),
      );

      final message = await withServer(server, () => AuthService().logoutOtherSessions());

      expect(message, 'Logged out of 2 other sessions.');
      expect(requests.single.url.path, AppUrls.logoutOtherSessions);
      expect(requests.single.body, '{"refresh_token":"test-refresh"}');
    });
  });

  test('assignments (APIs 7, 8) merge the submission into the assignment', () async {
    final assignments = await api(() => StudentAssignmentService().getAssignments());

    expect(assignments, hasLength(6));

    final submitted = assignments.singleWhere((a) => a.status != StudentAssignmentStatus.pending);
    expect(submitted.title, 'Assignmnet -1');
    expect(submitted.status, StudentAssignmentStatus.submitted);
    expect(submitted.submittedAt, isNotNull);
    expect(submitted.submittedFileUrl, contains('/media/submissions/'));
    expect(submitted.marksText, isNull, reason: 'not checked yet');

    final latest = assignments.first;
    expect(latest.title, 'ASSIG -1016');
    expect(latest.dueDate, DateTime(2026, 10, 25, 17, 0), reason: 'due_date + due_time');
    expect(latest.maxMarks, 30);
    expect(latest.facultyName, 'Test Faculty');
    expect(latest.description, isNotEmpty);
  });

  group('exams (APIs 9-13)', () {
    test('upcoming and all exams', () async {
      final service = StudentExamService();
      final upcoming = await api(service.getUpcomingExams);
      final all = await api(service.getAllExams);

      expect(upcoming.single.title, 'TT-04');
      expect(upcoming.single.chapter, 'Chapter-1 LLM');
      expect(upcoming.single.durationText, '1 hr');
      expect(all, hasLength(6));
      expect(all.first.title, 'TT-04', reason: 'newest first');
      expect(all.firstWhere((e) => e.title == 'TEST-1').durationText, '1 hr 30 min');
    });

    test('result history matches its attempt with answers', () async {
      final service = StudentExamService();
      final history = await api(service.getResultHistory);
      final attempts = await api(service.getAttempts);

      final result = history.single;
      expect(result.examTitle, 'tt-02');
      expect(result.scoreText, '1');
      expect(result.statusText, 'Evaluated');

      final attempt = attempts[result.id]!;
      expect(attempt.answers, hasLength(1));
      expect(attempt.tabSwitches, 1);
      expect(attempt.timeTakenText, '23 sec');
    });
  });

  group('attendance (APIs 14-16)', () {
    test('log, newest first, and subject-wise %', () async {
      final service = StudentAttendanceService();
      final log = await api(service.getAttendanceLog);

      expect(log, hasLength(4));
      expect(log.first.date, DateTime(2026, 10, 8));
      expect(log.where((e) => e.isPresent), hasLength(3));
      expect(log.first.markedByFacultyName, 'Test Faculty');

      final subjects = service.subjectWiseFromLog(log);
      expect(subjects.single.subject, 'Electricak');
      expect(subjects.single.percent, 75);
    });

    test('working days and rules', () async {
      final service = StudentAttendanceService();
      final days = await api(service.getWorkingDays);
      final rules = await api(service.getRules);

      expect(days.single.day, 'Monday');
      expect(days.single.isWorking, isTrue);
      expect(rules!.minRequiredPercent, 75);
      expect(rules.lowAlertPercent, 80);
      expect(rules.examLockPercent, 65);
      expect(rules.lateGraceMinutes, 15);
    });
  });

  group('fees (APIs 17-20)', () {
    test('fees, totals and the fee summary', () async {
      final service = StudentFeeService();
      final fees = await api(service.getFees);

      expect(fees.fees, hasLength(3));
      expect(fees.summary.totalFee, 260000);
      expect(fees.summary.amountPaid, 260000);
      expect(fees.summary.amountDue, 0);

      final summary = await api(() => service.applyFeeSummary(fees.summary));
      expect(summary.totalFee, 260000);
      expect(summary.amountDue, 0);
    });

    test('receipts, newest first, and paid by fee head', () async {
      final service = StudentFeeService();
      final receipts = await api(service.getPaymentHistory);
      final byHead = await api(service.getPaidByFeeHead);

      expect(receipts, hasLength(4));
      expect(receipts.first.receiptNo, 'RCPT-1-2026-000004');
      expect(receipts.first.paymentMode, 'Cash');

      final tuition = byHead.singleWhere((h) => h.feeHead == 'Tution Fees');
      expect(tuition.amount, 120000);
      expect(tuition.fineAmount, 1000);
      expect(byHead.singleWhere((h) => h.feeHead == 'Registration Fee').amount, 40000);
    });
  });

  group('certificates (APIs 21, 22)', () {
    test('requests, with issued details', () async {
      final certificates = await api(() => StudentCertificateService().getCertificates());

      expect(certificates, hasLength(7));
      expect(certificates.where((c) => c.status == CertificateStatus.available), hasLength(3));

      final character = certificates.singleWhere((c) => c.title == 'Character Certificate');
      expect(character.subtitle, 'Issued on 17 Oct 2026 · CHR/2026/0001');
      expect(character.issuedDetails['Name'], 'Test Student');
      expect(character.issuedDetails['Roll No.'], '100001');
    });

    test('a new request (API 32) sends the certificate type', () async {
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (request) async =>
            request.method == 'POST' ? http.Response('{"id":9}', 201) : null,
      );

      await withServer(
        server,
        () => StudentCertificateService().requestCertificate('Bonafide Certificate'),
      );

      final post = requests.single;
      expect(post.url.path, AppUrls.certificateRequests);
      expect(post.body, '{"certificate_type":"Bonafide"}');
    });

    test('an issued certificate (API 34) is created, then downloaded (API 35)', () async {
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (request) async {
          if (request.method == 'POST') return http.Response('{"id":2}', 201);
          if (request.url.path == AppUrls.downloadIssuedCertificate('2')) {
            return http.Response('<h1>CERTIFICATE</h1>', 200, headers: {'content-type': 'text/html'});
          }
          return null;
        },
      );

      final service = StudentCertificateService();
      final id = await withServer(server, () => service.createIssuedCertificate('Course Completion'));
      final document = await withServer(server, () => service.downloadIssuedCertificate(id));

      final post = requests.singleWhere((r) => r.method == 'POST');
      expect(post.body, '{"title":"Course Completion","student":"$testStudentId"}');
      expect(id, '2');
      expect(document.contentType, 'text/html');
      expect(String.fromCharCodes(document.bytes), '<h1>CERTIFICATE</h1>');
    });
  });

  group('placements (APIs 23-26)', () {
    test('drives, my applications and placed students', () async {
      final service = StudentPlacementService();
      final drives = await api(service.getDrives);
      final applications = await api(service.getApplications);
      final placed = await api(service.getPlacedStudents);

      expect(drives.map((d) => d.companyName), ['Google India', 'Havells', 'CISCO']);
      expect(drives.last.pdfUrl, isNotEmpty);
      expect(applications.map((a) => a.driveId), containsAll(['1', '3']));
      expect(applications.first.companyName, 'Havells', reason: 'newest first');
      // 7 placed students on campus, 3 of them this student: only those 3 show.
      expect(placed, hasLength(3));
      expect(placed.every((p) => p.isMe), isTrue);
    });

    test('applying sends the drive id as "job"', () async {
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (request) async =>
            request.method == 'POST' ? http.Response('{"id":12}', 201) : null,
      );

      await withServer(server, () => StudentPlacementService().apply('3'));

      expect(requests.single.url.path, AppUrls.placementApplications);
      expect(requests.single.body, '{"job":3}');
    });
  });

  test('notifications (API 27), with ₹ and line breaks intact', () async {
    final notifications = await api(() => StudentNotificationService().getNotifications());

    expect(notifications, hasLength(2));
    expect(notifications.first.title, 'Welcome to Maa Guljari Bharat Pvt. ITI');
    expect(notifications.first.attachmentUrl, isNotEmpty);

    final notice = notifications.last;
    expect(notice.body, contains('₹1,500'));
    expect(notice.body, isNot(contains('\r')));
  });
}
