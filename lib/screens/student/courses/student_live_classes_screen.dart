import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_course_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/link_opener.dart';
import 'package:lms/models/student/recorded_lecture_model.dart';
import 'package:lms/models/student/student_class_schedule_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "Live Classes" screen, split into two tabs:
///   - "Live & Schedule": the "Live Now" banner (if anything is live)
///     plus today's full class schedule.
///   - "Recorded Lectures": the recorded lecture library, watchable
///     any time.
class StudentLiveClassesScreen extends StatefulWidget {
  const StudentLiveClassesScreen({super.key});

  @override
  State<StudentLiveClassesScreen> createState() => _StudentLiveClassesScreenState();
}

class _StudentLiveClassesScreenState extends State<StudentLiveClassesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  /// Redraws every 30 seconds so Join, "Starting Soon" and "Live Now"
  /// switch on by themselves while the screen stays open.
  late final Timer _clock = Timer.periodic(const Duration(seconds: 30), (_) {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _clock; // Starts the timer.
  }

  @override
  void dispose() {
    _clock.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentCourseController>();
    controller.ensureClassesLoaded();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Live Classes',
        subtitle: 'Join live sessions or watch recorded lectures',
        fallbackRoute: Routes.studentDashboard,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Live & Schedule'),
            Tab(text: 'Recorded Lectures'),
          ],
        ),
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentLiveClasses),
      body: Obx(() {
        final error = controller.classesError.value;
        if (error != null && !controller.hasLoadedClasses) {
          return ErrorStateWidget(
            message: error,
            onRetry: controller.loadTodaysClassSchedule,
          );
        }
        if (controller.isLoadingClasses.value && !controller.hasLoadedClasses) {
          return const CustomLoader();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildLiveAndScheduleTab(controller),
            _buildRecordedLecturesTab(controller),
          ],
        );
      }),
    );
  }

  Widget _buildLiveAndScheduleTab(StudentCourseController controller) {
    final liveNow = controller.todaysClassSchedule
        .where((item) => item.isLiveNow())
        .toList();

    return RefreshIndicator(
      onRefresh: controller.loadTodaysClassSchedule,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (liveNow.isNotEmpty) ...[
            SectionCard(
              title: 'Live Now',
              trailing: StatusBadge(label: '${liveNow.length} Ongoing', type: BadgeType.success),
              child: Column(
                children: [for (final item in liveNow) _LiveNowTile(item: item)],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            title: 'Upcoming Classes',
            padding: EdgeInsets.zero,
            child: controller.todaysClassSchedule.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.event_available_outlined,
                      title: 'No upcoming classes',
                      message: 'New live classes will show up here.',
                    ),
                  )
                : Column(
                    children: [
                      for (final item in controller.todaysClassSchedule)
                        _ScheduleTile(item: item),
                    ],
                  ),
          ),
          if (controller.pastClasses.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Past Classes',
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final item in controller.pastClasses) _ScheduleTile(item: item),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordedLecturesTab(StudentCourseController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadTodaysClassSchedule,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Recorded Lecture Library',
            child: controller.recordedLectures.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.video_library_outlined,
                    title: 'No recordings yet',
                    message: 'Recorded classes will show up here.',
                  )
                : Column(
                    children: [
                      for (final lecture in controller.recordedLectures)
                        _RecordedLectureTile(lecture: lecture),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// A row inside the "Live Now" card - a class that's happening right
/// this minute, with a prominent Join button.
class _LiveNowTile extends StatelessWidget {
  final StudentClassScheduleModel item;

  const _LiveNowTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.facultyName} · ${item.timeRange}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: () => openLink(item.meetingLink),
            child: const Text('Join Class'),
          ),
        ],
      ),
    );
  }
}

/// A row in "Upcoming Classes" or "Past Classes" - shows the time,
/// subject, faculty and platform, plus:
///   - a Join button from 10 minutes before the start until the end,
///   - a Reminder button (bell) before that,
///   - nothing for finished or cancelled classes.
class _ScheduleTile extends StatelessWidget {
  final StudentClassScheduleModel item;

  const _ScheduleTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isLive = item.isLiveNow(now);
    final canJoin = item.canJoin(now);

    final (badgeLabel, badgeType) = switch (item.status) {
      StudentClassStatus.completed => ('Completed', BadgeType.neutral),
      StudentClassStatus.cancelled => ('Cancelled', BadgeType.danger),
      _ when isLive => ('Live', BadgeType.success),
      _ when canJoin => ('Starting Soon', BadgeType.warning),
      _ => ('Upcoming', BadgeType.neutral),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.timeRange} · ${item.facultyName} · ${item.platform}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(label: badgeLabel, type: badgeType),
          // Finished and cancelled classes just show their badge.
          if (!item.isOver) ...[
            const SizedBox(width: 8),
            if (canJoin)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: () => openLink(item.meetingLink),
                child: const Text('Join', style: TextStyle(fontSize: 12)),
              )
            else
              _ReminderButton(item: item),
          ],
        ],
      ),
    );
  }
}

/// The bell next to an upcoming class: tap to get a phone notification
/// before the class starts, tap again to remove it.
class _ReminderButton extends StatelessWidget {
  final StudentClassScheduleModel item;

  const _ReminderButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentCourseController>();

    return Obx(() {
      final isSet = controller.remindedClassIds.contains(item.id);

      return IconButton(
        tooltip: isSet ? 'Remove reminder' : 'Remind me',
        visualDensity: VisualDensity.compact,
        icon: Icon(
          isSet ? Icons.notifications_active : Icons.notifications_none_outlined,
          color: isSet ? AppColors.primaryNavy : AppColors.textSecondary,
        ),
        onPressed: () async {
          final message = await controller.toggleReminder(item);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        },
      );
    });
  }
}

/// One card in the recorded lecture library.
class _RecordedLectureTile extends StatelessWidget {
  final RecordedLectureModel lecture;

  const _RecordedLectureTile({required this.lecture});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openLink(lecture.recordingUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.statCardBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_outline, color: AppColors.statCardBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.tag,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statCardBlue,
                    ),
                  ),
                  Text(
                    lecture.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Text(
                    '${lecture.durationText} · ${lecture.facultyName}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
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
