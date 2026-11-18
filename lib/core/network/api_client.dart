import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_urls.dart';
import '../storage/api_cache.dart';
import '../storage/token_storage_service.dart';

/// Thrown when an API call fails. `message` is safe to show to the user.
class ApiException implements Exception {
  final String message;

  /// The HTTP status code from the server, or null if we never got a
  /// reply (no internet, server down, timeout).
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// The one place in the app that talks to our backend server.
///
/// Services call `get` / `post` with a path from `AppUrls`, for example
/// `ApiClient().post(AppUrls.login, body: {...})`. This class adds the
/// base URL, sends the saved access token, turns the reply JSON into a
/// Dart map, and converts any failure into an `ApiException`.
class ApiClient {
  /// Shown whenever an API fails in a way the student can't fix: the
  /// server crashed, the address doesn't exist, or it replied with
  /// something the app can't read.
  static const String somethingWentWrong = 'Something went wrong. Please try again.';

  /// When the phone can't reach the server at all.
  static const String noInternet = 'Something went wrong. Please check your internet connection.';

  /// When the login has run out and the student is sent back to login.
  static const String sessionExpired = 'Your session has expired. Please log in again.';

  /// The message to show for any error from loading or saving.
  ///
  /// If the server explained what went wrong ("You are already placed
  /// in another company.", "This field is required."...), that message
  /// is shown as-is - just the message, never the whole reply. Otherwise
  /// it's "Something went wrong", or the no-internet / session-expired
  /// message. Anything that isn't an `ApiException` (a bug, an API that
  /// changed shape) is "Something went wrong".
  static String messageFor(Object error) {
    if (error is! ApiException) return somethingWentWrong;
    return error.message.trim().isEmpty ? somethingWentWrong : error.message;
  }

  // The base web address of our backend. The real value lives in
  // `AppUrls` so the whole app uses the same address.
  final String baseUrl = AppUrls.baseUrl;

  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Called when the refresh token has also expired, so the user has to
  /// log in again. `AuthController` sets this to its `logout` method.
  static void Function()? onSessionExpired;

  // While a token refresh is running, every other request that gets a
  // 401 waits for this same refresh instead of starting its own.
  static Future<bool>? _refreshInProgress;

  // How long we wait for the server before giving up.
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(minutes: 3);

  /// Where GET replies are saved for offline use. Set once in `main()`;
  /// left null (no saving) in tests unless a test sets it.
  static ApiCache? cache;

  /// When the phone is offline and screens are showing saved data, this
  /// holds when that data was saved, so the app can show a banner.
  /// Null while the app is online.
  static final ValueNotifier<DateTime?> showingSavedDataFrom = ValueNotifier(null);

  /// One HTTP client for the whole app, so requests reuse open
  /// connections to the server instead of opening a new one each time.
  static http.Client? _shared;

  /// Tests set this to a fake server (see test/helpers/fake_server.dart).
  @visibleForTesting
  static http.Client? debugHttpClient;

  http.Client get _http => debugHttpClient ?? (_shared ??= http.Client());

  // Marks a zone where GETs answer from saved data only (`fromCache`).
  static final Object _cacheOnlyKey = Object();

  /// Runs `load` (a service call) using only saved replies: every GET
  /// it makes returns its saved reply instantly, without the network.
  ///
  /// Returns null if something it needs was never saved (first visit,
  /// just logged in) or the saved data can't be read. Used to show a
  /// screen immediately while fresh data loads in the background.
  static Future<T?> fromCache<T>(Future<T> Function() load) async {
    if (cache == null) return null;
    try {
      return await runZoned(load, zoneValues: {_cacheOnlyKey: true});
    } catch (_) {
      // Nothing saved, or old saved data in a different shape: just
      // wait for the server instead.
      return null;
    }
  }

  static bool get _cacheOnly => Zone.current[_cacheOnlyKey] == true;

  /// Sends a GET request. Set `auth` to false for APIs that don't need
  /// the user to be logged in.
  ///
  /// Every successful reply is saved. If the phone can't reach the
  /// server, the last saved reply is returned instead of an error, so
  /// screens still work offline.
  Future<dynamic> get(String path, {bool auth = true}) async {
    if (_cacheOnly) {
      final saved = cache?.read(path);
      if (saved == null) throw const ApiException('Nothing saved yet.');
      return saved.data;
    }

    try {
      final data = await _send(
        () async => _http.get(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(auth),
        ),
        auth: auth,
      );

      // Saving is best-effort; a full disk shouldn't break the screen.
      final cache = ApiClient.cache;
      if (cache != null) unawaited(cache.write(path, data).catchError((Object _) {}));
      return data;
    } on ApiException catch (e) {
      // The server answered with an error (wrong id, expired session...):
      // show it, don't hide it behind old data.
      if (e.statusCode != null) rethrow;

      final saved = cache?.read(path);
      if (saved == null) rethrow;

      final oldest = showingSavedDataFrom.value;
      if (oldest == null || saved.savedAt.isBefore(oldest)) {
        showingSavedDataFrom.value = saved.savedAt;
      }
      return saved.data;
    }
  }

