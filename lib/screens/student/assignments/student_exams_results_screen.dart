import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_exam_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/models/student/exam_model.dart';
import 'package:lms/models/student/exam_result_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "Exams & Results" screen, split into two tabs:
///   - "Exams": upcoming exams and online tests.
///   - "Results": past result history.
class StudentExamsResultsScreen extends StatefulWidget {
  const StudentExamsResultsScreen({super.key});

  @override
  State<StudentExamsResultsScreen> createState() => _StudentExamsResultsScreenState();
}

class _StudentExamsResultsScreenState extends State<StudentExamsResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentExamController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Exams & Results',
        subtitle: 'Upcoming exams, online tests and result history',
        fallbackRoute: Routes.studentDashboard,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Exams'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentExamsResults),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const CustomLoader();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildExamsTab(controller),
            _buildResultsTab(controller),
          ],
        );
      }),
    );
  }

  Widget _buildExamsTab(StudentExamController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadExamsAndResults,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Upcoming Exams',
            padding: EdgeInsets.zero,
            child: controller.upcomingExams.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.event_available_outlined,
                      title: 'Nothing scheduled',
                      message: 'No upcoming exams right now.',
                    ),
                  )
                : Column(
                    children: [
                      for (final exam in controller.upcomingExams) _ExamTile(exam: exam),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab(StudentExamController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadExamsAndResults,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Result History',
            padding: EdgeInsets.zero,
            child: controller.resultHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.fact_check_outlined,
                      title: 'No results yet',
                      message: 'Your exam results will show up here.',
                    ),
                  )
                : Column(
                    children: [
                      for (final result in controller.resultHistory)
                        _ResultTile(result: result),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// One row on the "Exams" tab. Every exam here is in the future, so the
/// action button is always disabled - there's nothing to do yet except
/// see it on the calendar.
class _ExamTile extends StatelessWidget {
  final ExamModel exam;

  const _ExamTile({required this.exam});

  @override
  Widget build(BuildContext context) {
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
                  exam.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exam.subject} · ${exam.dateTimeText} · ${exam.durationText}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: exam.type == ExamType.mcq ? 'MCQ' : 'Practical',
            type: exam.type == ExamType.mcq ? BadgeType.info : BadgeType.neutral,
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
            onPressed: null,
            child: const Text('Not Started', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

/// One row on the "Results" tab. Tapping it opens a small dialog with
/// the full breakdown.
class _ResultTile extends StatelessWidget {
  final ExamResultModel result;

  const _ResultTile({required this.result});

  Future<void> _viewResult(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(result.examTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Subject', value: result.subject),
              _DetailRow(label: 'Marks', value: result.marksText),
              _DetailRow(label: 'Grade', value: result.grade),
              _DetailRow(label: 'Rank', value: result.rankText),
            ],
          ),
          actions: [
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
      onTap: () => _viewResult(context),
      child: Container(
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
                    result.examTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.subject} · ${result.marksText} · Rank ${result.rankText}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            StatusBadge(label: result.grade, type: BadgeType.success),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// One "label: value" line in the result detail dialog.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
