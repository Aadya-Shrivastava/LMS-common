import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

/// The side menu (drawer) used on every faculty screen, instead of a
/// bottom navigation bar.
///
/// It's split into the same groups the user asked for:
///   Main -> Teaching -> Students -> Account
///
/// Tapping an item takes you to that screen. Tapping "Logout" logs the
/// user out instead of navigating.
class AppDrawer extends StatelessWidget {
  /// The route of the screen currently being shown, so we can highlight
  /// the matching drawer item. Pass in `Routes.facultyDashboard` etc.
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    // `Get.find` looks up the AuthController that was already created
    // when the app started (see app.dart), so we can show the user's
    // name here and call logout() when needed.
    final authController = Get.find<AuthController>();

    return Drawer(
      // The drawer's background color (navy) comes from AppTheme.
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(authController),
            const SizedBox(height: 8),

            _buildSectionLabel('Main'),
            _buildItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              route: Routes.facultyDashboard,
            ),

            _buildSectionLabel('Teaching'),
            _buildItem(
              icon: Icons.videocam_outlined,
              label: 'Live Classes',
              route: Routes.facultyLiveClasses,
            ),
            _buildItem(
              icon: Icons.calendar_month_outlined,
              label: 'My Timetable',
              route: Routes.facultyTimetable,
            ),
            _buildItem(
              icon: Icons.upload_file_outlined,
              label: 'Study Material',
              route: Routes.facultyStudyMaterial,
            ),
            _buildItem(
              icon: Icons.assignment_outlined,
              label: 'Assignments',
              route: Routes.facultyAssignments,
            ),
            _buildItem(
              icon: Icons.quiz_outlined,
              label: 'Question Bank & Tests',
              route: Routes.facultyQuestionBank,
            ),

            _buildSectionLabel('Students'),
            _buildItem(
              icon: Icons.fact_check_outlined,
              label: 'Attendance',
              route: Routes.facultyAttendance,
            ),
            _buildItem(
              icon: Icons.bar_chart_outlined,
              label: 'Student Performance',
              route: Routes.facultyStudentPerformance,
            ),

            _buildSectionLabel('Account'),
            _buildItem(
              icon: Icons.settings_outlined,
              label: 'Account Settings',
              route: Routes.facultyAccountSettings,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => authController.logout(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// The top part of the drawer: an avatar circle with the user's
  /// initial, their name, and their designation.
  Widget _buildHeader(AuthController authController) {
    return Obx(() {
      final user = authController.currentUser.value;
      final name = user?.name ?? 'Faculty Member';
      final designation = user?.designation ?? '';
      // Take the first letter of the name to show inside the avatar circle.
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.white.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (designation.isNotEmpty)
                    Text(
                      designation,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// A small grey label used above each group of drawer items,
  /// e.g. "TEACHING".
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// One tappable row in the drawer, e.g. "Live Classes".
  /// If its route matches the screen we're currently on, it's
  /// highlighted so the user can see where they are.
  Widget _buildItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = route == currentRoute;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.white.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        onTap: () {
          // If we're already on this screen, just close the drawer.
          if (isActive) {
            Get.back();
            return;
          }
          Get.offNamed(route);
        },
      ),
    );
  }
}