  /// Sends a POST request with a JSON body.
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _send(
      () async => _http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth),
        body: jsonEncode(body ?? {}),
      ),
      auth: auth,
    );
  }

  /// Sends a PUT request with a JSON body.
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _send(
      () async => _http.put(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth),
        body: jsonEncode(body ?? {}),
      ),
      auth: auth,
    );
  }

  /// Sends a POST as `multipart/form-data`: text `fields` plus one file
  /// (e.g. an assignment upload). Gets longer to finish than other
  /// requests, since a file on a slow connection takes a while.
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    return _send(
      () async {
        // A multipart request can only be sent once, so it's rebuilt
        // for the retry after a token refresh.
        final headers = await _headers(true)..remove('Content-Type');
        final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
          ..headers.addAll(headers)
          ..fields.addAll(fields)
          ..files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName));
        return http.Response.fromStream(await _http.send(request));
      },
      auth: true,
      timeout: _uploadTimeout,
    );
  }

  /// Sends a GET request for an API that replies with a document
  /// instead of JSON (e.g. a rendered certificate). Returns the raw
  /// bytes and their content type. Not saved for offline use.
  Future<({List<int> bytes, String contentType})> getDocument(String path) async {
    final response = await _sendRaw(
      () async => _http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(true),
      ),
      auth: true,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handle(response); // Throws the readable ApiException.
    }
    return (
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'] ?? '',
    );
  }

  /// Builds the headers for a request. When `auth` is true, the saved
  /// access token is added as `Authorization: Bearer <token>`.
  Future<Map<String, String>> _headers(bool auth) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Runs the request and turns the reply into JSON, or throws an
  /// `ApiException` with a readable message.
  ///
  /// If a logged-in request gets a 401 (access token expired), we swap
  /// the refresh token for new tokens and try the request once more.
  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    required bool auth,
    Duration timeout = _timeout,
  }) async {
    return _handle(await _sendRaw(request, auth: auth, timeout: timeout));
  }

  /// Like `_send`, but gives back the raw reply (after a token refresh
  /// if one was needed) instead of decoding it as JSON.
  Future<http.Response> _sendRaw(
    Future<http.Response> Function() request, {
    required bool auth,
    Duration timeout = _timeout,
  }) async {
    // Saved-data-only mode (`fromCache`) never touches the network.
    if (_cacheOnly) throw const ApiException('Nothing saved yet.');
    var response = await _run(request, timeout: timeout);

    if (response.statusCode == 401 && auth) {
      if (await _refreshTokens()) {
        // `request` reads the token again, so this retry uses the new one.
        response = await _run(request, timeout: timeout);
      } else {
        await _tokenStorage.clearTokens();
        onSessionExpired?.call();
        throw const ApiException(sessionExpired, statusCode: 401);
      }
    }

    return response;
  }

  /// Gets new access and refresh tokens using the saved refresh token.
  /// Returns false if there's no refresh token or the server rejects it.
  Future<bool> _refreshTokens() {
    return _refreshInProgress ??= _doRefresh().whenComplete(() {
      _refreshInProgress = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await _run(
        () => _http.post(
          Uri.parse('$baseUrl${AppUrls.refreshToken}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'refresh': refresh}),
        ),
      );
      if (response.statusCode != 200) return false;

      final data = _tryDecode(_bodyText(response));
      final newAccess = data is Map ? data['access'] : null;
      if (newAccess is! String) return false;

      // The server sends a new refresh token too; keep the old one if not.
      final newRefresh = data['refresh'];
      await _tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh is String ? newRefresh : refresh,
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Sends the request, turning "no internet" and timeouts into
  /// `ApiException`s.
  Future<http.Response> _run(
    Future<http.Response> Function() request, {
    Duration timeout = _timeout,
  }) async {
    try {
      final response = await request().timeout(timeout);
      // Any reply at all means we're back online.
      showingSavedDataFrom.value = null;
      return response;
    } on TimeoutException {
      throw const ApiException(somethingWentWrong);
    } on http.ClientException {
      // `http` reports "no internet" and "server unreachable" this way.
      throw const ApiException(noInternet);
    }
  }

  /// Turns a reply into JSON, or throws an `ApiException` if the server
  /// said something went wrong.
  dynamic _handle(http.Response response) {
    final body = _bodyText(response);
    final dynamic data = body.isEmpty ? null : _tryDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Some APIs reply 200 but say it failed, e.g.
      // `{"success": false, "message": "Already placed elsewhere."}`.
      if (data is Map && (data['success'] == false || data['status'] == false)) {
        throw ApiException(
          _findMessage(data) ?? somethingWentWrong,
          statusCode: response.statusCode,
        );
      }
      return data;
    }

    throw ApiException(
      _errorMessage(data, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  /// The reply as text. Always read as UTF-8: the server doesn't say
  /// which charset it uses, and `http` would then fall back to Latin-1,
  /// which garbles characters like "₹" and "–".
  String _bodyText(http.Response response) {
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  /// The message for an error reply: whatever message the server put in
  /// it, or a generic one if it didn't send a readable message (e.g. an
  /// HTML error page from a crashed server).
  String _errorMessage(dynamic data, int statusCode) {
    // A crashed server: whatever it says is technical.
    if (statusCode >= 500) return somethingWentWrong;

    final message = _findMessage(data);
    if (message != null) return message;

    if (statusCode == 401) return 'Invalid login details.';
    return somethingWentWrong;
  }

  // Where servers usually put the human-readable message, checked first.
  static const List<String> _messageKeys = [
    'detail',
    'message',
    'msg',
    'error',
    'errors',
    'non_field_errors',
  ];

  /// Finds the human-readable message in a reply - just that one line,
  /// never the whole reply. Handles the usual shapes:
  /// `{"detail": "..."}`, `{"message": "..."}`, `{"error": "..."}`,
  /// `{"field": ["..."]}`, `{"errors": {"field": ["..."]}}`, `["..."]`.
  ///
  /// Returns null if there's no sensible message (nothing there, or a
  /// long multi-line dump that isn't meant for people).
  static String? _findMessage(dynamic data, [int depth = 0]) {
    if (depth > 4) return null;

    if (data is String) {
      final text = data.trim();
      final looksReadable =
          text.isNotEmpty && text.length <= 200 && !text.contains('\n') && !_looksTechnical(text);
      return looksReadable ? text : null;
    }

    if (data is List) {
      for (final item in data) {
        final found = _findMessage(item, depth + 1);
        if (found != null) return found;
      }
      return null;
    }

    if (data is Map) {
      for (final key in _messageKeys) {
        if (!data.containsKey(key)) continue;
        final found = _findMessage(data[key], depth + 1);
        if (found != null) return found;
      }
      for (final entry in data.entries) {
        // Status flags like `"status": "error"` aren't messages.
        if (entry.key == 'status' || entry.key == 'code' || entry.key == 'success') continue;
        final found = _findMessage(entry.value, depth + 1);
        if (found != null) return found;
      }
    }

    return null;
  }

  // Wording that only makes sense to a developer: crash and database
  // errors, framework defaults about ids/types/methods, raw data.
  static final List<RegExp> _technicalPatterns = [
    RegExp(r'traceback|exception|stack ?trace', caseSensitive: false),
    RegExp(r'\b\w+(Error|Exception)\b'), // IntegrityError, KeyError, NullPointerException...
    RegExp(r'NoneType|has no attribute|object is not|is not subscriptable|not iterable', caseSensitive: false),
    RegExp(r'\bsql\b|database|relation "|column "|violates|constraint|duplicate key|null value',
        caseSensitive: false),
    RegExp(r'matches the given query', caseSensitive: false), // Django's "No X matches the given query."
    RegExp(r'^Method "\w+" not allowed', caseSensitive: false), // Django's 405
    RegExp(r'invalid pk|expected pk value|incorrect type\. expected|object does not exist',
        caseSensitive: false),
    RegExp(r'json parse error|unsupported media type|expected a (list|dictionary)', caseSensitive: false),
    RegExp(r'token|credentials were not provided', caseSensitive: false),
    RegExp(r'django|python|/api/|https?://|\bline \d+\b|<[a-z!/]', caseSensitive: false),
    RegExp(r'^[\[{]'), // raw JSON
  ];

  static bool _looksTechnical(String text) => _technicalPatterns.any((p) => p.hasMatch(text));

  /// The server's own message from a successful reply, if it sent one
  /// (e.g. `{"message": "Applied successfully."}`), otherwise null.
  static String? successMessage(dynamic data) {
    if (data is! Map) return null;
    for (final key in const ['message', 'detail', 'msg']) {
      final found = _findMessage(data[key]);
      if (found != null) return found;
    }
    return null;
  }
}
