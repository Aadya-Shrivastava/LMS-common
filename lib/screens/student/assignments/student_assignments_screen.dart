import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_assignment_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/link_opener.dart';
import 'package:lms/models/student/student_assignment_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/filter_card.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "Assignments" screen: 4 tappable filter cards (Total/Submitted/
/// Pending/Overdue) above the list, so tapping a card filters the list
/// straight to that group instead of needing a separate dropdown.
class StudentAssignmentsScreen extends GetView<StudentAssignmentController> {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Assignments',
        subtitle: 'View, submit and track assignment status',
        fallbackRoute: Routes.studentDashboard,
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentAssignments),
      body: Obx(() {
        final error = controller.errorMessage.value;
        if (error != null && !controller.hasLoaded) {
          return ErrorStateWidget(message: error, onRetry: controller.loadAssignments);
        }
        if (controller.isLoading.value && !controller.hasLoaded) {
          return const CustomLoader();
        }

        final assignments = controller.filteredAssignments;

        return RefreshIndicator(
          onRefresh: controller.loadAssignments,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFilterCards(),
              const SizedBox(height: 16),
              SectionCard(
                title: 'My Assignments',
                padding: EdgeInsets.zero,
                child: assignments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyStateWidget(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'Nothing here',
                          message: 'No assignments match this filter.',
                        ),
                      )
                    : Column(
                        children: [
                          for (final assignment in assignments)
                            _AssignmentTile(assignment: assignment),
                        ],
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterCards() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Total',
                  value: '${controller.totalCount}',
                  color: AppColors.statCardBlue,
                  selected: controller.activeFilter.value == StudentAssignmentFilter.total,
                  onTap: () => controller.selectFilter(StudentAssignmentFilter.total),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Submitted',
                  value: '${controller.submittedCount}',
                  color: AppColors.statCardGreen,
                  selected: controller.activeFilter.value == StudentAssignmentFilter.submitted,
                  onTap: () => controller.selectFilter(StudentAssignmentFilter.submitted),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Pending',
                  value: '${controller.pendingCount}',
                  color: AppColors.statusAmber,
                  selected: controller.activeFilter.value == StudentAssignmentFilter.pending,
                  onTap: () => controller.selectFilter(StudentAssignmentFilter.pending),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Overdue',
                  value: '${controller.overdueCount}',
                  color: AppColors.statusRed,
                  selected: controller.activeFilter.value == StudentAssignmentFilter.overdue,
                  onTap: () => controller.selectFilter(StudentAssignmentFilter.overdue),
                )),
          ),
        ],
      ),
    );
  }
}

/// One row in the assignment list. "View" opens the full details
/// (marks, feedback, files). "Upload" opens a dialog to pick a
/// document/image and hand it in.
class _AssignmentTile extends StatelessWidget {
  final StudentAssignmentModel assignment;

  const _AssignmentTile({required this.assignment});

