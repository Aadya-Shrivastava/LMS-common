import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../widgets/student/student_placeholder_screen.dart';

/// The student's notifications list. Placeholder for now.
class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentPlaceholderScreen(
      title: 'Notifications',
      currentRoute: Routes.studentNotifications,
      icon: Icons.notifications_outlined,
    );
  }
}
