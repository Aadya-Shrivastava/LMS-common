import 'dart:convert';
import 'package:get_storage/get_storage.dart';

/// A reply saved from an earlier API call, and when it was saved.
class SavedResponse {
  final dynamic data;
  final DateTime savedAt;

  const SavedResponse(this.data, this.savedAt);
}

/// Where `ApiClient` keeps the last reply of each GET request, so
/// screens can still show something when the phone is offline.
///
/// It's an interface so tests can use a simple in-memory version.
abstract class ApiCache {
  SavedResponse? read(String path);
  Future<void> write(String path, dynamic data);
  Future<void> clear();
}

/// The real cache: a GetStorage box on the device. Holds the student's
/// own data, so it's cleared on logout (see `AuthController.logout`).
class GetStorageApiCache implements ApiCache {
  /// Must be opened in `main()` with `GetStorage.init(boxName)` first.
  static const String boxName = 'api_cache';

  final GetStorage _box = GetStorage(boxName);

  @override
  SavedResponse? read(String path) {
    final saved = _box.read(path);
    if (saved is! Map) return null;

    final savedAt = DateTime.tryParse('${saved['savedAt']}');
    final body = saved['body'];
    if (savedAt == null || body is! String) return null;

    try {
      return SavedResponse(jsonDecode(body), savedAt);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String path, dynamic data) {
    return _box.write(path, {
      'savedAt': DateTime.now().toIso8601String(),
      'body': jsonEncode(data),
    });
  }

  @override
  Future<void> clear() => _box.erase();
}