  Future<void> _openUploadDialog(BuildContext context) async {
    final submittedName = await showDialog<String>(
      context: context,
      builder: (_) => _UploadDialog(assignment: assignment),
    );

    if (submittedName != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${assignment.title} submitted ($submittedName)')),
      );
    }
  }

  /// Everything about the assignment: instructions, marks, feedback,
  /// and links to the question file and the student's own submission.
  Future<void> _showDetails(BuildContext context) async {
    Widget line(String label, String value) {
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

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(assignment.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line('Subject', assignment.subject),
                if (assignment.facultyName.isNotEmpty) line('Given by', assignment.facultyName),
                line('Due', formatDateTime(assignment.dueDate)),
                if (assignment.submittedAt != null)
                  line('Submitted', formatDateTime(assignment.submittedAt!)),
                line(
                  'Marks',
                  assignment.marksText ??
                      (assignment.isDone ? 'Not checked yet' : 'Out of ${assignment.maxMarks}'),
                ),
                if (assignment.feedback.isNotEmpty) line('Feedback', assignment.feedback),
                if (assignment.description.isNotEmpty) line('Instructions', assignment.description),
              ],
            ),
          ),
          actions: [
            if (assignment.fileUrl.isNotEmpty)
              TextButton(
                onPressed: () => openLink(assignment.fileUrl),
                child: const Text('Question File'),
              ),
            if (assignment.submittedFileUrl.isNotEmpty)
              TextButton(
                onPressed: () => openLink(assignment.submittedFileUrl),
                child: const Text('My Submission'),
              ),
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
    final isDone = assignment.isDone;
    final marksPart = assignment.marksText != null
        ? ' · ${assignment.marksText}'
        : assignment.maxMarks > 0
            ? ' · ${assignment.maxMarks} marks'
            : '';

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
                  assignment.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${assignment.subject} · Due ${formatDate(assignment.dueDate)}'
                  '$marksPart',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                // Under the title (not beside the button) so the row
                // still fits a small phone with large text.
                const SizedBox(height: 6),
                _statusBadge(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isDone
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () => _showDetails(context),
                  child: const Text('View', style: TextStyle(fontSize: 12)),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () => _openUploadDialog(context),
                  child: const Text('Upload', style: TextStyle(fontSize: 12)),
                ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    if (assignment.status == StudentAssignmentStatus.graded) {
      return const StatusBadge(label: 'Graded', type: BadgeType.success);
    }
    if (assignment.status == StudentAssignmentStatus.submitted) {
      return const StatusBadge(label: 'Submitted', type: BadgeType.success);
    }
    if (assignment.isOverdue) {
      return const StatusBadge(label: 'Overdue', type: BadgeType.danger);
    }
    return const StatusBadge(label: 'Pending', type: BadgeType.warning);
  }
}

/// Picks the student's file and uploads it. Closes with the file's
/// name once it's handed in, or null if the student cancels.
class _UploadDialog extends StatefulWidget {
  final StudentAssignmentModel assignment;

  const _UploadDialog({required this.assignment});

  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  static const _allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
  static const _maxBytes = 10 * 1024 * 1024;

  String? _fileName;
  List<int>? _fileBytes;
  String? _error;
  bool _uploading = false;

  Future<void> _pickFile() async {
    final PlatformFile? file;
    final List<int> bytes;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );
      if (file == null) return; // Cancelled.
      bytes = await file.readAsBytes();
    } catch (_) {
      setState(() => _error = 'Could not open that file. Please try another.');
      return;
    }

    if (!mounted) return;
    setState(() {
      if (bytes.length > _maxBytes) {
        _fileName = null;
        _fileBytes = null;
        _error = 'That file is over 10 MB. Please choose a smaller one.';
      } else {
        _fileName = file!.name;
        _fileBytes = bytes;
        _error = null;
      }
    });
  }

  Future<void> _submit() async {
    final bytes = _fileBytes;
    final name = _fileName;
    if (bytes == null || name == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    final error = await Get.find<StudentAssignmentController>().submitAssignment(
      widget.assignment,
      fileBytes: bytes,
      fileName: name,
    );

    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(name);
    } else {
      setState(() {
        _uploading = false;
        _error = error;
      });
    }
  }

  static String _sizeText(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).ceil()} KB';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Don't let a back press drop an upload that's halfway through.
      canPop: !_uploading,
      child: AlertDialog(
        title: Text(widget.assignment.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.assignment.subject,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickFile,
              icon: Icon(_fileName == null ? Icons.attach_file : Icons.insert_drive_file_outlined),
              label: Text(
                _fileName ?? 'Choose Document / Image',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _fileBytes == null
                  ? 'PDF, Word or image · up to 10 MB'
                  : _sizeText(_fileBytes!.length),
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.statusRed)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _uploading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            // Can't submit without a file.
            onPressed: _fileBytes == null || _uploading ? null : _submit,
            child: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
