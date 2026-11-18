import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Saves and reads the login tokens the backend gives us.
///
/// Tokens are like passwords for the API, so we keep them in the
/// device's secure storage (Keychain on iOS, Keystore-backed storage on
/// Android) instead of `GetStorage`, which saves plain text.
///
/// - The **access** token is sent with every API call.
/// - The **refresh** token is kept so we can get a new access token later.
class TokenStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  /// Saves both tokens after a successful login.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  /// The saved access token, or null if nobody is logged in.
  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);

  /// The saved refresh token, or null if nobody is logged in.
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  /// Removes both tokens, used when the user logs out.
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}
