import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_placement_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/link_opener.dart';
import 'package:lms/models/student/placement_models.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "Placements" screen, split into three tabs:
///   - "Drives": company placement drives, with an Apply button.
///   - "My Applications": drives the student has applied to.
///   - "Placed": the student's own placements, with company and package.
class StudentPlacementsScreen extends StatefulWidget {
  const StudentPlacementsScreen({super.key});

  @override
  State<StudentPlacementsScreen> createState() => _StudentPlacementsScreenState();
}

class _StudentPlacementsScreenState extends State<StudentPlacementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentPlacementController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Placements',
        subtitle: 'Placement drives, your applications and placed students',
        fallbackRoute: Routes.studentDashboard,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Drives'),
            Tab(text: 'My Applications'),
            Tab(text: 'Placed'),
          ],
        ),
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentPlacements),
      body: Obx(() {
        final error = controller.errorMessage.value;
        if (error != null && !controller.hasLoaded) {
          return ErrorStateWidget(message: error, onRetry: controller.loadPlacements);
        }
        if (controller.isLoading.value && !controller.hasLoaded) {
          return const CustomLoader();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildList(
              controller,
              isEmpty: controller.drives.isEmpty,
              emptyTitle: 'No placement drives',
              emptyMessage: 'New drives will show up here.',
              children: [
                for (final drive in controller.drives)
                  _DriveCard(drive: drive, controller: controller),
              ],
            ),
            _buildList(
              controller,
              isEmpty: controller.applications.isEmpty,
              emptyTitle: 'No applications yet',
              emptyMessage: 'Apply to a drive from the Drives tab.',
              children: [
                SectionCard(
                  title: 'My Applications',
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final application in controller.applications)
                        _ApplicationTile(application: application),
                    ],
                  ),
                ),
              ],
            ),
            _buildList(
              controller,
              isEmpty: controller.placedStudents.isEmpty,
              emptyTitle: 'No placements yet',
              emptyMessage: 'Your placement will show up here once you are placed.',
              children: [
                SectionCard(
                  title: 'My Placements',
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final placed in controller.placedStudents) _PlacedTile(placed: placed),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  /// One tab's scrollable, pull-to-refresh list, or an empty message.
  Widget _buildList(
    StudentPlacementController controller, {
    required bool isEmpty,
    required String emptyTitle,
    required String emptyMessage,
    required List<Widget> children,
  }) {
    return RefreshIndicator(
      onRefresh: controller.loadPlacements,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: isEmpty
            ? [
                const SizedBox(height: 60),
                EmptyStateWidget(
                  icon: Icons.work_outline,
                  title: emptyTitle,
                  message: emptyMessage,
                ),
              ]
            : children,
      ),
    );
  }
}

/// One placement drive: company, date, positions, package, who can
/// apply, and an Apply button (or the application's status if already
/// applied).
class _DriveCard extends StatelessWidget {
  final PlacementDriveModel drive;
  final StudentPlacementController controller;

  const _DriveCard({required this.drive, required this.controller});

  Future<void> _apply(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply to ${drive.companyName}?'),
        content: const Text('Your profile will be sent to the placement cell.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await controller.apply(drive);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? null : AppColors.statusRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = [
      if (drive.date != null) formatDate(drive.date!),
      if (drive.positions > 0) '${drive.positions} positions',
      if (drive.packageText.isNotEmpty) drive.packageText,
    ].join(' · ');

    final eligibleFor = [...drive.courses, ...drive.branches].join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    drive.companyName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (drive.status.isNotEmpty) StatusBadge(label: drive.status, type: BadgeType.info),
              ],
            ),
            if (drive.role.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(drive.role, style: const TextStyle(fontSize: 12.5)),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(details, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
            if (drive.eligibility.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Eligibility: ${drive.eligibility}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
            if (eligibleFor.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'For: $eligibleFor',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (drive.pdfUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => openLink(drive.pdfUrl),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Details'),
                  ),
                const Spacer(),
                Obx(() {
                  final application = controller.applicationFor(drive);
                  if (application != null) {
                    return StatusBadge(
                      label: _titleCase(application.status.isEmpty ? 'Applied' : application.status),
                      type: BadgeType.success,
                    );
                  }

                  final isApplying = controller.applyingDriveId.value == drive.id;
                  return FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      minimumSize: const Size(0, 34),
                    ),
                    onPressed: isApplying || controller.applyingDriveId.value != null
                        ? null
                        : () => _apply(context),
                    child: isApplying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : const Text('Apply'),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in "My Applications".
class _ApplicationTile extends StatelessWidget {
  final PlacementApplicationModel application;

  const _ApplicationTile({required this.application});

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
                  application.companyName.isEmpty ? 'Drive #${application.driveId}' : application.companyName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                if (application.appliedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Applied ${formatDate(application.appliedAt!)}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (application.resumeUrl.isNotEmpty)
            IconButton(
              tooltip: 'Resume',
              icon: const Icon(Icons.description_outlined, size: 20),
              onPressed: () => openLink(application.resumeUrl),
            ),
          StatusBadge(
            label: _titleCase(application.status.isEmpty ? 'Applied' : application.status),
            type: application.status.toLowerCase() == 'rejected' ? BadgeType.danger : BadgeType.info,
          ),
        ],
      ),
    );
  }
}

/// One row in "Placed Students".
class _PlacedTile extends StatelessWidget {
  final PlacedStudentModel placed;

  const _PlacedTile({required this.placed});

  @override
  Widget build(BuildContext context) {
    final packageValue = double.tryParse(placed.packageLpa);
    final packageText = packageValue == null
        ? placed.packageLpa
        : '${packageValue == packageValue.roundToDouble() ? packageValue.round() : packageValue} LPA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: placed.isMe ? AppColors.statusGreen.withValues(alpha: 0.08) : null,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placed.isMe ? '${placed.studentName} (You)' : placed.studentName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    placed.companyName,
                    if (placed.date != null) formatDate(placed.date!),
                  ].join(' · '),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (packageText.isNotEmpty)
            Text(packageText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

/// "applied" -> "Applied".
String _titleCase(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
