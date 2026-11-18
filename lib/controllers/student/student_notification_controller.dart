import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/network/saved_then_fresh.dart';
import '../../models/notification_model.dart';
import '../../services/student/student_notification_service.dart';

/// Holds the student's notifications for the Notifications screen.
class StudentNotificationController extends GetxController {
  final StudentNotificationService _service = StudentNotificationService();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  bool hasLoaded = false;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    errorMessage.value = null;

    errorMessage.value = await loadSavedThenFresh(_service.getNotifications, (data) {
      notifications.assignAll(data);
      hasLoaded = true;
      isLoading.value = false;
    });
    isLoading.value = false;
  }

  /// True while "Mark all read" is being sent.
  final RxBool isMarkingRead = false.obs;

  /// Marks every notification as read on the server (API 41), then
  /// reloads the list. Returns an error message, or null if it worked.
  Future<String?> markAllRead() async {
    isMarkingRead.value = true;
    try {
      await _service.markAllRead();
      await loadNotifications();
      return null;
    } catch (e) {
      return ApiClient.messageFor(e);
    } finally {
      isMarkingRead.value = false;
    }
  }
}
