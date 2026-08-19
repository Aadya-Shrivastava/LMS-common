import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/faculty/faculty_assignment_controller.dart';
import '../../../controllers/faculty/faculty_attendance_controller.dart';
import '../../../controllers/faculty/faculty_course_controller.dart';
import '../../../controllers/faculty/faculty_dashboard_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/dashboard_list_item_model.dart';
import 'package:lms/models/faculty/live_class_model.dart';
import 'package:lms/models/faculty/submission_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/quick_action_ring.dart';
import '../../../widgets/stat_pill.dart';
import '../../../widgets/status_list_tile.dart';

/// The faculty home screen.
///
/// Layout, from top to bottom, exactly as designed:
///   1. A full navy app bar: drawer menu, department name + designation,
///      and notification + profile icons in the corner
///   2. A blue gradient "Welcome back, {name}" card with a short tagline
///   3. Four stat cards in a 2x2 grid, each with its own accent color
///   4. Today's Schedule (with a "Manage" link to Live Classes)
///   5. Pending Grading (with a "View All" link to Assignments)
///   6. Recent Submissions (with a "View All" link to Assignments)
///
/// `GetView<FacultyDashboardController>` is a GetX shortcut: it gives us
/// a `controller` property automatically, already connected to the
/// FacultyDashboardController that FacultyBinding created for us.
class FacultyDashboardScreen extends GetView<FacultyDashboardController> {
  const FacultyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // `AnnotatedRegion` tells the phone's status bar (the strip with the
    // clock, battery, signal icons) to use light/white icons instead of
    // its usual dark ones, since our navy header sits right behind it -
    // dark icons on a dark background would be invisible.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        // The side drawer (our navigation menu) instead of a bottom nav bar.
        drawer: const AppDrawer(currentRoute: Routes.facultyDashboard),
        // No SafeArea here on purpose: we want the navy header's color to
        // paint all the way to the very top of the screen, behind the
        // status bar, instead of leaving a plain white gap above it.
        // `_buildNavyHeader` adds its own top padding to keep the menu
        // icon/text below the status bar, and the scrollable content
        // below is wrapped in its own SafeArea further down.
        body: Column(
          children: [
            _buildNavyHeader(context, authController),

            // `Obx` rebuilds everything inside it whenever a value it
            // depends on changes (like `controller.isLoading`).
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const CustomLoader();
                }

                return RefreshIndicator(
                  onRefresh: controller.loadDashboardData,
                  child: SafeArea(
                    top: false,
                    child: _buildDashboardContent(authController),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// The full navy app bar: the hamburger menu (opens the drawer), the
  /// department name with the designation underneath it, and the
  /// notification + profile icons in the top-right corner.
  ///
  /// The extra `MediaQuery.of(context).padding.top` in the padding below
  /// is the height of the status bar - adding it here (instead of using
  /// SafeArea around the whole header) keeps the navy background full-
  /// bleed to the top of the screen while still keeping the icons and
  /// text safely below the status bar.
  Widget _buildNavyHeader(BuildContext context, AuthController authController) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: EdgeInsets.fromLTRB(4, statusBarHeight + 4, 4, 4),
      child: Row(
        children: [
          // `Builder` gives us a BuildContext that is actually "inside"
          // the Scaffold, which is required for `Scaffold.of(context)`
          // to be able to find and open the drawer.
          Builder(
            builder: (innerContext) {
              return IconButton(
                icon: const Icon(Icons.menu, color: AppColors.white),
                onPressed: () => Scaffold.of(innerContext).openDrawer(),
              );
            },
          ),
          Expanded(
            child: Obx(() {
              final user = authController.currentUser.value;
              final department = user?.department ?? 'Department';
              final designation = user?.designation ?? '';

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    department,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (designation.isNotEmpty)
                    Text(
                      designation,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              );
            }),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
            tooltip: 'Notifications',
            onPressed: () => Get.toNamed(Routes.facultyNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.white),
            tooltip: 'Profile',
            onPressed: () => Get.toNamed(Routes.facultyAccountSettings),
          ),
        ],
      ),
    );
  }

  /// Everything below the navy header: the welcome card, the stat
  /// cards, and the three lists. This is all inside one scrollable
  /// list so it works on small phone screens too.
  Widget _buildDashboardContent(AuthController authController) {
    final name = authController.currentUser.value?.name ?? 'Faculty';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(name),
        const SizedBox(height: 24),

        const Text(
          'TEACHING OVERVIEW',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatsStrip(),
        const SizedBox(height: 24),

        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickActionsRow(),
        const SizedBox(height: 24),

        _buildSection(
          title: "Today's Schedule",
          items: controller.todaysSchedule,
          sectionIcon: Icons.calendar_today_outlined,
          accentColor: AppColors.statCardRed,
          backgroundColor: AppColors.sectionRedBg,
          actionLabel: 'Manage',
          onActionTap: () => Get.toNamed(Routes.facultyLiveClasses),
        ),
        const SizedBox(height: 16),

        _buildSection(
          title: 'Pending Grading',
          items: controller.pendingGrading,
          sectionIcon: Icons.edit_note_outlined,
          accentColor: AppColors.statCardGreen,
          backgroundColor: AppColors.sectionGreenBg,
          actionLabel: 'View All',
          onActionTap: () => Get.toNamed(Routes.facultyAssignments),
        ),
        const SizedBox(height: 16),

        _buildSection(
          title: 'Recent Submissions',
          items: controller.recentSubmissions,
          sectionIcon: Icons.task_alt_outlined,
          accentColor: AppColors.statCardBlue,
          backgroundColor: AppColors.sectionBlueBg,
          actionLabel: 'View All',
          onActionTap: () => Get.toNamed(Routes.facultyAssignments),
          useAvatarForItems: true,
        ),
      ],
    );
  }

