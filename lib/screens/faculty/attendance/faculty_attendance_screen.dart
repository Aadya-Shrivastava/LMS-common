import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/faculty/faculty_attendance_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/faculty/attendance_row_model.dart';
import 'package:lms/models/faculty/biometric_entry_model.dart';
import 'package:lms/models/faculty/qr_scan_entry_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import '../../../widgets/compact_dropdown.dart';
import 'package:lms/widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';

const List<String> _subjects = ['Basic Electrical Wiring', 'Circuit Design'];
const List<String> _batches = ['Batch A', 'Batch B'];

/// The "Attendance" screen: pick a subject/batch/date, then mark
/// attendance using one of three modes - Manual, QR Code, or Biometric.
class FacultyAttendanceScreen extends GetView<FacultyAttendanceController> {
  const FacultyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Attendance',
        subtitle: 'Manual, QR or biometric mode',
      ),
      drawer: const AppDrawer(currentRoute: Routes.facultyAttendance),
      body: Obx(() {
        if (controller.isLoadingAttendance.value) {
          return const CustomLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.loadAttendance,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _AttendanceFilters(),
              const SizedBox(height: 10),
              const _AttendanceDatePicker(),
              const SizedBox(height: 16),
              _buildModeSelector(),
              const SizedBox(height: 16),
              _buildModeContent(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<AttendanceMode>(
      segments: const [
        ButtonSegment(value: AttendanceMode.manual, label: Text('Manual')),
        ButtonSegment(value: AttendanceMode.qrCode, label: Text('QR Code')),
        ButtonSegment(value: AttendanceMode.biometric, label: Text('Biometric')),
      ],
      selected: {controller.selectedMode.value},
      onSelectionChanged: (selection) => controller.selectMode(selection.first),
      // A smaller, denser style so the 3-way switch doesn't take up
      // more room than it needs to.
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primaryNavy,
        selectedForegroundColor: AppColors.white,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildModeContent() {
    switch (controller.selectedMode.value) {
      case AttendanceMode.manual:
        return const _ManualAttendancePanel();
      case AttendanceMode.qrCode:
        return const _QrAttendancePanel();
      case AttendanceMode.biometric:
        return const _BiometricAttendancePanel();
    }
  }
}

/// The subject/batch filter row shown above the attendance modes. Kept
/// deliberately small (no card, no labels) - just two compact
/// dropdowns side by side - so it doesn't eat into the space the
/// actual attendance list needs.
class _AttendanceFilters extends StatelessWidget {
  const _AttendanceFilters();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CompactDropdown<String>(
            value: _subjects.first,
            options: _subjects,
            labelFor: (option) => option,
            icon: Icons.menu_book_outlined,
            onChanged: (_) {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CompactDropdown<String>(
            value: _batches.first,
            options: _batches,
            labelFor: (option) => option,
            icon: Icons.groups_outlined,
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}

/// The calendar row: shows which date Manual mode is currently
/// looking at, and opens a date picker to jump to a different one -
/// that's how a faculty member checks (or corrects) a past day's
/// attendance instead of only ever seeing today's.
class _AttendanceDatePicker extends GetView<FacultyAttendanceController> {
  const _AttendanceDatePicker();

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedAttendanceDate.value,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      controller.selectAttendanceDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final date = controller.selectedAttendanceDate.value;
      final isToday = _isSameDay(date, DateTime.now());

      return InkWell(
        onTap: () => _pickDate(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.primaryNavy),
              const SizedBox(width: 8),
              Text(
                isToday ? 'Today · ${formatDate(date)}' : formatDate(date),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                'Change date',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    });
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ManualAttendancePanel extends StatefulWidget {
  const _ManualAttendancePanel();

  @override
  State<_ManualAttendancePanel> createState() => _ManualAttendancePanelState();
}

class _ManualAttendancePanelState extends State<_ManualAttendancePanel> {
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

    // This whole panel needs its own `Obx` - it's a separate widget
    // from the screen's outer `Obx`, so without this, ticking a
    // checkbox (which changes `manualRows`) wouldn't be noticed by
    // anything and the box would never visually update.
    return Obx(() {
      final query = _searchQuery.trim().toLowerCase();
      final rows =
          controller.manualRows.where((row) => row.studentName.toLowerCase().contains(query)).toList();
      final markedCount = controller.manualRows.where((row) => row.isPresent).length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            controller: _searchController,
            hint: 'Search student name',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          SectionCard(
            // Kept short on purpose - the subject is already shown in
            // the filter dropdown right above, so repeating the full
            // "Basic Electrical Wiring" name here just ate up the
            // space the "Marked" badge needed and caused it to overflow.
            title: 'Batch A',
            padding: EdgeInsets.zero,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: controller.markAllPresent,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                  child: const Text('Mark All', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                StatusBadge(
                  label: '$markedCount / ${controller.manualRows.length} Marked',
                  type: BadgeType.info,
                ),
              ],
            ),
            child: Column(
              children: [
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'No students match that search.',
                    ),
                  )
                else
                  for (final row in rows) _ManualAttendanceRow(row: row),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomButton(
                    text: 'Save Attendance',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance saved')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _ManualAttendanceRow extends GetView<FacultyAttendanceController> {
  final AttendanceRowModel row;

  const _ManualAttendanceRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: _initialsFor(row.studentName)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(
                  '${row.enrollmentNo} · ${row.monthlyPercent}% this month',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Checkbox(
            value: row.isPresent,
            activeColor: AppColors.primaryNavy,
            onChanged: (_) => controller.toggleManualPresent(row),
          ),
        ],
      ),
    );
  }
}

class _QrAttendancePanel extends StatefulWidget {
  const _QrAttendancePanel();

  @override
  State<_QrAttendancePanel> createState() => _QrAttendancePanelState();
}

class _QrAttendancePanelState extends State<_QrAttendancePanel> {
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

    return Obx(() {
      final query = _searchQuery.trim().toLowerCase();
      final entries =
          controller.qrScanLog.where((entry) => entry.studentName.toLowerCase().contains(query)).toList();

      return Column(
        children: [
          // A smaller QR card - it was taking up more room than a QR
          // code actually needs to be readable.
          SectionCard(
            title: 'QR Session',
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.qr_code_2, size: 66, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Session Code: QR-A102-0801',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Valid for 10 minutes · Campus Wi-Fi only',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {},
                      child: const Text('Start Session', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {},
                      child: const Text('Regenerate', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SearchField(
            controller: _searchController,
            hint: 'Search student name',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Live Scan Log',
            padding: EdgeInsets.zero,
            trailing: const StatusBadge(label: '24 / 42 Scanned', type: BadgeType.success),
            child: entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'No students match that search.',
                    ),
                  )
                : Column(
                    children: [
                      for (final entry in entries) _QrScanRow(entry: entry),
                    ],
                  ),
          ),
        ],
      );
    });
  }
}

class _QrScanRow extends StatelessWidget {
  final QrScanEntryModel entry;

  const _QrScanRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: entry.studentInitials),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
          Text(entry.scannedAtText, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(width: 10),
          _statusBadgeFor(entry.status),
        ],
      ),
    );
  }

  Widget _statusBadgeFor(String status) {
    switch (status) {
      case 'Present':
        return const StatusBadge(label: 'Present', type: BadgeType.success);
      case 'Late':
        return const StatusBadge(label: 'Late', type: BadgeType.warning);
      default:
        return const StatusBadge(label: 'Not Scanned', type: BadgeType.neutral);
    }
  }
}

class _BiometricAttendancePanel extends StatefulWidget {
  const _BiometricAttendancePanel();

  @override
  State<_BiometricAttendancePanel> createState() => _BiometricAttendancePanelState();
}

class _BiometricAttendancePanelState extends State<_BiometricAttendancePanel> {
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

    return Obx(() {
      final query = _searchQuery.trim().toLowerCase();
      final entries = controller.biometricLog
          .where((entry) => entry.studentName.toLowerCase().contains(query))
          .toList();

      return Column(
        children: [
          SearchField(
            controller: _searchController,
            hint: 'Search student name',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Biometric Sync - Batch A',
            padding: EdgeInsets.zero,
            trailing: OutlinedButton(onPressed: () {}, child: const Text('Sync Now')),
            child: Column(
              children: [
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'No students match that search.',
                    ),
                  )
                else
                  for (final entry in entries) _BiometricRow(entry: entry),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomButton(
                    text: 'Confirm & Save Attendance',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance saved')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _BiometricRow extends StatelessWidget {
  final BiometricEntryModel entry;

  const _BiometricRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(
                  'Punch: ${entry.punchTimeText} · ${entry.matchStatus}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _attendanceBadge(entry.attendanceStatus),
        ],
      ),
    );
  }

  Widget _attendanceBadge(String status) {
    switch (status) {
      case 'Present':
        return const StatusBadge(label: 'Present', type: BadgeType.success);
      case 'Absent':
        return const StatusBadge(label: 'Absent', type: BadgeType.danger);
      default:
        return const StatusBadge(label: 'Needs review', type: BadgeType.warning);
    }
  }
}

/// Turns a name like "Rahul Sharma" into initials like "RS".
String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length < 2) return name.substring(0, 2).toUpperCase();
  return (words.first[0] + words[1][0]).toUpperCase();
}
