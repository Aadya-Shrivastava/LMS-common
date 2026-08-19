import 'package:get/get.dart';
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

  // ---- Timetable ----

  final RxBool isLoadingTimetable = true.obs;

  // Defaults to today's actual weekday, so the screen opens on the
  // timetable that's actually relevant right now.
  final RxString selectedDay = _todayAsWeekday().obs;
  final RxList<StudentTimetableSlotModel> selectedDaySlots =
      <StudentTimetableSlotModel>[].obs;

  List<String> get weekDays => _service.weekDays;

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

  @override
  void onInit() {
    super.onInit();
    loadTodaysClassSchedule();
    loadTimetable();
    loadMaterials();
  }

  Future<void> loadTodaysClassSchedule() async {
    isLoadingClasses.value = true;

    final results = await Future.wait([
      _service.getTodaysClassSchedule(),
      _service.getRecordedLectures(),
    ]);

    todaysClassSchedule.assignAll(results[0] as List<StudentClassScheduleModel>);
    recordedLectures.assignAll(results[1] as List<RecordedLectureModel>);

    isLoadingClasses.value = false;
  }

  Future<void> loadTimetable() async {
    isLoadingTimetable.value = true;
    await _loadSlotsForSelectedDay();
    isLoadingTimetable.value = false;
  }

  /// Switches the timetable view to a different day, e.g. "Tuesday".
  Future<void> selectDay(String day) async {
    selectedDay.value = day;
    await _loadSlotsForSelectedDay();
  }

  Future<void> _loadSlotsForSelectedDay() async {
    final slots = await _service.getSlotsForDay(selectedDay.value);
    selectedDaySlots.assignAll(slots);
  }

  Future<void> loadMaterials() async {
    isLoadingMaterials.value = true;
    final items = await _service.getStudyMaterials();
    materials.assignAll(items);
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
