import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_attendance_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/student/attendance_log_entry_model.dart';
import 'package:lms/models/student/subject_attendance_model.dart';
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

/// The "Attendance" screen: 4 filter cards (Overall/Present/Absent/
/// Subject-wise) above a sliding month picker.
///
/// The Overall/Present/Absent filters narrow the attendance log by
/// status; the Subject-wise filter swaps the log out for a
/// subject-wise breakdown instead. Whichever month is picked from the
/// slider, everything below - the card numbers and the log - only
/// describes that one month.
class StudentAttendanceScreen extends GetView<StudentAttendanceController> {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Attendance',
        subtitle: 'Daily attendance record and monthly summary',
        fallbackRoute: Routes.studentDashboard,
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentAttendance),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const CustomLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.loadAttendance,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFilterCards(),
              const SizedBox(height: 16),
              _buildMonthSlider(),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.activeFilter.value == AttendanceFilter.subjectWise) {
                  return SectionCard(
                    title: 'Subject-wise Attendance',
                    child: Column(
                      children: [
                        for (final subject in controller.subjectWiseAttendance)
                          _SubjectAttendanceBar(subject: subject),
                      ],
                    ),
                  );
                }

                return _buildLogCard(context);
              }),
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
                  label: 'Overall',
                  value: '${controller.overallPercentForSelectedMonth}%',
                  color: AppColors.statCardBlue,
                  selected: controller.activeFilter.value == AttendanceFilter.overall,
                  onTap: () => controller.selectFilter(AttendanceFilter.overall),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Present',
                  value: '${controller.presentCountForSelectedMonth}',
                  color: AppColors.statCardGreen,
                  selected: controller.activeFilter.value == AttendanceFilter.present,
                  onTap: () => controller.selectFilter(AttendanceFilter.present),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Absent',
                  value: '${controller.absentCountForSelectedMonth}',
                  color: AppColors.statusRed,
                  selected: controller.activeFilter.value == AttendanceFilter.absent,
                  onTap: () => controller.selectFilter(AttendanceFilter.absent),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => FilterCard(
                  label: 'Subject-wise',
                  value: '${controller.subjectWiseAttendance.length}',
                  color: AppColors.statCardOrange,
                  selected: controller.activeFilter.value == AttendanceFilter.subjectWise,
                  onTap: () => controller.selectFilter(AttendanceFilter.subjectWise),
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
  Widget _buildMonthSlider() {
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

  /// The Attendance Log card, with a small "pick a date" calendar
  /// button sitting right beside its title - tapping it opens a date
  /// picker, and once a day is picked, narrows the log below down to
  /// just that one day (and jumps the month slider to match).
  Widget _buildLogCard(BuildContext context) {
    return Obx(() {
      final log = controller.filteredLog;
      final pickedDate = controller.selectedDate.value;

      return SectionCard(
        title: 'Attendance Log',
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
              onPressed: () => _pickDate(context),
            ),
          ],
        ),
        child: log.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyStateWidget(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'Nothing here',
                  message: 'No attendance entries match this filter/month.',
                ),
              )
            : Column(
                children: [for (final entry in log) _LogTile(entry: entry)],
              ),
      );
    });
  }

  Future<void> _pickDate(BuildContext context) async {
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

/// One progress bar in "Subject-wise Attendance".
class _SubjectAttendanceBar extends StatelessWidget {
  final SubjectAttendanceModel subject;

  const _SubjectAttendanceBar({required this.subject});

  @override
  Widget build(BuildContext context) {
    // Attendance below 75% is usually the threshold institutions flag
    // as a shortage - color the bar red once it dips under that.
    final color = subject.percent < 75 ? AppColors.statusRed : AppColors.statCardGreen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject.subject,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${subject.percent.round()}%',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (subject.percent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the "Attendance Log".
class _LogTile extends StatelessWidget {
  final AttendanceLogEntryModel entry;

  const _LogTile({required this.entry});

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
                  '${formatDate(entry.date)} · Marked by ${entry.markedByFacultyName}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: entry.isPresent ? 'Present' : 'Absent',
            type: entry.isPresent ? BadgeType.success : BadgeType.danger,
          ),
        ],
      ),
    );
  }
}
