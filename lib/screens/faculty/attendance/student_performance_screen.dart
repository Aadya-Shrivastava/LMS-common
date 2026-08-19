import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/faculty/faculty_attendance_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/models/faculty/student_performance_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import '../../../widgets/compact_dropdown.dart';
import 'package:lms/widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dropdown_field.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';

const List<String> _batches = ['Batch A', 'Batch B'];

/// The "Student Performance" screen: a batch-wide overview of
/// attendance, assignments, and internal marks, plus a way to message
/// a student or the whole batch directly.
class StudentPerformanceScreen extends StatefulWidget {
  const StudentPerformanceScreen({super.key});

  @override
  State<StudentPerformanceScreen> createState() => _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FacultyAttendanceController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Student Performance',
        subtitle: 'Internal marks, reports and communication',
      ),
      drawer: const AppDrawer(currentRoute: Routes.facultyStudentPerformance),
      body: Obx(() {
        if (controller.isLoadingPerformance.value) {
          return const CustomLoader();
        }

        final batch = controller.selectedPerformanceBatch.value;
        final query = _searchQuery.trim().toLowerCase();
        final allRows = controller.performanceRows;
        final visibleRows =
            allRows.where((row) => row.studentName.toLowerCase().contains(query)).toList();

        return RefreshIndicator(
          onRefresh: controller.loadPerformance,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // A compact inline batch picker instead of a full-height
              // form field - it's just a label + small dropdown, so
              // most of the screen stays free for the actual list.
              Row(
                children: [
                  const Text(
                    'Batch',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 130,
                    child: CompactDropdown<String>(
                      value: batch,
                      options: _batches,
                      labelFor: (option) => option,
                      onChanged: (value) => controller.selectPerformanceBatch(value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SearchField(
                controller: _searchController,
                hint: 'Search student name',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: '$batch - Performance Overview',
                padding: EdgeInsets.zero,
                trailing: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Message sent to $batch')),
                    );
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                  child: const Text('Message Batch', style: TextStyle(fontSize: 12)),
                ),
                child: visibleRows.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyStateWidget(
                          icon: Icons.search_off,
                          title: 'No matches',
                          message: 'No students match, or none in this batch yet.',
                        ),
                      )
                    : Column(
                        children: [
                          for (final row in visibleRows) _PerformanceRow(row: row),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              // A fresh `key` per batch means this form resets itself
              // (new local state) whenever the batch changes, instead of
              // hanging on to a student name from the previous batch.
              _DirectCommunicationSection(
                key: ValueKey(batch),
                batchLabel: batch,
                studentNames: [for (final row in allRows) row.studentName],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final StudentPerformanceModel row;

  const _PerformanceRow({required this.row});

  Color _attendanceColor() {
    if (row.attendancePercent >= 90) return AppColors.statusGreen;
    if (row.attendancePercent >= 75) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    // The row itself is tappable and opens the student's full detail
    // screen (attendance, marks, assignment history). The marks chip
    // inside is its own separate tap target for the quick edit, and
    // wins over the row's tap when you hit it directly.
    return InkWell(
      onTap: () => Get.toNamed(Routes.facultyStudentDetail, arguments: row),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            InitialsAvatar(initials: row.studentInitials),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(
                    'Attendance ${row.attendancePercent}% · Assignments ${row.assignmentsCompletedText}',
                    style: TextStyle(fontSize: 11, color: _attendanceColor()),
                  ),
                ],
              ),
            ),
            _MarksChip(row: row),
            const SizedBox(width: 8),
            StatusBadge(
              label: row.grade,
              type: row.grade.startsWith('A') ? BadgeType.success : BadgeType.warning,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small tappable chip showing a student's internal marks, e.g.
/// "38/40". Tapping it opens a little dialog to change the marks,
/// instead of squeezing an always-editable text field into the row
/// (which was cramped and easy to misread).
class _MarksChip extends StatelessWidget {
  final StudentPerformanceModel row;

  const _MarksChip({required this.row});

  Future<void> _editMarks(BuildContext context) async {
    final textController = TextEditingController(text: row.internalMarks);

    final newMarks = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${row.studentName} - Internal Marks'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. 38/40'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () => Navigator.of(context).pop(textController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newMarks != null && newMarks.isNotEmpty) {
      Get.find<FacultyAttendanceController>().saveInternalMarksFor(row, newMarks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _editMarks(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              row.internalMarks.isEmpty ? 'Add' : row.internalMarks,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 13, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// The "Direct Communication" form, collapsed into a single header row
/// until tapped open - it's used far less often than the performance
/// list above it, so it shouldn't take up space by default.
class _DirectCommunicationSection extends StatefulWidget {
  final String batchLabel;
  final List<String> studentNames;

  const _DirectCommunicationSection({
    super.key,
    required this.batchLabel,
    required this.studentNames,
  });

  @override
  State<_DirectCommunicationSection> createState() => _DirectCommunicationSectionState();
}

class _DirectCommunicationSectionState extends State<_DirectCommunicationSection> {
  late String _target = _targets.first;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  List<String> get _targets => ['${widget.batchLabel} - All Students', ...widget.studentNames];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a message first')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message sent to $_target')),
    );

    setState(() {
      _subjectController.clear();
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Removes the default ExpansionTile divider lines, so it matches
      // the flat, borderless look of the rest of the app.
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            'Direct Communication',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            CustomDropdownField<String>(
              label: 'Student / Batch',
              value: _target,
              options: _targets,
              labelFor: (option) => option,
              onChanged: (value) => setState(() => _target = value!),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'Message subject',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _messageController,
              label: 'Message',
              hint: 'Write your message',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            CustomButton(text: 'Send', onPressed: _send),
          ],
        ),
      ),
    );
  }
}
