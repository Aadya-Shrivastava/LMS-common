import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/faculty/faculty_course_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/faculty/live_class_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import 'package:lms/widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dropdown_field.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';

/// The subjects and platforms this faculty member can pick from when
/// scheduling a class. In a real app these would come from the
/// backend; here they're just fixed lists, matching the prototype.
const List<String> _subjects = [
  'Basic Electrical Wiring',
  'Circuit Design',
  'Practical Lab',
];
const List<String> _batches = ['Batch A', 'Batch B'];
const List<String> _platforms = ['Google Meet', 'Zoom'];

/// The "Live Classes" screen: a form to schedule a new live class, and
/// a list of classes already scheduled.
class LiveClassesScreen extends GetView<FacultyCourseController> {
  const LiveClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Live Classes',
        subtitle: 'Schedule and manage live sessions',
      ),
      drawer: const AppDrawer(currentRoute: Routes.facultyLiveClasses),
      body: RefreshIndicator(
        onRefresh: controller.loadScheduledClasses,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ScheduleClassForm(controller: controller),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.isLoadingClasses.value) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CustomLoader(),
                );
              }

              return SectionCard(
                title: 'My Scheduled Classes',
                padding: EdgeInsets.zero,
                child: controller.scheduledClasses.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyStateWidget(
                          icon: Icons.videocam_off_outlined,
                          title: 'No classes yet',
                          message: 'Classes you schedule will show up here.',
                        ),
                      )
                    : Column(
                        children: [
                          for (final liveClass in controller.scheduledClasses)
                            _LiveClassTile(liveClass: liveClass),
                        ],
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// The "Schedule New Class" form card. This is its own StatefulWidget
/// because it needs to remember what the user has typed/picked so far.
class _ScheduleClassForm extends StatefulWidget {
  final FacultyCourseController controller;

  const _ScheduleClassForm({required this.controller});

  @override
  State<_ScheduleClassForm> createState() => _ScheduleClassFormState();
}

class _ScheduleClassFormState extends State<_ScheduleClassForm> {
  String _subject = _subjects.first;
  String _batch = _batches.first;
  String _platform = _platforms.first;
  DateTime? _dateTime;
  final _meetingLinkController = TextEditingController();

  @override
  void dispose() {
    _meetingLinkController.dispose();
    super.dispose();
  }

  /// Opens a date picker, then a time picker, and combines the two
  /// into one DateTime.
  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      _dateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _scheduleClass() {
    if (_dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date and time first')),
      );
      return;
    }

    final newClass = LiveClassModel(
      id: 'lc-${DateTime.now().millisecondsSinceEpoch}',
      subject: _subject,
      batch: _batch,
      dateTimeText: formatDateTime(_dateTime!),
      platform: _platform,
      meetingLink: _meetingLinkController.text.trim(),
      status: LiveClassStatus.upcoming,
    );

    widget.controller.addScheduledClass(newClass);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_subject scheduled for ${newClass.dateTimeText}')),
    );

    // Reset the form so it's ready for the next class.
    setState(() => _dateTime = null);
    _meetingLinkController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Schedule New Class',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          CustomDropdownField<String>(
            label: 'Platform',
            value: _platform,
            options: _platforms,
            labelFor: (option) => option,
            onChanged: (value) => setState(() => _platform = value!),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date & Time',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                _dateTime == null ? 'Tap to pick a date & time' : formatDateTime(_dateTime!),
                style: TextStyle(
                  color: _dateTime == null ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _meetingLinkController,
            label: 'Meeting Link',
            hint: 'https://meet.google.com/... or https://zoom.us/j/...',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          CustomButton(text: 'Schedule Class', onPressed: _scheduleClass),
        ],
      ),
    );
  }
}

/// One row in the "My Scheduled Classes" list.
class _LiveClassTile extends StatelessWidget {
  final LiveClassModel liveClass;

  const _LiveClassTile({required this.liveClass});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  liveClass.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _statusBadge(liveClass.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${liveClass.batch} · ${liveClass.platform} · ${liveClass.dateTimeText}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: liveClass.status == LiveClassStatus.completed
                ? OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Recording'),
                  )
                : FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                    icon: const Icon(Icons.videocam_outlined, size: 16),
                    label: const Text('Join'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(LiveClassStatus status) {
    switch (status) {
      case LiveClassStatus.live:
        return const StatusBadge(label: 'Live Now', type: BadgeType.danger);
      case LiveClassStatus.upcoming:
        return const StatusBadge(label: 'Upcoming', type: BadgeType.neutral);
      case LiveClassStatus.completed:
        return const StatusBadge(label: 'Completed', type: BadgeType.neutral);
    }
  }
}
