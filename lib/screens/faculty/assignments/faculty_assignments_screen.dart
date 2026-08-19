import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/faculty/faculty_assignment_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/faculty/assignment_summary_model.dart';
import 'package:lms/models/faculty/submission_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
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

const List<String> _subjects = ['Basic Electrical Wiring', 'Circuit Design'];
const List<String> _batches = ['Batch A', 'Batch B'];

/// The 3 ways the Submissions tab can be filtered.
enum _SubmissionFilter { all, pending, completed }

/// The "Assignments" screen, split into three tabs so nothing feels
/// crowded:
///   - "Create": the new-assignment form, on its own.
///   - "Assignments": search + every assignment given out.
///   - "Submissions": filter (All/Pending/Completed) + grade the
///     submissions for the assignment currently being reviewed.
class FacultyAssignmentsScreen extends StatefulWidget {
  const FacultyAssignmentsScreen({super.key});

  @override
  State<FacultyAssignmentsScreen> createState() => _FacultyAssignmentsScreenState();
}

class _FacultyAssignmentsScreenState extends State<FacultyAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  final _assignmentSearchController = TextEditingController();
  String _assignmentSearchQuery = '';

  final _submissionSearchController = TextEditingController();
  String _submissionSearchQuery = '';
  _SubmissionFilter _submissionFilter = _SubmissionFilter.all;

  @override
  void dispose() {
    _tabController.dispose();
    _assignmentSearchController.dispose();
    _submissionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FacultyAssignmentController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Assignments',
        subtitle: 'Create assignments and evaluate submissions',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Create'),
            Tab(text: 'Assignments'),
            Tab(text: 'Submissions'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: Routes.facultyAssignments),
      body: Obx(() {
        if (controller.isLoadingAssignments.value) {
          return const CustomLoader();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildCreateTab(),
            _buildAssignmentsTab(controller),
            _buildSubmissionsTab(controller),
          ],
        );
      }),
    );
  }

  Widget _buildCreateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [_CreateAssignmentForm()],
    );
  }

  Widget _buildAssignmentsTab(FacultyAssignmentController controller) {
    final query = _assignmentSearchQuery.trim().toLowerCase();
    final assignments = controller.assignments
        .where((assignment) =>
            assignment.title.toLowerCase().contains(query) ||
            assignment.batch.toLowerCase().contains(query))
        .toList();

    return RefreshIndicator(
      onRefresh: controller.loadAssignments,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchField(
            controller: _assignmentSearchController,
            hint: 'Search assignments by title or batch',
            onChanged: (value) => setState(() => _assignmentSearchQuery = value),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'All Assignments',
            padding: EdgeInsets.zero,
            child: assignments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'No assignments match that search.',
                    ),
                  )
                : Column(
                    children: [
                      for (final assignment in assignments)
                        _AssignmentSummaryTile(assignment: assignment),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab(FacultyAssignmentController controller) {
    final query = _submissionSearchQuery.trim().toLowerCase();
    final activeAssignment = controller.activeAssignment;

    // Includes students who haven't submitted anything yet too, not
    // just the ones who did - that's what lets "Missing"/"Overdue"
    // rows show up.
    final submissions = controller.submissionsWithMissingFor('Batch A').where((submission) {
      final matchesFilter = switch (_submissionFilter) {
        _SubmissionFilter.pending => submission.status == SubmissionStatus.pendingReview,
        _SubmissionFilter.completed => submission.status == SubmissionStatus.graded,
        _SubmissionFilter.all => true,
      };
      final matchesSearch = submission.studentName.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
    final pendingCount = controller.activeSubmissions
        .where((submission) => submission.status == SubmissionStatus.pendingReview)
        .length;

    return RefreshIndicator(
      onRefresh: controller.loadAssignments,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchField(
            controller: _submissionSearchController,
            hint: 'Search by student name',
            onChanged: (value) => setState(() => _submissionSearchQuery = value),
          ),
          const SizedBox(height: 10),
          // A smaller, denser style so the 3-way filter doesn't take up
          // more room than it needs to.
          SegmentedButton<_SubmissionFilter>(
            segments: const [
              ButtonSegment(value: _SubmissionFilter.all, label: Text('All')),
              ButtonSegment(value: _SubmissionFilter.pending, label: Text('Pending')),
              ButtonSegment(value: _SubmissionFilter.completed, label: Text('Completed')),
            ],
            selected: {_submissionFilter},
            onSelectionChanged: (selection) =>
                setState(() => _submissionFilter = selection.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primaryNavy,
              selectedForegroundColor: AppColors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Wiring Diagram Submission',
            padding: EdgeInsets.zero,
            trailing: StatusBadge(label: '$pendingCount Pending', type: BadgeType.warning),
            child: submissions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'Nothing here',
                      message: 'No submissions match this filter.',
                    ),
                  )
                : Column(
                    children: [
                      for (final submission in submissions)
                        _SubmissionTile(
                          submission: submission,
                          isAssignmentOverdue: activeAssignment?.isOverdue ?? false,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CreateAssignmentForm extends StatefulWidget {
  const _CreateAssignmentForm();

  @override
  State<_CreateAssignmentForm> createState() => _CreateAssignmentFormState();
}

class _CreateAssignmentFormState extends State<_CreateAssignmentForm> {
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _subject = _subjects.first;
  String _batch = _batches.first;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _createAssignment() {
    if (_titleController.text.trim().isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title and due date')),
      );
      return;
    }

    Get.find<FacultyAssignmentController>().addAssignment(
      AssignmentSummaryModel(
        id: 'as-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        batch: _batch,
        dueDate: _dueDate!,
        submittedCount: 0,
        totalCount: 42,
        status: AssignmentSummaryStatus.active,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_titleController.text.trim()} published')),
    );

    setState(() {
      _titleController.clear();
      _instructionsController.clear();
      _dueDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create New Assignment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _titleController,
            label: 'Title',
            hint: 'Assignment title',
          ),
          const SizedBox(height: 16),
          CustomDropdownField<String>(
            label: 'Subject',
            value: _subject,
            options: _subjects,
            labelFor: (option) => option,
            onChanged: (value) => setState(() => _subject = value!),
          ),
          const SizedBox(height: 16),
          CustomDropdownField<String>(
            label: 'Batch',
            value: _batch,
            options: _batches,
            labelFor: (option) => option,
            onChanged: (value) => setState(() => _batch = value!),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Due Date',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                _dueDate == null ? 'Tap to pick a date' : formatDate(_dueDate!),
                style: TextStyle(
                  color: _dueDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _instructionsController,
            label: 'Instructions',
            hint: 'Assignment instructions',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          CustomButton(text: 'Create & Publish', onPressed: _createAssignment),
        ],
      ),
    );
  }
}

/// One student's row in the Submissions list. Tapping it opens a
/// dialog to review what they submitted (or, for a "Missing"/"Overdue"
/// student, a note that they haven't submitted anything) and to give
/// or change their marks.
class _SubmissionTile extends StatelessWidget {
  final SubmissionModel submission;

  /// Whether the assignment these submissions belong to is past its
  /// due date - that's what turns "Missing" into "Overdue".
  final bool isAssignmentOverdue;

  const _SubmissionTile({required this.submission, required this.isAssignmentOverdue});

  Future<void> _openReview(BuildContext context) async {
    if (submission.status == SubmissionStatus.missing) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(submission.studentName),
            content: Text(
              isAssignmentOverdue
                  ? "This student didn't submit this assignment, and the due date has passed."
                  : "This student hasn't submitted this assignment yet.",
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
      return;
    }

    final textController = TextEditingController(text: submission.marks);

    final newMarks = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(submission.studentName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submitted ${submission.submittedAtText}\nFile: ${submission.fileName}',
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
      Get.find<FacultyAssignmentController>().saveMarksFor(submission, newMarks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openReview(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            InitialsAvatar(initials: submission.studentInitials),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Text(
                    submission.status == SubmissionStatus.missing
                        ? 'Not submitted'
                        : '${submission.submittedAtText} · ${submission.fileName}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
    switch (submission.status) {
      case SubmissionStatus.graded:
        return StatusBadge(label: submission.marks, type: BadgeType.success);
      case SubmissionStatus.pendingReview:
        return const StatusBadge(label: 'Pending', type: BadgeType.warning);
      case SubmissionStatus.missing:
        return StatusBadge(
          label: isAssignmentOverdue ? 'Overdue' : 'Missing',
          type: BadgeType.danger,
        );
    }
  }
}

/// One row in the "All Assignments" list. Tapping it opens a dialog
/// showing the assignment's details, and lets the faculty member who
/// created it edit the due date.
class _AssignmentSummaryTile extends StatelessWidget {
  final AssignmentSummaryModel assignment;

  const _AssignmentSummaryTile({required this.assignment});

  Future<void> _openDetail(BuildContext context) async {
    DateTime pickedDate = assignment.dueDate;

    await showDialog<void>(
      context: context,
      builder: (context) {
        // `StatefulBuilder` lets this dialog remember the newly-picked
        // date and redraw itself, without needing a whole new widget class.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(assignment.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${assignment.batch} · ${assignment.submittedCount}/${assignment.totalCount} submitted',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: pickedDate,
                        firstDate: now.subtract(const Duration(days: 365)),
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (newDate != null) setDialogState(() => pickedDate = newDate);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                      child: Text(formatDate(pickedDate)),
                    ),
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
                  onPressed: () {
                    Get.find<FacultyAssignmentController>()
                        .updateAssignmentDueDate(assignment, pickedDate);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = assignment.status == AssignmentSummaryStatus.active && assignment.isOverdue;

    return InkWell(
      onTap: () => _openDetail(context),
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
                    assignment.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Text(
                    '${assignment.batch} · Due ${formatDate(assignment.dueDate)} · '
                    '${assignment.submittedCount}/${assignment.totalCount} submitted',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: isOverdue
                  ? 'Overdue'
                  : (assignment.status == AssignmentSummaryStatus.active ? 'Active' : 'Closed'),
              type: isOverdue
                  ? BadgeType.danger
                  : (assignment.status == AssignmentSummaryStatus.active
                      ? BadgeType.warning
                      : BadgeType.success),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
