import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/faculty/faculty_course_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/faculty/timetable_slot_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import 'package:lms/widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/stat_pill.dart';

/// The "My Timetable" screen: a few quick stats, a day picker, and the
/// list of periods for whichever day is selected.
///
/// The real prototype shows a full Monday-Saturday grid side by side,
/// which is great on a wide desktop screen but wouldn't fit on a phone.
/// So here we show one day at a time instead, picked with the chips
/// at the top - same information, laid out for a small screen.
class TimetableScreen extends GetView<FacultyCourseController> {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'My Timetable',
        subtitle: 'Weekly teaching schedule',
      ),
      drawer: const AppDrawer(currentRoute: Routes.facultyTimetable),
      body: Obx(() {
        if (controller.isLoadingTimetable.value) {
          return const CustomLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.loadTimetable,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildDayPicker(),
              const SizedBox(height: 16),
              SectionCard(
                title: controller.selectedDay.value,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final slot in controller.selectedDaySlots)
                      _TimetableSlotTile(slot: slot),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsRow() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StatPill(
            title: 'Periods / Week',
            value: '${controller.periodsPerWeek.value}',
            icon: Icons.event_repeat_outlined,
            accentColor: AppColors.statCardBlue,
          ),
          const SizedBox(width: 10),
          StatPill(
            title: 'Batches',
            value: '${controller.batchesAssigned}',
            icon: Icons.groups_outlined,
            accentColor: AppColors.statCardOrange,
          ),
          const SizedBox(width: 10),
          StatPill(
            title: 'Subjects',
            value: '${controller.subjectCount}',
            icon: Icons.menu_book_outlined,
            accentColor: AppColors.statCardGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDayPicker() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.weekDays.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = controller.weekDays[index];
          final isSelected = day == controller.selectedDay.value;

          return ChoiceChip(
            label: Text(day.substring(0, 3)),
            selected: isSelected,
            onSelected: (_) => controller.selectDay(day),
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
  }
}

/// One row in the selected day's timetable: either a class, a free
/// period, or a break.
class _TimetableSlotTile extends StatelessWidget {
  final TimetableSlotModel slot;

  const _TimetableSlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    if (slot.kind == TimetableSlotKind.breakSlot) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Text(
          'Short Break · ${slot.timeRange}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    final isFree = slot.kind == TimetableSlotKind.free;
    // Only relevant for online classes: is the current time inside this
    // period's time range? If so, the "Join" button lights up.
    final canJoinNow = slot.isOnline && isNowWithinTimeRange(slot.timeRange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.period,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  slot.timeRange,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isFree
                ? const Text(
                    'Free Period',
                    style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.subject ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      Row(
                        children: [
                          Text(
                            '${slot.batch} · ${slot.room}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          if (slot.isOnline) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.wifi, size: 12, color: AppColors.statCardBlue),
                          ],
                        ],
                      ),
                    ],
                  ),
          ),
          // Online classes get a "Join" button - it's only tappable
          // while the current time is actually inside this period, so
          // faculty can't accidentally join a session that isn't live.
          if (slot.isOnline)
            _JoinButton(
              enabled: canJoinNow,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joining ${slot.subject}...')),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// The small "Join" button next to an online timetable slot. It's
/// filled and tappable when the class is happening right now, and
/// greyed out and disabled otherwise.
class _JoinButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _JoinButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryNavy,
        disabledBackgroundColor: AppColors.cardBorder,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 32),
      ),
      icon: const Icon(Icons.videocam_outlined, size: 15),
      label: const Text('Join', style: TextStyle(fontSize: 12)),
    );
  }
}
