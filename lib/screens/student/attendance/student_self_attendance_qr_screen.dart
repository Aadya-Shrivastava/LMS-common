import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_self_attendance_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/student/self_attendance_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/filter_card.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// The "Self Attendance (QR)" screen, split into two tabs:
///   - "Mark Attendance": the live session banner, plus the QR-scan
///     and app-location check-in cards.
///   - "History": every attendance entry the student has self-marked.
class StudentSelfAttendanceQrScreen extends StatefulWidget {
  const StudentSelfAttendanceQrScreen({super.key});

  @override
  State<StudentSelfAttendanceQrScreen> createState() =>
      _StudentSelfAttendanceQrScreenState();
}

class _StudentSelfAttendanceQrScreenState extends State<StudentSelfAttendanceQrScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentSelfAttendanceController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Self Attendance',
        subtitle: 'Mark your own attendance via QR code or app location',
        fallbackRoute: Routes.studentDashboard,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Mark Attendance'),
            Tab(text: 'History'),
          ],
        ),
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentSelfAttendanceQr),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const CustomLoader();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildMarkTab(controller),
            _buildHistoryTab(controller),
          ],
        );
      }),
    );
  }

  Widget _buildMarkTab(StudentSelfAttendanceController controller) {
    final session = controller.currentSession.value;

    return RefreshIndicator(
      onRefresh: controller.loadSelfAttendance,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session != null) _CurrentSessionBanner(session: session),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Scan Class QR Code',
            child: Column(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_outlined,
                    size: 56,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Point your camera at the QR code displayed by your faculty to mark attendance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                    onPressed: session == null
                        ? null
                        : () {
                            controller.markCurrentSession(SelfAttendanceMode.qrCode);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Attendance marked for ${session.subject}')),
                            );
                          },
                    child: const Text('Scan QR Code'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'App Location Check-in',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.statusGreenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.my_location, color: AppColors.statusGreen),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Location Detected', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            'Within campus geofence · Workshop Block',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _LocationDetailRow(label: 'Distance from Campus', value: '32 m'),
                const _LocationDetailRow(label: 'GPS Accuracy', value: 'High'),
                const _LocationDetailRow(label: 'Wi-Fi Network', value: 'MGB-Campus'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                    onPressed: session == null
                        ? null
                        : () {
                            controller.markCurrentSession(SelfAttendanceMode.appLocation);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Attendance marked for ${session.subject}')),
                            );
                          },
                    child: const Text("Confirm I'm in Class"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(StudentSelfAttendanceController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadSelfAttendance,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHistoryFilterCards(controller),
          const SizedBox(height: 16),
          _buildMonthSlider(controller),
          const SizedBox(height: 16),
          _buildHistoryLogCard(controller),
        ],
      ),
    );
  }

  Widget _buildHistoryFilterCards(StudentSelfAttendanceController controller) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'All',
                  value: '${controller.allCountForSelectedMonth}',
                  color: AppColors.statCardBlue,
                  selected: controller.activeFilter.value == SelfAttendanceFilter.all,
                  onTap: () => controller.selectFilter(SelfAttendanceFilter.all),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Present',
                  value: '${controller.presentCountForSelectedMonth}',
                  color: AppColors.statCardGreen,
                  selected: controller.activeFilter.value == SelfAttendanceFilter.present,
                  onTap: () => controller.selectFilter(SelfAttendanceFilter.present),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Not Marked',
                  value: '${controller.notMarkedCountForSelectedMonth}',
                  color: AppColors.statusRed,
                  selected: controller.activeFilter.value == SelfAttendanceFilter.notMarked,
                  onTap: () => controller.selectFilter(SelfAttendanceFilter.notMarked),
                )),
          ),
        ],
      ),
    );
  }

  /// The horizontal sliding row of month chips - the current month is
  /// selected by default, but every other month in the last 6 is also
  /// tappable, and picking one filters everything above and below it
  /// down to just that month.
  Widget _buildMonthSlider(StudentSelfAttendanceController controller) {
    return Obx(() {
      final months = controller.availableMonths;
      final selected = controller.selectedMonth.value;

      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: months.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final month = months[index];
            final isSelected = month.year == selected.year && month.month == selected.month;

            return ChoiceChip(
              label: Text(_monthNames[month.month - 1]),
              selected: isSelected,
              onSelected: (_) => controller.selectMonth(month),
              selectedColor: AppColors.primaryNavy,
              backgroundColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryNavy : AppColors.cardBorder,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  /// The self-marked log, with a small "pick a date" calendar button
  /// beside its title - tapping it opens a date picker, and once a
  /// day is picked, narrows the log below down to just that one day
  /// (and jumps the month slider to match).
  Widget _buildHistoryLogCard(StudentSelfAttendanceController controller) {
    return Obx(() {
      final log = controller.filteredLog;
      final pickedDate = controller.selectedDate.value;

      return SectionCard(
        title: 'My Self-Marked Attendance Log',
        padding: EdgeInsets.zero,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pickedDate != null) ...[
              Text(
                formatDate(pickedDate),
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Clear date',
                visualDensity: VisualDensity.compact,
                onPressed: controller.clearSelectedDate,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              tooltip: 'Pick a date',
              visualDensity: VisualDensity.compact,
              onPressed: () => _pickHistoryDate(controller),
            ),
          ],
        ),
        child: log.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyStateWidget(
                  icon: Icons.qr_code_2_outlined,
                  title: 'Nothing here',
                  message: 'No attendance entries match this filter/month.',
                ),
              )
            : Column(
                children: [for (final entry in log) _SelfAttendanceLogTile(entry: entry)],
              ),
      );
    });
  }

  Future<void> _pickHistoryDate(StudentSelfAttendanceController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) controller.selectDate(picked);
  }
}

/// The gradient banner at the top of the "Mark Attendance" tab,
/// showing whichever class is currently in session.
class _CurrentSessionBanner extends StatelessWidget {
  final CurrentSessionModel session;

  const _CurrentSessionBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT SESSION',
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  [session.subject, session.batch].where((s) => s.isNotEmpty).join(' - '),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [session.facultyName, session.timeRange].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Live Now',
              style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _LocationDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfAttendanceLogTile extends StatelessWidget {
  final SelfAttendanceLogEntryModel entry;

  const _SelfAttendanceLogTile({required this.entry});

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
                  entry.subject,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.timeText.isEmpty
                      ? formatDate(entry.date)
                      : '${formatDate(entry.date)} · ${entry.timeText}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: entry.mode == SelfAttendanceMode.qrCode ? 'QR Code' : 'App Location',
            type: entry.mode == SelfAttendanceMode.qrCode ? BadgeType.info : BadgeType.neutral,
          ),
          const SizedBox(width: 8),
          StatusBadge(
            label: entry.isPresent ? 'Present' : 'Not Marked',
            type: entry.isPresent ? BadgeType.success : BadgeType.danger,
          ),
        ],
      ),
    );
  }
}
