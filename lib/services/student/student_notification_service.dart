import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_parsers.dart';
import '../../models/notification_model.dart';

/// Loads the student's notifications from `AppUrls.notifications`
/// (API 40), newest first, and marks them all read (API 41).
class StudentNotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<void> markAllRead() async {
    await _apiClient.post(AppUrls.markAllNotificationsRead);
  }

  Future<List<NotificationModel>> getNotifications() async {
    final items = jsonList(await _apiClient.get(AppUrls.notifications));

    final notifications = items
        // Notifications the office switched off shouldn't be shown.
        .where((item) => item['is_active'] != false)
        .map((item) => NotificationModel(
              id: jsonString(item['id']),
              title: jsonString(item['title']),
              // Messages come with Windows line breaks ("\r\n").
              body: jsonString(item['message']).replaceAll('\r\n', '\n'),
              createdAt: jsonDate(item['created_at']) ?? DateTime.now(),
              isRead: item['is_read'] == true,
              attachmentUrl: jsonString(item['attachment']),
            ))
        .toList();

    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }
}
