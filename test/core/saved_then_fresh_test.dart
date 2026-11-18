// Tests the "show saved data first, then fresh data" loading that
// makes screens open instantly on later visits.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lms/core/network/api_client.dart';
import 'package:lms/core/network/saved_then_fresh.dart';

import '../helpers/fake_server.dart';

void main() {
  setUp(resetApiState);

  test('fromCache answers from saved data without touching the network', () async {
    final cache = MemoryApiCache();
    ApiClient.cache = cache;
    await cache.write('/api/thing/', {'value': 'saved'});

    final requests = <http.Request>[];
    final data = await withServer(
      fakeServer(requests: requests),
      () => ApiClient.fromCache(() => ApiClient().get('/api/thing/')),
    );

    expect(data, {'value': 'saved'});
    expect(requests, isEmpty);
  });

  test('fromCache gives null when nothing was saved, or there is no cache', () async {
    expect(await ApiClient.fromCache(() => ApiClient().get('/api/thing/')), isNull);

    ApiClient.cache = MemoryApiCache();
    expect(await ApiClient.fromCache(() => ApiClient().get('/api/thing/')), isNull);
  });

  test('fromCache never sends a POST', () async {
    ApiClient.cache = MemoryApiCache();
    final requests = <http.Request>[];

    final result = await withServer(
      fakeServer(requests: requests),
      () => ApiClient.fromCache(() => ApiClient().post('/api/thing/')),
    );

    expect(result, isNull);
    expect(requests, isEmpty);
  });

  test('loadSavedThenFresh shows saved data, then the fresh data', () async {
    final cache = MemoryApiCache();
    ApiClient.cache = cache;
    await cache.write('/api/thing/', {'value': 'saved'});

    final shown = <dynamic>[];
    final error = await withServer(
      fakeServer(handler: (request) async => http.Response('{"value":"fresh"}', 200)),
      () => loadSavedThenFresh(() => ApiClient().get('/api/thing/'), shown.add),
    );

    expect(error, isNull);
    expect(shown, [
      {'value': 'saved'},
      {'value': 'fresh'},
    ]);
  });

  test('loadSavedThenFresh turns an unexpected failure into "Something went wrong"', () async {
    // e.g. the API changed shape and reading it threw a TypeError:
    // the screen must show an error, not a skeleton forever.
    final error = await loadSavedThenFresh<int>(() async => throw TypeError(), (_) {});
    expect(error, ApiClient.somethingWentWrong);
  });

  test('loadSavedThenFresh reports a server error but keeps the saved data', () async {
    final cache = MemoryApiCache();
    ApiClient.cache = cache;
    await cache.write('/api/thing/', {'value': 'saved'});

    final shown = <dynamic>[];
    final error = await withServer(
      fakeServer(handler: (request) async => http.Response('{"detail":"Broken."}', 400)),
      () => loadSavedThenFresh(() => ApiClient().get('/api/thing/'), shown.add),
    );

    // The server's own message is shown.
    expect(error, 'Broken.');
    expect(shown, [
      {'value': 'saved'},
    ]);
  });
}
