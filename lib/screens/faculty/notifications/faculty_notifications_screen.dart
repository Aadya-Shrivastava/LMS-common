import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/widgets/faculty/faculty_placeholder_screen.dart';

/// The faculty notifications screen. Not part of the drawer list the
/// user asked for, but kept here so the folder structure matches the
/// planned architecture, in case it's needed later (e.g. a bell icon
/// in a future header).
class FacultyNotificationsScreen extends StatelessWidget {
  const FacultyNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FacultyPlaceholderScreen(
      title: 'Notifications',
      currentRoute: Routes.facultyNotifications,
      icon: Icons.notifications_outlined,
    );
  }
}
