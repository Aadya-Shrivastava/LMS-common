// Tests for ApiClient (token header, reading replies, error messages,
// renewing an expired token, offline fallback) and login/logout.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lms/core/constants/app_urls.dart';
import 'package:lms/core/network/api_client.dart';
import 'package:lms/core/storage/token_storage_service.dart';
import 'package:lms/models/user_model.dart';
import 'package:lms/services/auth_service.dart';

import '../helpers/fake_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetApiState);

  test('sends the saved access token, and none when auth is off', () async {
    final requests = <http.Request>[];

    await withServer(fakeServer(requests: requests), () async {
      await ApiClient().get(AppUrls.studentProfile);
      await ApiClient().get(AppUrls.studentProfile, auth: false);
    });

    expect(requests[0].headers['Authorization'], 'Bearer test-access');
    expect(requests[1].headers.containsKey('Authorization'), isFalse);
  });

  test('reads replies as UTF-8 even without a charset (₹, –)', () async {
    final server = fakeServer(handler: (request) async {
      return http.Response.bytes(utf8.encode('{"text":"Fee: ₹1,500 – paid"}'), 200,
          headers: {'content-type': 'application/json'});
    });

    final data = await withServer(server, () => ApiClient().get('/api/any/'));
    expect(data['text'], 'Fee: ₹1,500 – paid');
  });

  group('error messages', () {
    Future<ApiException> errorFor(int status, String body) async {
      final server = fakeServer(handler: (_) async => http.Response(body, status));
      try {
        await withServer(server, () => ApiClient().get('/api/any/', auth: false));
      } on ApiException catch (e) {
        return e;
      }
      fail('expected an ApiException');
    }

    test('uses the server\'s "detail" message', () async {
      final e = await errorFor(400, '{"detail":"Exam already submitted."}');
      expect(e.message, 'Exam already submitted.');
      expect(e.statusCode, 400);
    });

    test('uses the first field error from a validation reply', () async {
      final e = await errorFor(400, '{"title":["This field is required."]}');
      expect(e.message, 'This field is required.');
    });

    test('a crashed server with no readable message shows "Something went wrong"', () async {
      final e = await errorFor(500, '<html>Server Error</html>');
      expect(e.message, ApiClient.somethingWentWrong);
      expect(e.statusCode, 500);
    });

    test('an unreadable error reply shows "Something went wrong"', () async {
      final e = await errorFor(400, '<html>Bad Request</html>');
      expect(e.message, ApiClient.somethingWentWrong);
    });

    test('any other failure (not from the server) shows "Something went wrong"', () {
      expect(ApiClient.messageFor(TypeError()), ApiClient.somethingWentWrong);
    });

    test('the server\'s message is always shown, whatever the status', () async {
      final e = await errorFor(400, '{"title":["This field is required."]}');
      expect(ApiClient.messageFor(e), 'This field is required.');

      final conflict = await errorFor(409, '{"message":"You are already placed in another company."}');
      expect(ApiClient.messageFor(conflict), 'You are already placed in another company.');

      final forbidden = await errorFor(403, '{"detail":"You are not allowed to apply for this drive."}');
      expect(ApiClient.messageFor(forbidden), 'You are not allowed to apply for this drive.');

      final notFound = await errorFor(404, '{"detail":"Not found."}');
      expect(ApiClient.messageFor(notFound), 'Not found.');
    });

    test('a crashed server never shows its message', () async {
      final e = await errorFor(500, '{"error":"Drive is closed."}');
      expect(e.message, ApiClient.somethingWentWrong);
    });

    test('technical messages show "Something went wrong" instead', () async {
      for (final body in [
        '{"detail":"No Assignment matches the given query."}',
        '{"detail":"Method \\"POST\\" not allowed."}',
        '{"detail":"IntegrityError: duplicate key value violates unique constraint"}',
        '{"job":["Invalid pk \\"99\\" - object does not exist."]}',
        '{"error":"\'NoneType\' object has no attribute \'id\'"}',
        '{"detail":"JSON parse error - Expecting value"}',
      ]) {
        final e = await errorFor(400, body);
        expect(e.message, ApiClient.somethingWentWrong, reason: body);
      }
    });

    test('finds the message inside nested replies, never the whole reply', () async {
      final nested = await errorFor(400, '{"status":"error","errors":{"job":["Already applied."]}}');
      expect(nested.message, 'Already applied.');

      final dump = await errorFor(400, '{"trace":"Traceback...\\n  File x\\n  line 3"}');
      expect(dump.message, ApiClient.somethingWentWrong);
    });

    test('a 200 reply that says it failed is treated as an error', () async {
      final e = await errorFor(200, '{"success":false,"message":"Already placed elsewhere."}');
      expect(e.message, 'Already placed elsewhere.');
    });

    test('no internet and an expired login are always explained', () {
      const offline = ApiException(ApiClient.noInternet);
      const expired = ApiException(ApiClient.sessionExpired, statusCode: 401);
      expect(ApiClient.messageFor(offline), ApiClient.noInternet);
      expect(ApiClient.messageFor(expired), ApiClient.sessionExpired);
    });

    test('no reply from the server becomes the no-internet message', () async {
      final e = await withServer(
        fakeServer(handler: (request) async => throw http.ClientException('Failed host lookup')),
        () async {
          try {
            await ApiClient().post('/api/thing/');
          } on ApiException catch (e) {
            return e;
          }
          return null;
        },
      );
      expect(e?.message, ApiClient.noInternet);
    });
  });

  group('expired access token', () {
    test('renews the token once and retries the request', () async {
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (request) async {
          if (request.url.path == AppUrls.refreshToken) {
            expect(jsonDecode(request.body), {'refresh': 'test-refresh'});
            return http.Response('{"access":"new-access","refresh":"new-refresh"}', 200);
          }
          if (request.headers['Authorization'] == 'Bearer test-access') {
            return http.Response('{"detail":"Token expired"}', 401);
          }
          return null; // the fixture
        },
      );

      final data = await withServer(server, () => ApiClient().get(AppUrls.studentProfile));

      expect(data['roll_no'], '100001');
      expect(requests.map((r) => r.url.path), [
        AppUrls.studentProfile,
        AppUrls.refreshToken,
        AppUrls.studentProfile,
      ]);
      expect(requests.last.headers['Authorization'], 'Bearer new-access');
      expect(await TokenStorageService().getAccessToken(), 'new-access');
      expect(await TokenStorageService().getRefreshToken(), 'new-refresh');
    });

    test('logs out when the refresh token is rejected too', () async {
      var sessionExpired = false;
      ApiClient.onSessionExpired = () => sessionExpired = true;

      final server = fakeServer(handler: (_) async => http.Response('{"detail":"no"}', 401));

      await expectLater(
        withServer(server, () => ApiClient().get(AppUrls.studentProfile)),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
      expect(sessionExpired, isTrue);
      expect(await TokenStorageService().getAccessToken(), isNull);
    });
  });

  group('offline', () {
    final offline = fakeServer(handler: (_) async => throw http.ClientException('No internet'));

    test('shows a friendly error when nothing was saved yet', () async {
      await expectLater(
        withServer(offline, () => ApiClient().get(AppUrls.studentProfile)),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', isNull)),
      );
    });

    test('returns the last saved reply and flags the banner', () async {
      final cache = MemoryApiCache();
      ApiClient.cache = cache;

      // Online: the reply is saved.
      await withServer(fakeServer(), () => ApiClient().get(AppUrls.studentProfile));
      await Future<void>.delayed(Duration.zero);
      expect(cache.saved.keys, [AppUrls.studentProfile]);
      expect(ApiClient.showingSavedDataFrom.value, isNull);

      // Offline: the saved reply comes back instead of an error.
      final data = await withServer(offline, () => ApiClient().get(AppUrls.studentProfile));
      expect(data['roll_no'], '100001');
      expect(ApiClient.showingSavedDataFrom.value, isNotNull);

      // Back online: the banner goes away.
      await withServer(fakeServer(), () => ApiClient().get(AppUrls.studentProfile));
      expect(ApiClient.showingSavedDataFrom.value, isNull);
    });

    test('does not hide a real server error behind saved data', () async {
      final cache = MemoryApiCache();
      ApiClient.cache = cache;
      await cache.write(AppUrls.studentProfile, {'old': true});

      final notFound = fakeServer(handler: (_) async => http.Response('{"detail":"Not found."}', 404));

      await expectLater(
        withServer(notFound, () => ApiClient().get(AppUrls.studentProfile)),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('POST requests are never answered from saved data', () async {
      ApiClient.cache = MemoryApiCache();
      await expectLater(
        withServer(offline, () => ApiClient().post(AppUrls.placementApplications, body: {'job': 1})),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('login and logout', () {
    test('login sends the email or username and saves both tokens', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (_) async => http.Response('{"access":"a1","refresh":"r1"}', 200),
      );

      final user = await withServer(
        server,
        () => AuthService().login(identifier: 'teststudent', password: 'pw', role: UserRole.student),
      );

      expect(jsonDecode(requests.single.body), {'identifier': 'teststudent', 'password': 'pw'});
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
      expect(user.name, 'teststudent');
      expect(user.email, isEmpty, reason: 'a username is not an email');
      expect(await TokenStorageService().getAccessToken(), 'a1');
      expect(await TokenStorageService().getRefreshToken(), 'r1');
    });

    test('wrong password shows the server message and saves nothing', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final server = fakeServer(
        handler: (_) async => http.Response('{"detail":"Invalid credentials"}', 401),
      );

      await expectLater(
        withServer(
          server,
          () => AuthService().login(identifier: 'x@y.com', password: 'bad', role: UserRole.student),
        ),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Invalid credentials')),
      );
      expect(await TokenStorageService().getAccessToken(), isNull);
    });

    test('logout tells the server, then clears the tokens', () async {
      final requests = <http.Request>[];
      final server = fakeServer(
        requests: requests,
        handler: (_) async => http.Response('{"detail":"Successfully logged out."}', 200),
      );

      await withServer(server, () => AuthService().logout());

      expect(requests.single.url.path, AppUrls.logout);
      expect(jsonDecode(requests.single.body), {'refresh_token': 'test-refresh'});
      expect(await TokenStorageService().getAccessToken(), isNull);
      expect(await TokenStorageService().getRefreshToken(), isNull);
    });

    test('logout still clears the tokens when offline', () async {
      final offline = fakeServer(handler: (_) async => throw http.ClientException('No internet'));

      await withServer(offline, () => AuthService().logout());

      expect(await TokenStorageService().getAccessToken(), isNull);
    });
  });
}
