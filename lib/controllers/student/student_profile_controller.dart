import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/network/saved_then_fresh.dart';
import 'package:lms/models/student/student_profile_model.dart';
import 'package:lms/models/student/student_record_model.dart';
import 'package:lms/services/student/student_profile_service.dart';
import 'package:lms/services/student/student_record_service.dart';
import '../../services/auth_service.dart';

/// Holds the student's profile data for the Account Settings screen:
/// the profile itself (API 5), the summary from their student record
/// (API 4), and the devices they're logged in on (API 43). Also saves
/// contact details (API 6), changes the password (API 42) and logs out
/// other devices (API 44).
class StudentProfileController extends GetxController {
  final StudentProfileService _service = StudentProfileService();
  final StudentRecordService _recordService = StudentRecordService();
  final AuthService _authService = AuthService();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final Rx<StudentProfileModel?> profile = Rx<StudentProfileModel?>(null);

  /// Null if the record couldn't be loaded - the screen just hides the
  /// cards that use it.
  final Rx<StudentRecordModel?> record = Rx<StudentRecordModel?>(null);
  final RxList<ActiveSessionModel> activeSessions = <ActiveSessionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    errorMessage.value = null;

    // The record and sessions are extras, loaded alongside: if they
    // fail, the profile still shows instead of an error page.
    final extrasDone = Future.wait([
      loadSavedThenFresh(() => _recordService.getRecord(fresh: true), (data) => record.value = data),
      loadSavedThenFresh(_recordService.getActiveSessions, activeSessions.assignAll),
    ]);

    errorMessage.value = await loadSavedThenFresh(_service.getProfile, (data) {
      profile.value = data;
      isLoading.value = false;
    });
    isLoading.value = false;
    await extrasDone;
  }

  /// True while contact details, a password change or a "log out other
  /// devices" request is being sent.
  final RxBool isSaving = false.obs;

  /// Saves contact details (API 6) and reloads the profile. Returns the
  /// message to show (success or error).
  Future<String> saveContactDetails({
    required String mobile,
    required String guardianMobile,
    required String address,
  }) {
    return _save(() async {
      final message = await _service.updateContactDetails(
        mobile: mobile,
        guardianMobile: guardianMobile,
        address: address,
      );
      await loadProfile();
      return message;
    });
  }

  /// Changes the password (API 42), then refreshes the device list
  /// since the server logs out every other device.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return _save(() async {
      final message = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      await _reloadSessions();
      return message;
    });
  }

  /// Logs out every other device (API 44).
  Future<String> logoutOtherDevices() {
    return _save(() async {
      final message = await _authService.logoutOtherSessions();
      await _reloadSessions();
      return message;
    });
  }

  Future<void> _reloadSessions() async {
    activeSessions.assignAll(await _optional(_recordService.getActiveSessions()) ?? const []);
  }

  Future<String> _save(Future<String> Function() action) async {
    isSaving.value = true;
    try {
      return await action();
    } catch (e) {
      return ApiClient.messageFor(e);
    } finally {
      isSaving.value = false;
    }
  }

  /// Waits for `future`, giving back null instead of an error.
  Future<T?> _optional<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }
}
