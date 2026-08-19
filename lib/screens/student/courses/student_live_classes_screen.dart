import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_course_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/models/student/recorded_lecture_model.dart';
import 'package:lms/models/student/student_class_schedule_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentCourseController>();

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
        if (controller.isLoadingClasses.value) {
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
        .where((item) => item.status == StudentClassStatus.live)
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
            title: "Today's Schedule",
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final item in controller.todaysClassSchedule)
                  _ScheduleTile(item: item),
              ],
            ),
          ),
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
            child: Column(
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joining ${item.subject}...')),
              );
            },
            child: const Text('Join Class'),
          ),
        ],
      ),
    );
  }
}

/// A row in "Today's Schedule" - shows the time, subject, faculty and
/// platform, plus either a Join button (if live) or a Reminder button
/// (if upcoming).
class _ScheduleTile extends StatelessWidget {
  final StudentClassScheduleModel item;

  const _ScheduleTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLive = item.status == StudentClassStatus.live;

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
          StatusBadge(
            label: isLive ? 'Live' : 'Upcoming',
            type: isLive ? BadgeType.success : BadgeType.neutral,
          ),
          const SizedBox(width: 8),
          isLive
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Joining ${item.subject}...')),
                    );
                  },
                  child: const Text('Join', style: TextStyle(fontSize: 12)),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("We'll remind you before ${item.subject} starts")),
                    );
                  },
                  child: const Text('Reminder', style: TextStyle(fontSize: 12)),
                ),
        ],
      ),
    );
  }
}

/// One card in the recorded lecture library.
class _RecordedLectureTile extends StatelessWidget {
  final RecordedLectureModel lecture;

  const _RecordedLectureTile({required this.lecture});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playing "${lecture.title}"...')),
        );
      },
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
