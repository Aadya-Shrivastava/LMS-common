import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_attendance_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/student/attendance_log_entry_model.dart';
import 'package:lms/models/student/attendance_settings_model.dart';
import 'package:lms/models/student/subject_attendance_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/error_state_widget.dart';
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
        final error = controller.errorMessage.value;
        if (error != null && !controller.hasLoaded) {
          return ErrorStateWidget(message: error, onRetry: controller.loadAttendance);
        }
        if (controller.isLoading.value && !controller.hasLoaded) {
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
                        if (controller.subjectWiseAttendance.isEmpty)
                          const Text(
                            'No attendance marked yet.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        for (final subject in controller.subjectWiseAttendance)
                          _SubjectAttendanceBar(
                            subject: subject,
                            minRequiredPercent: controller.minRequiredPercent,
                          ),
                      ],
                    ),
                  );
                }

                return _buildLogCard();
              }),
              const SizedBox(height: 16),
              _buildCalendarCard(),
              const SizedBox(height: 16),
              _buildRulesCard(),
              const SizedBox(height: 16),
              _buildWorkingDaysCard(),
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

  /// The compact Attendance Log card. It's capped to a short,
  /// scrollable box so the calendar below stays in view. If a day is
  /// picked on the calendar, the log narrows to just that day and a
  /// small "clear" button appears beside the title.
  Widget _buildLogCard() {
    return Obx(() {
      final log = controller.filteredLog;
      final pickedDate = controller.selectedDate.value;

      return SectionCard(
        title: 'Attendance Log',
        padding: EdgeInsets.zero,
        trailing: pickedDate == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
              ),
        child: log.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Text(
                  'No attendance entries match this filter/month.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: Scrollbar(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: log.length,
                    itemBuilder: (context, index) => _LogTile(entry: log[index]),
                  ),
                ),
              ),
      );
    });
  }

  /// A month calendar for the selected month: each day is tinted by
  /// that day's attendance (green = all present, red = all absent,
  /// orange = mixed). Tapping a day narrows the log above to it.
  Widget _buildCalendarCard() {
    return Obx(() {
      final month = controller.selectedMonth.value;
      final byDay = controller.entriesByDayForSelectedMonth;
      final picked = controller.selectedDate.value;
      final today = DateTime.now();

      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final leadingBlanks = month.weekday - 1; // Monday-first grid
      final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

      final cells = <Widget>[];
      for (var i = 0; i < totalCells; i++) {
        final dayNum = i - leadingBlanks + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          cells.add(const SizedBox.shrink());
          continue;
        }
        final date = DateTime(month.year, month.month, dayNum);
        cells.add(_CalendarDayCell(
          day: dayNum,
          entries: byDay[dayNum] ?? const [],
          isToday: date.year == today.year && date.month == today.month && date.day == today.day,
          isSelected: picked != null &&
              picked.year == date.year &&
              picked.month == date.month &&
              picked.day == date.day,
          onTap: () => controller.toggleDate(date),
        ));
      }

      return SectionCard(
        title: 'Attendance Calendar',
        trailing: Text(
          '${_monthNames[month.month - 1]} ${month.year}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var row = 0; row < totalCells ~/ 7; row++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: cells[row * 7 + col],
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 14,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _LegendDot(color: AppColors.statCardGreen, label: 'Present'),
                _LegendDot(color: AppColors.statusRed, label: 'Absent'),
                _LegendDot(color: AppColors.statCardOrange, label: 'Partial'),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// The campus attendance rules: the minimum % needed, when a warning
  /// kicks in, and when exams get locked.
  Widget _buildRulesCard() {
    return Obx(() {
      final rules = controller.rules.value;

      return SectionCard(
        title: 'Attendance Rules',
        child: rules == null
            ? const Text(
                'Your campus hasn\'t set attendance rules yet.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              )
            : Column(
                children: [
                  _InfoLine(
                    label: 'Minimum attendance required',
                    value: '${rules.minRequiredPercent.round()}%',
                  ),
                  _InfoLine(
                    label: 'Low attendance warning below',
                    value: '${rules.lowAlertPercent.round()}%',
                  ),
                  _InfoLine(
                    label: 'Exams locked below',
                    value: '${rules.examLockPercent.round()}%',
                  ),
                  _InfoLine(
                    label: 'Late check-in grace period',
                    value: '${rules.lateGraceMinutes} min',
                  ),
                ],
              ),
      );
    });
  }

  /// Which days of the week the campus is open, and for which shift.
  Widget _buildWorkingDaysCard() {
    return Obx(() {
      final days = controller.workingDays;

      return SectionCard(
        title: 'Working Days',
        child: days.isEmpty
            ? const Text(
                'No working days have been set up yet.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              )
            : Column(
                children: [
                  for (final day in days) _WorkingDayRow(day: day),
                ],
              ),
      );
    });
  }
}

/// One day square in the attendance calendar.
class _CalendarDayCell extends StatelessWidget {
  final int day;
  final List<AttendanceLogEntryModel> entries;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.entries,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  Color? get _statusColor {
    if (entries.isEmpty) return null;
    final present = entries.where((e) => e.isPresent).length;
    if (present == entries.length) return AppColors.statCardGreen;
    if (present == 0) return AppColors.statusRed;
    return AppColors.statCardOrange;
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusColor;
    final background = isSelected
        ? AppColors.primaryNavy
        : status?.withValues(alpha: 0.18) ?? Colors.transparent;
    final textColor = isSelected ? AppColors.white : (status ?? AppColors.textPrimary);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.primaryNavy, width: 1.5)
                : null,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: status != null || isToday ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A colored dot + label in the calendar legend.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// A "label ........ value" row inside the Attendance Rules card.
class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in "Working Days", e.g. "Monday · Morning Shift  [Working]".
class _WorkingDayRow extends StatelessWidget {
  final WorkingDayModel day;

  const _WorkingDayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.day,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                if (day.shift.isNotEmpty)
                  Text(
                    day.shift,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          StatusBadge(
            label: day.status.isEmpty ? '—' : day.status,
            type: day.isWorking ? BadgeType.success : BadgeType.neutral,
          ),
        ],
      ),
    );
  }
}

/// One progress bar in "Subject-wise Attendance".
class _SubjectAttendanceBar extends StatelessWidget {
  final SubjectAttendanceModel subject;

  /// Below this % the bar turns red (from the campus attendance rules).
  final double minRequiredPercent;

  const _SubjectAttendanceBar({required this.subject, required this.minRequiredPercent});

  @override
  Widget build(BuildContext context) {
    // Color the bar red once it dips under the campus minimum.
    final color = subject.percent < minRequiredPercent ? AppColors.statusRed : AppColors.statCardGreen;

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
    final color = entry.isPresent ? AppColors.statCardGreen : AppColors.statusRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                Text(
                  '${formatDate(entry.date)} · ${entry.markedByFacultyName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.isPresent ? 'P' : 'A',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
