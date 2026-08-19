import '../models/notification_model.dart';

/// Provides the notifications shown to a user, e.g. "Your assignment
/// was graded" or "New announcement posted".
class NotificationService {
  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      NotificationModel(
        id: 'n1',
        title: 'New submission',
        body: 'Priya Nair submitted Linked List Implementation.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'n2',
        title: 'Reminder',
        body: 'You have 24 assignments waiting to be graded.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
    ];
  }
}
