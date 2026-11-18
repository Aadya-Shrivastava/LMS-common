import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

/// The side menu (drawer) used on the student side of the app - the
/// student equivalent of `AppDrawer`. Same navy look and grouped-list
/// layout, just with the routes a student actually has.
class StudentDrawer extends StatelessWidget {
  final String currentRoute;

  const StudentDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Drawer(
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
              route: Routes.studentDashboard,
            ),

            _buildSectionLabel('Learning'),
            _buildItem(
              icon: Icons.videocam_outlined,
              label: 'Live Classes',
              route: Routes.studentLiveClasses,
            ),
            _buildItem(
              icon: Icons.calendar_month_outlined,
              label: 'My Timetable',
              route: Routes.studentTimetable,
            ),
            _buildItem(
              icon: Icons.menu_book_outlined,
              label: 'Study Materials',
              route: Routes.studentCourses,
            ),
            _buildItem(
              icon: Icons.assignment_outlined,
              label: 'Assignments',
              route: Routes.studentAssignments,
            ),
            _buildItem(
              icon: Icons.fact_check_outlined,
              label: 'Exams & Results',
              route: Routes.studentExamsResults,
            ),

            _buildSectionLabel('Records'),
            _buildItem(
              icon: Icons.fact_check_outlined,
              label: 'Attendance',
              route: Routes.studentAttendance,
            ),
            // Self attendance is switched off for now (no backend API yet).
            // _buildItem(
            //   icon: Icons.qr_code_scanner_outlined,
            //   label: 'Self Attendance (QR)',
            //   route: Routes.studentSelfAttendanceQr,
            // ),
            _buildItem(
              icon: Icons.currency_rupee_outlined,
              label: 'Fees',
              route: Routes.studentFees,
            ),
            _buildItem(
              icon: Icons.workspace_premium_outlined,
              label: 'Certificates',
              route: Routes.studentCertificates,
            ),
            _buildItem(
              icon: Icons.work_outline,
              label: 'Placements',
              route: Routes.studentPlacements,
            ),
            _buildItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              route: Routes.studentNotifications,
            ),

            _buildSectionLabel('Account'),
            _buildItem(
              icon: Icons.person_outline,
              label: 'My Profile',
              route: Routes.studentProfile,
            ),
            _buildItem(
              icon: Icons.settings_outlined,
              label: 'Account Settings',
              route: Routes.studentAccountSettings,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () => authController.logout(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthController authController) {
    return Obx(() {
      final user = authController.currentUser.value;
      final name = user?.name ?? 'Student';
      final department = user?.department ?? '';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

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
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (department.isNotEmpty)
                    Text(
                      department,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        onTap: () {
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
