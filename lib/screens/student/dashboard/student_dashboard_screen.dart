import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/student/student_dashboard_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/dashboard_list_item_model.dart';
import 'package:lms/models/student/course_progress_model.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/quick_action_ring.dart';
import '../../../widgets/stat_pill.dart';
import '../../../widgets/status_list_tile.dart';
import 'package:lms/widgets/student/student_drawer.dart';

/// The student home screen.
///
/// Built to match the faculty dashboard's layout exactly:
///   1. A full navy app bar: drawer menu, course/batch name, and a
///      single notification + profile icon in the corner (the
///      prototype's separate "message" and "notification" icons are
///      merged into one "Notifications" icon here)
///   2. A navy gradient "Hi {name}" welcome card with a short tagline
///   3. Four stat pills in a 2x2 grid
///   4. A row of Quick Action rings
///   5. Today's Class Schedule, Course Progress, and Pending
///      Assignments - no "Recent Notifications" section, by design.
class StudentDashboardScreen extends GetView<StudentDashboardController> {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        drawer: const StudentDrawer(currentRoute: Routes.studentDashboard),
        body: Column(
          children: [
            _buildNavyHeader(context, authController),
            Expanded(
              child: Obx(() {
                final error = controller.errorMessage.value;
                if (error != null && controller.stats.value == null) {
                  return ErrorStateWidget(message: error, onRetry: controller.loadDashboardData);
                }

                if (controller.isLoading.value && controller.stats.value == null) {
                  return const CustomLoader(layout: SkeletonLayout.dashboard);
                }

                return RefreshIndicator(
                  onRefresh: controller.loadDashboardData,
                  child: SafeArea(top: false, child: _buildDashboardContent(authController)),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// The navy app bar: hamburger menu, course + batch name, and the
  /// merged notification icon + profile icon in the top-right corner.
  Widget _buildNavyHeader(BuildContext context, AuthController authController) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: EdgeInsets.fromLTRB(4, statusBarHeight + 4, 4, 4),
      child: Row(
        children: [
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
              final course = user?.department ?? 'Course';
              final batch = user?.designation ?? '';

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (batch.isNotEmpty)
                    Text(
                      batch,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              );
            }),
          ),
          // The prototype has two separate icons here (a message icon
          // and a notification icon) - merged into one, since both are
          // really just "things that need your attention".
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
            tooltip: 'Notifications',
            onPressed: () => Get.toNamed(Routes.studentNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.white),
            tooltip: 'Profile',
            onPressed: () => Get.toNamed(Routes.studentProfile),
          ),
        ],
      ),
    );
  }

