import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/faculty/faculty_attendance_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/models/faculty/assignment_model.dart';
import 'package:lms/models/faculty/student_assignment_record_model.dart';
import 'package:lms/models/faculty/student_performance_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import 'package:lms/widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';

/// A single student's detail screen: their attendance, internal marks
/// and grade, and their full assignment history - each assignment can
/// be reviewed and (re-)graded right here.
///
/// Opened from the Student Performance screen by tapping a student's
/// row; which student to show is passed in via `Get.arguments`.
class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late final StudentPerformanceModel _student = Get.arguments as StudentPerformanceModel;
  late final FacultyAttendanceController _controller = Get.find<FacultyAttendanceController>();

  @override
  void initState() {
    super.initState();
    _controller.loadAssignmentRecordsFor(_student.studentName);
  }

  Color _attendanceColor(int percent) {
    if (percent >= 90) return AppColors.statusGreen;
    if (percent >= 75) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: _student.studentName, subtitle: 'Attendance, marks & assignments'),
      drawer: const AppDrawer(currentRoute: Routes.facultyStudentPerformance),
      body: Obx(() {
        if (_controller.isLoadingStudentAssignments.value) {
          return const CustomLoader();
        }

        return RefreshIndicator(
          onRefresh: () => _controller.loadAssignmentRecordsFor(_student.studentName),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildOverviewCard(),
              const SizedBox(height: 16),
              _buildAssignmentsCard(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        InitialsAvatar(initials: _student.studentInitials, radius: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _student.studentName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Text(
                'Overall Grade',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        StatusBadge(
          label: _student.grade,
          type: _student.grade.startsWith('A') ? BadgeType.success : BadgeType.warning,
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return SectionCard(
      title: 'Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text('Attendance', style: TextStyle(fontSize: 13)),
              const Spacer(),
              Text(
                '${_student.attendancePercent}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _attendanceColor(_student.attendancePercent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _student.attendancePercent / 100,
              minHeight: 6,
              backgroundColor: AppColors.background,
              color: _attendanceColor(_student.attendancePercent),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text('Assignments Completed', style: TextStyle(fontSize: 13)),
              const Spacer(),
              Text(
                _student.assignmentsCompletedText,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.grade_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text('Internal Marks', style: TextStyle(fontSize: 13)),
              const Spacer(),
              Text(
                _student.internalMarks.isEmpty ? 'Not set' : _student.internalMarks,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsCard() {
    return SectionCard(
      title: 'Assignments',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final record in _controller.studentAssignmentRecords)
            _AssignmentRecordTile(record: record),
        ],
      ),
    );
  }
}

/// One row in a student's assignment history. Tapping it opens a
/// dialog to review the assignment and give (or change) its marks.
class _AssignmentRecordTile extends StatelessWidget {
  final StudentAssignmentRecordModel record;

  const _AssignmentRecordTile({required this.record});

  Future<void> _reviewAndGrade(BuildContext context) async {
    final textController = TextEditingController(text: record.marks);

    final newMarks = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(record.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Due ${record.dueDateText}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Marks', hintText: 'e.g. 18/20'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () => Navigator.of(context).pop(textController.text.trim()),
              child: const Text('Save Marks'),
            ),
          ],
        );
      },
    );

    if (newMarks != null && newMarks.isNotEmpty) {
      Get.find<FacultyAttendanceController>().saveAssignmentRecordMarks(record, newMarks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _reviewAndGrade(context),
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
                    record.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Text(
                    record.marks.isEmpty ? 'Due ${record.dueDateText}' : 'Marks: ${record.marks}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _statusBadge(),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    switch (record.status) {
      case AssignmentStatus.graded:
        return const StatusBadge(label: 'Graded', type: BadgeType.success);
      case AssignmentStatus.submitted:
        return const StatusBadge(label: 'Submitted', type: BadgeType.info);
      case AssignmentStatus.pending:
        return const StatusBadge(label: 'Pending', type: BadgeType.warning);
    }
  }
}
