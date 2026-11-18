import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_notification_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/link_opener.dart';
import '../../../models/notification_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/student/student_drawer.dart';

/// The student's notifications: notices from the institute, newest
/// first. Tapping one shows the full message and any attachment.
class StudentNotificationsScreen extends GetView<StudentNotificationController> {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Notifications',
        subtitle: 'Notices and updates from your institute',
        fallbackRoute: Routes.studentDashboard,
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentNotifications),
      body: Obx(() {
        final error = controller.errorMessage.value;
        if (error != null && !controller.hasLoaded) {
          return ErrorStateWidget(message: error, onRetry: controller.loadNotifications);
        }
        if (controller.isLoading.value && !controller.hasLoaded) {
          return const CustomLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.loadNotifications,
          child: controller.notifications.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    EmptyStateWidget(
                      icon: Icons.notifications_none_outlined,
                      title: 'No notifications',
                      message: "You're all caught up.",
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (controller.unreadCount > 0)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${controller.unreadCount} unread',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: controller.isMarkingRead.value
                                ? null
                                : () async {
                                    final error = await controller.markAllRead();
                                    if (error != null && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(error)));
                                    }
                                  },
                            icon: const Icon(Icons.done_all, size: 18),
                            label: const Text('Mark all read'),
                          ),
                        ],
                      ),
                    for (final notification in controller.notifications) ...[
                      _NotificationCard(notification: notification),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        );
      }),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  Future<void> _open(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(notification.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDateTime(notification.createdAt),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(notification.body, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
          actions: [
            if (notification.attachmentUrl.isNotEmpty)
              TextButton.icon(
                onPressed: () => openLink(notification.attachmentUrl),
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Attachment'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead ? AppColors.cardBorder : AppColors.primaryNavy,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              notification.isRead ? Icons.notifications_none_outlined : Icons.notifications_active,
              color: AppColors.primaryNavy,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          formatDateTime(notification.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      if (notification.attachmentUrl.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.attach_file, size: 14, color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
