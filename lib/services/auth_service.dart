import '../core/constants/app_urls.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage_service.dart';
import '../models/user_model.dart';

/// Handles logging a user in and out against the real backend.
class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Sends the email-or-username and password to the login API, saves
  /// the access and refresh tokens securely, and returns the user.
  ///
  /// Throws an `ApiException` if the login details are wrong or the
  /// server can't be reached.
  Future<UserModel> login({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    final data = await _apiClient.post(
      AppUrls.login,
      body: {'identifier': identifier, 'password': password},
      auth: false,
    );

    final access = data is Map ? data['access'] : null;
    final refresh = data is Map ? data['refresh'] : null;
    if (access is! String || refresh is! String) {
      throw const ApiException('Unexpected reply from the server.');
    }

    await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);

    // The login API only returns tokens, not the user's details, so we
    // start from what they typed. The dashboard fills in the real
    // name, course and batch right after (see `updateUserDetails`).
    final isEmail = identifier.contains('@');
    return UserModel(
      id: '',
      name: isEmail ? identifier.split('@').first : identifier,
      email: isEmail ? identifier : '',
      role: role,
    );
  }

  /// Asks the server to email a password-reset link (API 2). The reply
  /// is the same whether or not the email is registered, so we just
  /// pass the server's message on.
  Future<String> requestPasswordReset(String email) async {
    final data = await _apiClient.post(
      AppUrls.passwordReset,
      body: {'email': email},
      auth: false,
    );
    return _detail(
      data,
      'If an account with this email exists, a password reset link has been sent.',
    );
  }

  /// Changes the password (API 42). The server logs out every other
  /// device; this one stays logged in. Returns the server's message.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final data = await _apiClient.put(
      AppUrls.changePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      },
    );
    return _detail(data, 'Password updated.');
  }

  /// Logs out every other device, keeping this one (API 44). Returns
  /// the server's message, e.g. "Logged out of 2 other sessions."
  Future<String> logoutOtherSessions() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw const ApiException(ApiClient.sessionExpired);
    }

    final data = await _apiClient.post(
      AppUrls.logoutOtherSessions,
      body: {'refresh_token': refresh},
    );
    return _detail(data, 'Logged out of other devices.');
  }

  /// The server's `{"detail": "..."}` message, or `fallback`.
  String _detail(dynamic data, String fallback) {
    final detail = data is Map ? data['detail'] : null;
    return detail is String && detail.isNotEmpty ? detail : fallback;
  }

  /// Tells the server to cancel the refresh token (API 45), then
  /// removes both saved tokens so later API calls are no longer logged
  /// in. If the server can't be reached we still log out on this phone.
  Future<void> logout() async {
    final refresh = await _tokenStorage.getRefreshToken();

    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _apiClient.post(AppUrls.logout, body: {'refresh_token': refresh});
      } on ApiException {
        // Already expired or offline - nothing more to do on the server.
      }
    }

    await _tokenStorage.clearTokens();
  }
}
