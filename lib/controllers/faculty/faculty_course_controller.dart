import 'package:get/get.dart';
import 'package:lms/models/faculty/live_class_model.dart';
import 'package:lms/models/faculty/study_material_model.dart';
import 'package:lms/models/faculty/timetable_slot_model.dart';
import 'package:lms/services/faculty/live_class_service.dart';
import 'package:lms/services/faculty/study_material_service.dart';
import 'package:lms/services/faculty/timetable_service.dart';

/// Holds the data for the faculty course-related screens: Live
/// Classes, My Timetable, and Study Material Upload.
class FacultyCourseController extends GetxController {
  final LiveClassService _liveClassService = LiveClassService();
  final TimetableService _timetableService = TimetableService();
  final StudyMaterialService _studyMaterialService = StudyMaterialService();

  // ---- Live Classes ----

  final RxBool isLoadingClasses = true.obs;
  final RxList<LiveClassModel> scheduledClasses = <LiveClassModel>[].obs;

  // ---- Timetable ----

  final RxBool isLoadingTimetable = true.obs;

  /// How many periods per week - loaded once as reference data, since
  /// nothing in the app adds or removes timetable periods.
  final RxInt periodsPerWeek = 0.obs;

  // Defaults to today's actual weekday (e.g. opens on "Wednesday" if
  // that's what day it is), so the screen shows the timetable that's
  // actually relevant right now instead of always starting on Monday.
  final RxString selectedDay = _todayAsWeekday().obs;
  final RxList<TimetableSlotModel> selectedDaySlots =
      <TimetableSlotModel>[].obs;

  List<String> get weekDays => _timetableService.weekDays;

  /// How many distinct batches this faculty member currently has a
  /// live class scheduled for. Computed live from `scheduledClasses`,
  /// so scheduling a class for a new batch updates this immediately.
  int get batchesAssigned =>
      scheduledClasses.map((liveClass) => liveClass.batch).toSet().length;

  /// How many distinct subjects this faculty member currently has a
  /// live class scheduled for. Computed live from `scheduledClasses`,
  /// same as `batchesAssigned` above.
  int get subjectCount =>
      scheduledClasses.map((liveClass) => liveClass.subject).toSet().length;

  // ---- Study Material ----

  final RxBool isLoadingMaterials = true.obs;
  final RxList<StudyMaterialModel> materials = <StudyMaterialModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadScheduledClasses();
    loadTimetable();
    loadMaterials();
  }

  Future<void> loadScheduledClasses() async {
    isLoadingClasses.value = true;
    final classes = await _liveClassService.getScheduledClasses();
    scheduledClasses.assignAll(classes);
    isLoadingClasses.value = false;
  }

  /// Adds a brand new scheduled class to the top of the list.
  ///
  /// There's no real backend yet, so "scheduling a class" just means
  /// adding it to our in-memory list - it disappears again if the app
  /// restarts.
  void addScheduledClass(LiveClassModel newClass) {
    scheduledClasses.insert(0, newClass);
  }

  Future<void> loadTimetable() async {
    isLoadingTimetable.value = true;
    periodsPerWeek.value = await _timetableService.getPeriodsPerWeek();
    await _loadSlotsForSelectedDay();
    isLoadingTimetable.value = false;
  }

  /// Switches the timetable view to a different day, e.g. "Tuesday".
  Future<void> selectDay(String day) async {
    selectedDay.value = day;
    await _loadSlotsForSelectedDay();
  }

  Future<void> _loadSlotsForSelectedDay() async {
    final slots = await _timetableService.getSlotsForDay(selectedDay.value);
    selectedDaySlots.assignAll(slots);
  }

  Future<void> loadMaterials() async {
    isLoadingMaterials.value = true;
    final items = await _studyMaterialService.getMyMaterials();
    materials.assignAll(items);
    isLoadingMaterials.value = false;
  }

  /// Adds a brand new uploaded material to the top of the list.
  /// There's no real backend yet, so this is a local-only mock upload.
  void addMaterial(StudyMaterialModel newMaterial) {
    materials.insert(0, newMaterial);
  }

  /// Removes a material from the list - called after the user confirms
  /// the "are you sure?" dialog on the Study Material screen.
  void removeMaterial(StudyMaterialModel material) {
    materials.remove(material);
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
