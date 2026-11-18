import 'package:get/get.dart';
import '../core/routes/app_routes.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/token_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/student/student_record_service.dart';

/// Keeps track of who is currently logged in, and handles logging in
/// and logging out.
///
/// This controller is registered once, when the app starts (see
/// `app.dart`), so it stays alive for the whole app and any screen can
/// ask it "who is the current user?" at any time.
class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// The currently logged-in user, or null if nobody is logged in.
  /// It's an `Rx` value, which means any widget using `Obx(...)` will
  /// automatically rebuild whenever this changes.
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  /// True while a login request is in progress, so the UI can show
  /// a loading spinner and disable the login button.
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // If someone logged in before and never logged out, restore their
    // session now. This is what keeps the user logged in between app
    // opens instead of asking them to log in every single time.
    currentUser.value = _localStorageService.getSavedUser();

    // If both tokens expire mid-use, ApiClient calls this so the user is
    // sent back to the login screen.
    ApiClient.onSessionExpired = () {
      if (isLoggedIn) logout();
    };
  }

  /// True if we already have a logged-in user (either from this app
  /// session, or restored from a previous one). The splash screen uses
  /// this to decide whether to show the login screen or skip straight
  /// to the right dashboard.
  bool get isLoggedIn => currentUser.value != null;

  /// Logs out a saved user who has no access token (for example, one
  /// saved by the old fake login), so they're sent to the login screen
  /// instead of a dashboard where every API call would fail.
  /// The splash screen calls this before checking `isLoggedIn`.
  Future<void> checkSavedSession() async {
    if (currentUser.value == null) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      currentUser.value = null;
      await _localStorageService.clearSession();
    }
  }

  /// The dashboard route that matches the current user's role.
  /// Only meaningful when `isLoggedIn` is true.
 String get dashboardRoute { 
  return Routes.studentDashboard; 
}


  /// Attempts to log the user in, then sends them to the right dashboard
  /// depending on their role (student or faculty).
  Future<void> login({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    isLoading.value = true;

    try {
      final user = await _authService.login(
        identifier: identifier,
        password: password,
        role: role,
      );

      currentUser.value = user;

      // Save the user to the device so `AuthController.onInit()` can
      // restore this same session the next time the app is opened.
      await _localStorageService.saveSession(user);

      // `offAllNamed` clears the login screen from history, so the user
      // can't accidentally go "back" to the login page after logging in.
      Get.offAllNamed(dashboardRoute);
    } catch (e) {
      // Wrong password, no internet, server down, etc.
      Get.snackbar(
        'Login failed',
        ApiClient.messageFor(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Replaces the placeholder name/course/batch saved at login with the
  /// real ones from the API. Empty values are ignored.
  Future<void> updateUserDetails({
    required String name,
    required String department,
    required String designation,
  }) async {
    final user = currentUser.value;
    if (user == null) return;

    final updated = UserModel(
      id: user.id,
      name: name.isNotEmpty ? name : user.name,
      email: user.email,
      role: user.role,
      department: department.isNotEmpty ? department : user.department,
      designation: designation.isNotEmpty ? designation : user.designation,
      avatarUrl: user.avatarUrl,
    );

    currentUser.value = updated;
    await _localStorageService.saveSession(updated);
  }

  /// Logs the current user out and sends them back to the login screen.
  Future<void> logout() async {
    currentUser.value = null;
    StudentRecordService.clearCache();
    await _authService.logout();

    // The saved offline copies are this student's data - don't leave
    // them for whoever logs in next on this phone.
    await ApiClient.cache?.clear();
    ApiClient.showingSavedDataFrom.value = null;
    await _localStorageService.clearSession();
    Get.offAllNamed(Routes.login);
  }
}