  /// Everything below the navy header: the welcome card, the stat
  /// pills, the quick actions row, and the three list sections.
  Widget _buildDashboardContent(AuthController authController) {
    final name = authController.currentUser.value?.name ?? 'Student';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(name),
        const SizedBox(height: 24),

        const Text(
          'MY OVERVIEW',
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
          title: "Today's Class Schedule",
          items: controller.todaysClassSchedule,
          sectionIcon: Icons.calendar_today_outlined,
          accentColor: AppColors.statCardRed,
          backgroundColor: AppColors.sectionRedBg,
          actionLabel: 'View All',
          onActionTap: () => Get.toNamed(Routes.studentLiveClasses),
        ),
        const SizedBox(height: 16),

        _buildCourseProgressSection(),
        const SizedBox(height: 16),

        _buildSection(
          title: 'Pending Assignments',
          items: controller.pendingAssignments,
          sectionIcon: Icons.assignment_late_outlined,
          accentColor: AppColors.statCardGreen,
          backgroundColor: AppColors.sectionGreenBg,
          actionLabel: 'View All',
          onActionTap: () => Get.toNamed(Routes.studentAssignments),
        ),
      ],
    );
  }

  /// The rounded, navy-gradient card that greets the student, e.g.
  /// "Hi Rahul" + a short tagline underneath.
  Widget _buildWelcomeCard(String name) {
    return ClipRRect(
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
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -18,
              child: Icon(
                Icons.menu_book_outlined,
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
    final firstName = name.trim().split(RegExp(r'\s+')).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hi $firstName',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          "Here's your learning snapshot for today",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  /// The fixed 2x2 grid of stat pills: Attendance/Assignments Done on
  /// top, Upcoming Exams/Fee Due below. Each pill jumps to the screen
  /// that stat is about.
  Widget _buildStatsStrip() {
    return Obx(() {
      final stats = controller.stats.value;
      if (stats == null) return const SizedBox.shrink();

      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatPill(
                    title: 'Attendance',
                    value: '${stats.attendancePercent.round()}%',
                    icon: Icons.fact_check_outlined,
                    accentColor: AppColors.statCardBlue,
                    onTap: () => Get.toNamed(Routes.studentAttendance),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatPill(
                    title: 'Assignments Done',
                    value: stats.assignmentsDoneText,
                    icon: Icons.assignment_turned_in_outlined,
                    accentColor: AppColors.statCardGreen,
                    onTap: () => Get.toNamed(Routes.studentAssignments),
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
                    title: 'Upcoming Exams',
                    value: '${stats.upcomingExamsCount}',
                    icon: Icons.event_note_outlined,
                    accentColor: AppColors.statCardOrange,
                    onTap: () => Get.toNamed(Routes.studentExamsResults),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatPill(
                    title: 'Fee Due',
                    value: stats.feeDueText,
                    icon: Icons.currency_rupee_outlined,
                    accentColor: AppColors.statusPurple,
                    onTap: () => Get.toNamed(Routes.studentFees),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// The row of progress rings below the stats strip - Attendance,
  /// Assignments, Fees, Live Class, and Timetable - each pointing at
  /// the real screen it summarizes.
  Widget _buildQuickActionsRow() {
    return Obx(() {
      final stats = controller.stats.value;
      if (stats == null) return const SizedBox.shrink();

      // "6/8" -> 6 done out of 8 total, used to fill the ring.
      final doneParts = stats.assignmentsDoneText.split('/');
      final assignmentsDone = int.tryParse(doneParts.isNotEmpty ? doneParts[0] : '') ?? 0;
      final assignmentsTotal = int.tryParse(doneParts.length > 1 ? doneParts[1] : '') ?? 0;

      final overdueAssignments = controller.pendingAssignments
          .where((item) => item.status == ListItemStatus.overdue)
          .length;

      // How much of today's schedule is already live/done, so the
      // "Live Class" ring fills in as the day goes on.
      final totalClassesToday = controller.todaysClassSchedule.length;
      final liveClassesNow = controller.todaysClassSchedule
          .where((item) => item.status == ListItemStatus.live)
          .length;
      final upcomingClassesToday = controller.todaysClassSchedule
          .where((item) => item.status == ListItemStatus.upcoming)
          .length;

      return SizedBox(
        height: 108,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            QuickActionRing(
              icon: Icons.fact_check_outlined,
              label: 'Attendance',
              subtitle: '${stats.attendancePercent.round()}% present',
              progress: stats.attendancePercent / 100,
              accentColor: AppColors.statCardBlue,
              onTap: () => Get.toNamed(Routes.studentAttendance),
            ),
            QuickActionRing(
              icon: Icons.assignment_turned_in_outlined,
              label: 'Assignments',
              subtitle: overdueAssignments == 0 ? 'All on track' : '$overdueAssignments overdue',
              progress: assignmentsTotal == 0 ? 0 : assignmentsDone / assignmentsTotal,
              accentColor: AppColors.statCardGreen,
              onTap: () => Get.toNamed(Routes.studentAssignments),
            ),
            QuickActionRing(
              icon: Icons.currency_rupee_outlined,
              label: 'Fees',
              subtitle: stats.feeDueText,
              progress: 1,
              accentColor: AppColors.statusPurple,
              onTap: () => Get.toNamed(Routes.studentFees),
            ),
            QuickActionRing(
              icon: Icons.videocam_outlined,
              label: 'Live Class',
              subtitle: liveClassesNow > 0
                  ? '$liveClassesNow live now'
                  : '$totalClassesToday today',
              progress: totalClassesToday == 0
                  ? 0
                  : (totalClassesToday - upcomingClassesToday) / totalClassesToday,
              accentColor: AppColors.statCardRed,
              onTap: () => Get.toNamed(Routes.studentLiveClasses),
            ),
            QuickActionRing(
              icon: Icons.calendar_month_outlined,
              label: 'Timetable',
              subtitle: 'All set',
              progress: 1,
              accentColor: AppColors.statCardOrange,
              onTap: () => Get.toNamed(Routes.studentTimetable),
            ),
          ],
        ),
      );
    });
  }

  /// A whole colored card for one dashboard list section, matching the
  /// faculty dashboard's section styling exactly.
  Widget _buildSection({
    required String title,
    required List<DashboardListItem> items,
    required IconData sectionIcon,
    required Color accentColor,
    required Color backgroundColor,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Obx(() {
      return _buildSectionCard(
        title: title,
        sectionIcon: sectionIcon,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
        actionLabel: actionLabel,
        onActionTap: onActionTap,
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nothing here right now.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              )
            : Column(children: [for (final item in items) StatusListTile(item: item)]),
      );
    });
  }

  /// The "Course Progress" card - one progress bar per course, instead
  /// of the usual status-chip rows, since a bar reads more naturally
  /// as "how much is done" than a chip does.
  Widget _buildCourseProgressSection() {
    return Obx(() {
      return _buildSectionCard(
        title: 'Course Progress',
        sectionIcon: Icons.trending_up_outlined,
        accentColor: AppColors.statCardBlue,
        backgroundColor: AppColors.sectionBlueBg,
        actionLabel: 'View All',
        onActionTap: () => Get.toNamed(Routes.studentCourses),
        child: Column(
          children: [
            for (final course in controller.courseProgress) _buildCourseProgressBar(course),
          ],
        ),
      );
    });
  }

  /// One row inside "Course Progress": the course name and percentage
  /// on top, a filled bar underneath showing how much is complete.
  Widget _buildCourseProgressBar(CourseProgressModel course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.courseName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${course.percentComplete.round()}%',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statCardBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (course.percentComplete / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.statCardBlue.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statCardBlue),
            ),
          ),
        ],
      ),
    );
  }

  /// The shared card chrome (colored background, icon badge, title,
  /// optional action pill) used by every dashboard list section - only
  /// the body underneath differs between sections.
  Widget _buildSectionCard({
    required String title,
    required IconData sectionIcon,
    required Color accentColor,
    required Color backgroundColor,
    required Widget child,
    String? actionLabel,
    VoidCallback? onActionTap,
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
            children: [
              // `Expanded` + `Flexible` let a long title wrap instead of
              // pushing the action pill off a small screen.
              Expanded(
                child: Row(
                  children: [
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
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null) const SizedBox(width: 8),
              if (actionLabel != null)
                // `Flexible` so with very large text the pill shrinks too,
                // instead of squeezing the title out.
                Flexible(
                  child: GestureDetector(
                    onTap: onActionTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        actionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
