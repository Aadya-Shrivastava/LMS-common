import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_exam_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/student/exam_model.dart';
import 'package:lms/models/student/exam_result_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "Exams & Results" screen, split into two tabs:
///   - "Exams": upcoming exams, then every exam for the batch.
///   - "Results": finished exams; tapping one shows the attempt detail.
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
        final error = controller.errorMessage.value;
        if (error != null && !controller.hasLoaded) {
          return ErrorStateWidget(message: error, onRetry: controller.loadExamsAndResults);
        }
        if (controller.isLoading.value && !controller.hasLoaded) {
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
          if (controller.allExams.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'All Exams',
              padding: EdgeInsets.zero,
              child: Column(
                children: [for (final exam in controller.allExams) _ExamTile(exam: exam)],
              ),
            ),
          ],
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
                        _ResultTile(result: result, attempt: controller.attemptFor(result)),
                    ],
                  ),
          ),
          if (controller.gradingScale.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Grading Scale',
              child: Column(
                children: [
                  for (final band in controller.gradingScale) _GradeBandRow(band: band),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One line of the grading scale: grade, % range, points and remarks.
class _GradeBandRow extends StatelessWidget {
  final GradeBandModel band;

  const _GradeBandRow({required this.band});

  String _number(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              band.grade,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              '${_number(band.fromPercent)}–${_number(band.toPercent)}%'
              '${band.remarks.isEmpty ? '' : ' · ${band.remarks}'}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Text(
            '${_number(band.gradePoint)} pts',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// One exam row: title, subject/chapter, when and how long, and whether
/// it's upcoming, live now, or finished.
class _ExamTile extends StatelessWidget {
  final ExamModel exam;

  const _ExamTile({required this.exam});

  @override
  Widget build(BuildContext context) {
    final details = [
      exam.subject,
      if (exam.chapter.isNotEmpty) exam.chapter,
      exam.dateTimeText,
      if (exam.durationText.isNotEmpty) exam.durationText,
      if (exam.questionCount > 0) '${exam.questionCount} Qs',
    ].where((part) => part.isNotEmpty).join(' · ');

    final (label, type) = switch (exam.status) {
      ExamStatus.upcoming => ('Upcoming', BadgeType.info),
      ExamStatus.live => ('Live Now', BadgeType.success),
      ExamStatus.finished => ('Finished', BadgeType.neutral),
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
                  exam.typeName.isEmpty ? exam.title : '${exam.title} · ${exam.typeName}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(label: label, type: type),
        ],
      ),
    );
  }
}

/// One row on the "Results" tab. Tapping it opens the attempt detail.
class _ResultTile extends StatelessWidget {
  final ExamResultModel result;

  /// Null if the attempt detail couldn't be matched.
  final ExamAttemptModel? attempt;

  const _ResultTile({required this.result, required this.attempt});

  Future<void> _viewResult(BuildContext context) async {
    final attempt = this.attempt;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(result.examTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Subject', value: result.subject),
                _DetailRow(label: 'Score', value: result.scoreText),
                _DetailRow(label: 'Status', value: result.statusText),
                if (attempt != null) ...[
                  if (attempt.startedAt != null)
                    _DetailRow(label: 'Started', value: formatDateTime(attempt.startedAt!)),
                  if (attempt.submittedAt != null)
                    _DetailRow(label: 'Submitted', value: formatDateTime(attempt.submittedAt!)),
                  _DetailRow(label: 'Time taken', value: attempt.timeTakenText),
                  _DetailRow(label: 'Answered', value: '${attempt.answers.length} questions'),
                  _DetailRow(label: 'Tab switches', value: '${attempt.tabSwitches}'),
                  if (attempt.autoSubmitted)
                    const _DetailRow(label: 'Note', value: 'Submitted automatically when time ran out'),
                ],
              ],
            ),
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
    final submitted = result.submittedAt == null ? '' : ' · ${formatDate(result.submittedAt!)}';
    final evaluated = result.statusText.toLowerCase().contains('evaluat');

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
                    '${result.subject} · Score ${result.scoreText}$submitted',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: result.statusText.isEmpty ? '—' : result.statusText,
              type: evaluated ? BadgeType.success : BadgeType.warning,
            ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
