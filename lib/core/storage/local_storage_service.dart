import 'package:get_storage/get_storage.dart';
import '../../models/user_model.dart';

/// A small helper for saving and reading simple values on the user's
/// device, like "is someone logged in" and "who are they".
///
/// We wrap the `GetStorage` package here so the rest of the app doesn't
/// need to know exactly which storage package we use. If we ever swap
/// GetStorage for something else, we only have to change this one file.
///
/// This is also what makes the user stay logged in between app opens:
/// we save their info here when they log in, and read it back the next
/// time the app starts, instead of asking them to log in again.
class LocalStorageService {
  // GetStorage is like a small key-value box saved on the device.
  final GetStorage _box = GetStorage();

  // Keys are just the names we use to save/read each value.
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUser = 'user';

  bool get isLoggedIn => _box.read(_keyIsLoggedIn) ?? false;

  /// Saves the logged-in user so they're remembered next time the app
  /// opens, instead of having to log in again.
  Future<void> saveSession(UserModel user) async {
    await _box.write(_keyIsLoggedIn, true);
    await _box.write(_keyUser, user.toJson());
  }

  /// Reads back the user that was saved by `saveSession`, or returns
  /// null if nobody is logged in (or nothing was saved yet).
  UserModel? getSavedUser() {
    if (!isLoggedIn) return null;

    final userJson = _box.read(_keyUser);
    if (userJson == null) return null;

    // GetStorage gives the map back as `Map<String, dynamic>`, but just
    // to be safe we make sure it's the right type before using it.
    return UserModel.fromJson(Map<String, dynamic>.from(userJson));
  }

  /// Clears everything we saved, used when the user logs out.
  Future<void> clearSession() async {
    await _box.remove(_keyIsLoggedIn);
    await _box.remove(_keyUser);
  }
}
