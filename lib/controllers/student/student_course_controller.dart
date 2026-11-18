import 'dart:async';
import 'package:get/get.dart';
import '../../core/network/saved_then_fresh.dart';
import '../../core/notifications/class_reminder_service.dart';
import 'package:lms/models/student/recorded_lecture_model.dart';
import 'package:lms/models/student/student_class_schedule_model.dart';
import 'package:lms/models/student/student_study_material_model.dart';
import 'package:lms/models/student/student_timetable_slot_model.dart';
import 'package:lms/services/student/student_course_service.dart';

/// Holds the data for the student's course-related screens: Live
/// Classes, My Timetable, and Study Materials.
class StudentCourseController extends GetxController {
  final StudentCourseService _service = StudentCourseService();

  // ---- Live Classes ----

  final RxBool isLoadingClasses = true.obs;
  final RxList<StudentClassScheduleModel> todaysClassSchedule =
      <StudentClassScheduleModel>[].obs;
  final RxList<RecordedLectureModel> recordedLectures = <RecordedLectureModel>[].obs;

  /// Finished or cancelled classes, most recent first.
  final RxList<StudentClassScheduleModel> pastClasses = <StudentClassScheduleModel>[].obs;

  /// Ids of the classes the student set a reminder for.
  final RxSet<int> remindedClassIds = <int>{}.obs;

  final ClassReminderService _reminders = ClassReminderService.instance;

  /// Sets or removes the reminder for `item`. Returns the message to show.
  Future<String> toggleReminder(StudentClassScheduleModel item) async {
    if (remindedClassIds.contains(item.id)) {
      await _reminders.cancel(item.id);
      remindedClassIds.remove(item.id);
      return 'Reminder removed for ${item.subject}';
    }

    final startsAt = item.startsAt;
    if (startsAt == null) return "This class has no start time, so a reminder can't be set.";

    final result = await _reminders.schedule(
      id: item.id,
      subject: item.subject,
      startsAt: startsAt,
    );
    final minutes = ClassReminderService.remindBefore.inMinutes;
    switch (result) {
      case ReminderResult.scheduled:
        remindedClassIds.add(item.id);
        return "We'll remind you $minutes minutes before ${item.subject} starts";
      case ReminderResult.tooLate:
        return 'This class starts in less than $minutes minutes - you can join it now.';
      case ReminderResult.permissionDenied:
        return 'Please allow notifications for this app to get class reminders.';
      case ReminderResult.unsupported:
        return "Reminders aren't available on this device.";
    }
  }

  /// Set when the live classes failed to load.
  final RxnString classesError = RxnString();

  /// True once the live classes have loaded at least once, so a failed
  /// refresh keeps showing the old list instead of an error page.
  bool hasLoadedClasses = false;

  // ---- Timetable ----

  final RxBool isLoadingTimetable = true.obs;
  final RxnString timetableError = RxnString();
  bool hasLoadedTimetable = false;

  // Defaults to today's actual weekday, so the screen opens on the
  // timetable that's actually relevant right now.
  final RxString selectedDay = _todayAsWeekday().obs;
  final RxList<StudentTimetableSlotModel> selectedDaySlots =
      <StudentTimetableSlotModel>[].obs;

  /// The whole week from API 46, by day.
  final RxMap<String, List<StudentTimetableSlotModel>> _timetable =
      <String, List<StudentTimetableSlotModel>>{}.obs;

  List<String> get weekDays => _timetable.keys.isEmpty
      ? const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      : _timetable.keys.toList();

  /// How many distinct subjects show up in the selected day's
  /// timetable. Computed live, so it updates as the day changes.
  int get subjectCount => selectedDaySlots
      .where((slot) => slot.kind == StudentTimetableSlotKind.classSlot)
      .map((slot) => slot.subject)
      .toSet()
      .length;

  /// How many actual classes (not free periods/breaks) are on the
  /// selected day.
  int get classesOnSelectedDay => selectedDaySlots
      .where((slot) => slot.kind == StudentTimetableSlotKind.classSlot)
      .length;

  // ---- Study Materials ----

  final RxBool isLoadingMaterials = true.obs;
  final RxList<StudentStudyMaterialModel> materials = <StudentStudyMaterialModel>[].obs;
  final RxnString materialsError = RxnString();
  bool hasLoadedMaterials = false;

  /// "All Subjects" plus every subject that has materials, for the
  /// subject filter on the Study Materials screen.
  List<String> get materialSubjects => [
        'All Subjects',
        ...{for (final material in materials) material.subject}.where((s) => s.isNotEmpty),
      ];

  // Each screen loads only its own data (see the `ensure...` methods),
  // so opening My Timetable doesn't also wait on study materials.
  bool _startedClasses = false;
  bool _startedTimetable = false;
  bool _startedMaterials = false;

  /// Loads the live classes once, the first time a screen needs them.
  /// Safe to call from `build`: the load starts right after the frame.
  void ensureClassesLoaded() {
    if (_startedClasses) return;
    _startedClasses = true;
    Future.microtask(loadTodaysClassSchedule);
  }

  /// Loads the timetable once, the first time a screen needs it.
  void ensureTimetableLoaded() {
    if (_startedTimetable) return;
    _startedTimetable = true;
    Future.microtask(loadTimetable);
  }

  /// Loads the study materials once, the first time a screen needs them.
  void ensureMaterialsLoaded() {
    if (_startedMaterials) return;
    _startedMaterials = true;
    Future.microtask(loadMaterials);
  }

  Future<void> loadTodaysClassSchedule() async {
    _startedClasses = true;
    isLoadingClasses.value = true;
    classesError.value = null;

    classesError.value = await loadSavedThenFresh(_service.getLiveClasses, (result) {
      todaysClassSchedule.assignAll(result.schedule);
      pastClasses.assignAll(result.past);
      recordedLectures.assignAll(result.recorded);
      hasLoadedClasses = true;
      isLoadingClasses.value = false;
    });
    isLoadingClasses.value = false;

    // Which bells are on; the list never waits for this.
    unawaited(_reminders.scheduledIds().then(remindedClassIds.assignAll));
  }

  Future<void> loadTimetable() async {
    _startedTimetable = true;
    isLoadingTimetable.value = true;
    timetableError.value = null;

    timetableError.value = await loadSavedThenFresh(_service.getTimetable, (data) {
      _timetable.assignAll(data);
      hasLoadedTimetable = true;
      selectDay(selectedDay.value);
      isLoadingTimetable.value = false;
    });
    isLoadingTimetable.value = false;
  }

  /// Switches the timetable view to a different day, e.g. "Tuesday".
  void selectDay(String day) {
    selectedDay.value = day;
    selectedDaySlots.assignAll(_timetable[day] ?? const []);
  }

  Future<void> loadMaterials() async {
    _startedMaterials = true;
    isLoadingMaterials.value = true;
    materialsError.value = null;

    materialsError.value = await loadSavedThenFresh(_service.getStudyMaterials, (data) {
      materials.assignAll(data);
      hasLoadedMaterials = true;
      isLoadingMaterials.value = false;
    });
    isLoadingMaterials.value = false;
  }
}

/// Turns today's actual date into one of our weekday names, e.g.
/// "Wednesday". `DateTime.weekday` counts Monday=1 through Sunday=7;
/// since the timetable doesn't have a Sunday, we just fall back to
/// Monday on Sundays.
String _todayAsWeekday() {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final weekday = DateTime.now().weekday;
  return weekday == DateTime.sunday ? 'Monday' : names[weekday - 1];
}
