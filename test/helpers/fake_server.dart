// Shared helpers for tests: a fake backend that answers every API with
// the saved replies in test/fixtures/, and an in-memory offline cache.
//
// The fixtures are real replies from the backend with the student's
// personal details swapped for fake ones (name "Test Student", etc.).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms/core/network/api_client.dart';
import 'package:lms/core/storage/api_cache.dart';
import 'package:lms/services/student/student_record_service.dart';

/// The fake student's id, as it appears in the fixtures.
const String testStudentId = '00000000-0000-4000-8000-000000000001';

/// API path -> fixture file name (in test/fixtures/, without ".json").
const Map<String, String> fixtureForPath = {
  '/api/student/students/dashboard/': 'dashboard',
  '/api/students/students/': 'student_record',
  '/api/students/profile/': 'profile',
  '/api/learning/live-classes/': 'live_classes',
  '/api/learning/study-materials/': 'study_materials',
  '/api/assignments/assignments/student_assignments/': 'my_assignments',
  '/api/assignments/submissions/': 'submissions',
  '/api/exams/exams/': 'exams',
  '/api/exams/exams/upcoming/': 'upcoming_exams',
  '/api/exams/attempts/': 'exam_attempts',
  '/api/exams/answers/': 'exam_answers',
  '/api/exams/attempts/history/': 'exam_history',
  '/api/attendance/records/': 'attendance_records',
  '/api/attendance/working-days/': 'working_days',
  '/api/attendance/attendance-rules/': 'attendance_rules',
  '/api/fees/student-fees/': 'student_fees',
  '/api/fees/fee-payments/': 'fee_payments',
  '/api/fees/fee-payment-items/': 'fee_payment_items',
  '/api/student/student/$testStudentId/fee_summary/': 'fee_summary',
  '/api/certificates/requests/': 'certificate_requests',
  '/api/placements/placement-drives/': 'placement_drives',
  '/api/placements/applications/': 'placement_applications',
  '/api/placements/placed-students/': 'placed_students',
  '/api/communication/notifications/': 'notifications',
  '/api/auth/sessions/': 'sessions',
  '/api/timetable/entries/': 'timetable_entries',
  '/api/academics/video-lessons/': 'video_lessons',
  '/api/academics/text-lessons/': 'text_lessons',
  '/api/academics/download-lessons/': 'download_lessons',
  '/api/exams/grades/': 'exam_grades',
  '/api/attendance/records/current_session/': 'current_session',
};

/// The raw bytes of a fixture file.
List<int> fixtureBytes(String name) => File('test/fixtures/$name.json').readAsBytesSync();

/// A fixture decoded as JSON.
dynamic fixtureJson(String name) => jsonDecode(utf8.decode(fixtureBytes(name)));

/// A fake backend. GET requests to known paths get their fixture, like
/// the real server would (no charset in the Content-Type, just like
/// the real one). Anything else gets a 404, unless `handler` answers
/// it first (return null from `handler` to fall through).
///
/// Every request is added to `requests`, so tests can check what was sent.
MockClient fakeServer({
  List<http.Request>? requests,
  Future<http.Response?> Function(http.Request request)? handler,
}) {
  return MockClient((request) async {
    requests?.add(request);

    final custom = await handler?.call(request);
    if (custom != null) return custom;

    final fixture = fixtureForPath[request.url.path];
    if (request.method == 'GET' && fixture != null) {
      return http.Response.bytes(
        fixtureBytes(fixture),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    return http.Response('{"detail":"Not found."}', 404);
  });
}

/// Runs `body` with every API call going to `client` instead of the
/// internet.
Future<T> withServer<T>(http.Client client, Future<T> Function() body) async {
  // ApiClient keeps one shared client, so point it at the fake server.
  final previous = ApiClient.debugHttpClient;
  ApiClient.debugHttpClient = client;
  try {
    return await http.runWithClient(body, () => client);
  } finally {
    ApiClient.debugHttpClient = previous;
  }
}

/// Resets everything that's kept between API calls, so tests don't
/// affect each other. Call from `setUp`.
void resetApiState({String? accessToken = 'test-access', String? refreshToken = 'test-refresh'}) {
  FlutterSecureStorage.setMockInitialValues({
    'access_token': ?accessToken,
    'refresh_token': ?refreshToken,
  });
  StudentRecordService.clearCache();
  ApiClient.cache = null;
  ApiClient.onSessionExpired = null;
  ApiClient.showingSavedDataFrom.value = null;
}

/// An offline cache that lives in memory, for tests.
class MemoryApiCache implements ApiCache {
  final Map<String, SavedResponse> saved = {};

  @override
  SavedResponse? read(String path) => saved[path];

  @override
  Future<void> write(String path, dynamic data) async {
    // Round-trip through JSON, like the real cache does.
    saved[path] = SavedResponse(jsonDecode(jsonEncode(data)), DateTime.now());
  }

  @override
  Future<void> clear() async => saved.clear();
}
