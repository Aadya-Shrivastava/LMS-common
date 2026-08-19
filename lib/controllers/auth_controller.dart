import 'package:get/get.dart';
import '../core/routes/app_routes.dart';
import '../core/storage/local_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Keeps track of who is currently logged in, and handles logging in
/// and logging out.
///
/// This controller is registered once, when the app starts (see
/// `app.dart`), so it stays alive for the whole app and any screen can
/// ask it "who is the current user?" at any time.
class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final LocalStorageService _localStorageService = LocalStorageService();

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
  }

  /// True if we already have a logged-in user (either from this app
  /// session, or restored from a previous one). The splash screen uses
  /// this to decide whether to show the login screen or skip straight
  /// to the right dashboard.
  bool get isLoggedIn => currentUser.value != null;

  /// The dashboard route that matches the current user's role.
  /// Only meaningful when `isLoggedIn` is true.
  String get dashboardRoute {
    return currentUser.value?.role == UserRole.faculty
        ? Routes.facultyDashboard
        : Routes.studentDashboard;
  }

  /// Attempts to log the user in, then sends them to the right dashboard
  /// depending on their role (student or faculty).
  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    isLoading.value = true;

    try {
      final user = await _authService.login(
        email: email,
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
    } finally {
      isLoading.value = false;
    }
  }

  /// Logs the current user out and sends them back to the login screen.
  Future<void> logout() async {
    currentUser.value = null;
    await _localStorageService.clearSession();
    Get.offAllNamed(Routes.login);
  }
}
