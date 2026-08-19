import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_assignment_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/student/student_assignment_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
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
        if (controller.isLoading.value) {
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

/// One row in the assignment list. "View" just shows a confirmation
/// snackbar for now, since there's no backend yet. "Upload" opens a
/// dialog to pick a document/image and add an optional note before
/// submitting.
class _AssignmentTile extends StatelessWidget {
  final StudentAssignmentModel assignment;

  const _AssignmentTile({required this.assignment});

  Future<void> _openUploadDialog(BuildContext context) async {
    // The name of the file the student "picked" in the dialog below.
    // Picking a real file needs a file-picker package, which isn't
    // wired up yet since there's no backend to upload it to - for now
    // this just simulates a file being chosen, the same way the
    // faculty side's material upload does.
    String? pickedFileName;
    final noteController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        // `StatefulBuilder` lets this dialog remember the picked file
        // name and redraw itself, without needing a whole new widget class.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(assignment.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.subject,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => setDialogState(
                      () => pickedFileName = 'submission_${DateTime.now().second}.pdf',
                    ),
                    icon: const Icon(Icons.attach_file),
                    label: Text(pickedFileName ?? 'Choose Document / Image'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'Add a note for your faculty',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  // Can't submit without a file - the note stays optional.
                  onPressed: pickedFileName == null
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();

    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${assignment.title} submitted ($pickedFileName)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGraded = assignment.status == StudentAssignmentStatus.graded;

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
                  '${isGraded ? ' · ${assignment.marksText}' : ''}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _statusBadge(),
          const SizedBox(width: 8),
          isGraded
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${assignment.title}: ${assignment.marksText}')),
                    );
                  },
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
    if (assignment.isOverdue) {
      return const StatusBadge(label: 'Overdue', type: BadgeType.danger);
    }
    return const StatusBadge(label: 'Pending', type: BadgeType.warning);
  }
}