  /// The rounded, blue-gradient card that greets the faculty member,
  /// e.g. "Welcome back, Dr. Sharma" + a short tagline underneath.
  Widget _buildWelcomeCard(String name) {
    return ClipRRect(
      // Clipping to the same rounded shape as the card keeps the big
      // watermark icon below from poking outside the corners.
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // `Stack` lets us place the big faint icon behind the text.
        child: Stack(
          children: [
            // A large, mostly-transparent icon in the corner, purely
            // decorative - it fills the empty space and gives the card
            // a bit more visual personality.
            Positioned(
              right: -10,
              bottom: -18,
              child: Icon(
                Icons.school_outlined,
                size: 100,
                color: AppColors.white.withValues(alpha: 0.08),
              ),
            ),
            _buildWelcomeCardText(name),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCardText(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome back, $name',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Here's your teaching overview for today",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  /// The fixed 2x2 grid of stat pills at the top of the dashboard -
  /// Students above Classes on the left, To Grade above Attendance on
  /// the right. No sliding: everything is visible at once. Each pill
  /// is tappable and jumps straight to the screen that stat is about.
  Widget _buildStatsStrip() {
    return Obx(() {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatPill(
                    title: 'Students',
                    value: '${controller.myStudentsCount.value}',
                    icon: Icons.groups_outlined,
                    accentColor: AppColors.statCardOrange,
                    onTap: () => Get.toNamed(Routes.facultyStudentPerformance),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatPill(
                    title: 'To grade',
                    value: '${controller.assignmentsToGradeCount}',
                    icon: Icons.edit_note_outlined,
                    accentColor: AppColors.statCardGreen,
                    onTap: () => Get.toNamed(Routes.facultyAssignments),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatPill(
                    title: 'Classes',
                    value: '${controller.classesTodayCount}',
                    icon: Icons.event_outlined,
                    accentColor: AppColors.statCardRed,
                    onTap: () => Get.toNamed(Routes.facultyLiveClasses),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatPill(
                    title: 'Attendance',
                    value: '${controller.averageAttendance.round()}%',
                    icon: Icons.fact_check_outlined,
                    accentColor: AppColors.statCardBlue,
                    onTap: () => Get.toNamed(Routes.facultyAttendance),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// The row of progress rings below the stats strip. Each ring shows
  /// how much of that area's work is done - e.g. how many students
  /// are marked present, or how many submissions are graded - computed
  /// fresh from the other faculty controllers every time this rebuilds.
  /// That's what makes the rings "dynamic": mark another student
  /// present, or grade another submission, and the ring fills in
  /// immediately.
  Widget _buildQuickActionsRow() {
    // These controllers are already created by `FacultyBinding` (every
    // faculty route, including the dashboard, uses it), so `Get.find`
    // just hands us the same live instances those other screens use.
    final courseController = Get.find<FacultyCourseController>();
    final assignmentController = Get.find<FacultyAssignmentController>();
    final attendanceController = Get.find<FacultyAttendanceController>();

    return Obx(() {
      // Attendance: how many students are currently ticked "present".
      final totalStudents = attendanceController.manualRows.length;
      final presentCount =
          attendanceController.manualRows.where((row) => row.isPresent).length;

      // Assignments: how many of the active assignment's submissions
      // have been graded so far.
      final totalSubmissions = assignmentController.activeSubmissions.length;
      final gradedCount = assignmentController.activeSubmissions
          .where((submission) => submission.status == SubmissionStatus.graded)
          .length;
      final pendingCount = totalSubmissions - gradedCount;

      // Materials: how many of the 2 known subjects have at least one
      // uploaded material.
      const totalSubjects = 2;
      final coveredSubjects =
          courseController.materials.map((material) => material.subject).toSet().length;

      // Live classes: how many scheduled classes have already happened.
      final totalClasses = courseController.scheduledClasses.length;
      final completedClasses = courseController.scheduledClasses
          .where((liveClass) => liveClass.status == LiveClassStatus.completed)
          .length;

      return SizedBox(
        height: 108,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            QuickActionRing(
              icon: Icons.fact_check_outlined,
              label: 'Attendance',
              subtitle: totalStudents == 0 ? 'No students' : '$presentCount/$totalStudents present',
              progress: totalStudents == 0 ? 0 : presentCount / totalStudents,
              accentColor: AppColors.statCardRed,
              onTap: () => Get.toNamed(Routes.facultyAttendance),
            ),
            QuickActionRing(
              icon: Icons.edit_note_outlined,
              label: 'Assignments',
              subtitle: pendingCount == 0 ? 'All graded' : '$pendingCount left',
              progress: totalSubmissions == 0 ? 0 : gradedCount / totalSubmissions,
              accentColor: AppColors.statCardGreen,
              onTap: () => Get.toNamed(Routes.facultyAssignments),
            ),
            QuickActionRing(
              icon: Icons.upload_file_outlined,
              label: 'Materials',
              subtitle: '$coveredSubjects/$totalSubjects subjects',
              progress: coveredSubjects / totalSubjects,
              accentColor: AppColors.statCardOrange,
              onTap: () => Get.toNamed(Routes.facultyStudyMaterial),
            ),
            QuickActionRing(
              icon: Icons.videocam_outlined,
              label: 'Live class',
              subtitle: totalClasses == 0 ? 'None yet' : '$completedClasses/$totalClasses done',
              progress: totalClasses == 0 ? 0 : completedClasses / totalClasses,
              accentColor: AppColors.statCardBlue,
              onTap: () => Get.toNamed(Routes.facultyLiveClasses),
            ),
            QuickActionRing(
              icon: Icons.calendar_month_outlined,
              label: 'Timetable',
              subtitle: 'All set',
              progress: 1,
              accentColor: AppColors.statusPurple,
              onTap: () => Get.toNamed(Routes.facultyTimetable),
            ),
          ],
        ),
      );
    });
  }

  /// A whole colored card for one dashboard list section - "Today's
  /// Schedule", "Pending Grading", or "Recent Submissions".
  ///
  /// Each section gets its own accent color for the header's icon badge
  /// and pill button (which is what "Manage" and "View All" are), and
  /// an extremely light, flat tint of that color as the card's
  /// background - just enough to hint "this section is red/green/blue"
  /// without the card ever looking like a loud block of color.
  Widget _buildSection({
    required String title,
    required List<DashboardListItem> items,
    required IconData sectionIcon,
    required Color accentColor,
    required Color backgroundColor,
    String? actionLabel,
    VoidCallback? onActionTap,
    bool useAvatarForItems = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A solid-colored icon badge, matching the style of
                  // the stat cards above, so the whole screen feels
                  // like one consistent design.
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(sectionIcon, size: 17, color: AppColors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onActionTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            StatusListTile(item: item, useAvatar: useAvatarForItems),
        ],
      ),
    );
  }
}
