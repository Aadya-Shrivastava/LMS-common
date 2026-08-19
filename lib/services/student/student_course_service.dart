import 'package:lms/models/student/recorded_lecture_model.dart';
import 'package:lms/models/student/student_class_schedule_model.dart';
import 'package:lms/models/student/student_study_material_model.dart';
import 'package:lms/models/student/student_timetable_slot_model.dart';

/// Provides everything for the student's course-related screens: Live
/// Classes, My Timetable, and Study Materials.
class StudentCourseService {
  // ---- Live Classes ----

  Future<List<StudentClassScheduleModel>> getTodaysClassSchedule() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      StudentClassScheduleModel(
        timeRange: '09:00 - 10:00 AM',
        subject: 'Basic Electrical Wiring',
        facultyName: 'Er. R. Kumar',
        platform: 'Google Meet',
        status: StudentClassStatus.live,
        meetingLink: 'https://meet.google.com/live-class',
      ),
      StudentClassScheduleModel(
        timeRange: '11:00 - 12:00 PM',
        subject: 'Workshop Safety',
        facultyName: 'S. Pandey',
        platform: 'Zoom',
        status: StudentClassStatus.upcoming,
      ),
      StudentClassScheduleModel(
        timeRange: '02:00 - 03:00 PM',
        subject: 'Employability Skills',
        facultyName: 'N. Singh',
        platform: 'Google Meet',
        status: StudentClassStatus.upcoming,
      ),
    ];
  }

  Future<List<RecordedLectureModel>> getRecordedLectures() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      RecordedLectureModel(
        tag: 'Electrician',
        title: 'Wiring Basics - Session 4',
        durationText: '42 min',
        facultyName: 'Er. R. Kumar',
      ),
      RecordedLectureModel(
        tag: 'Electrician',
        title: 'Circuit Diagrams - Session 3',
        durationText: '38 min',
        facultyName: 'Er. R. Kumar',
      ),
      RecordedLectureModel(
        tag: 'General',
        title: 'Workshop Safety Protocols',
        durationText: '25 min',
        facultyName: 'S. Pandey',
      ),
    ];
  }

  // ---- Timetable ----

  List<String> get weekDays => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ];

  Future<List<StudentTimetableSlotModel>> getSlotsForDay(String day) async {
    await Future.delayed(const Duration(milliseconds: 300));

    StudentTimetableSlotModel classSlot(
      String period,
      String time,
      String subject,
      String faculty,
      String room,
    ) {
      return StudentTimetableSlotModel(
        period: period,
        timeRange: time,
        kind: StudentTimetableSlotKind.classSlot,
        subject: subject,
        facultyName: faculty,
        room: room,
      );
    }

    StudentTimetableSlotModel onlineSlot(
      String period,
      String time,
      String subject,
      String faculty,
    ) {
      return StudentTimetableSlotModel(
        period: period,
        timeRange: time,
        kind: StudentTimetableSlotKind.classSlot,
        subject: subject,
        facultyName: faculty,
        room: 'Online',
        isOnline: true,
        meetingLink: 'https://meet.google.com/timetable-session',
      );
    }

    StudentTimetableSlotModel free(String period, String time) {
      return StudentTimetableSlotModel(
        period: period,
        timeRange: time,
        kind: StudentTimetableSlotKind.free,
      );
    }

    const breakSlot = StudentTimetableSlotModel(
      period: 'Break',
      timeRange: '11:15 - 11:30',
      kind: StudentTimetableSlotKind.breakSlot,
    );

    switch (day) {
      case 'Monday':
        return [
          onlineSlot('P1', '09:00-09:45', 'Basic Electrical Wiring', 'Er. R. Kumar'),
          classSlot('P2', '09:45-10:30', 'Basic Electrical Wiring', 'Er. R. Kumar', 'R-101'),
          breakSlot,
          classSlot('P4', '11:30-12:15', 'Employability Skills', 'N. Singh', 'R-101'),
        ];
      case 'Tuesday':
        return [
          onlineSlot('P1', '09:00-09:45', 'Circuit Design', 'Er. R. Kumar'),
          classSlot('P2', '09:45-10:30', 'Circuit Design', 'Er. R. Kumar', 'R-101'),
          breakSlot,
          free('P4', '11:30-12:15'),
        ];
      case 'Wednesday':
        return [
          classSlot('P1', '09:00-09:45', 'Workshop Safety', 'S. Pandey', 'W-201'),
          classSlot('P2', '09:45-10:30', 'Workshop Safety', 'S. Pandey', 'W-201'),
          breakSlot,
          classSlot('P4', '11:30-12:15', 'Basic Electrical Wiring', 'Er. R. Kumar', 'R-101'),
        ];
      case 'Thursday':
        return [
          onlineSlot('P1', '09:00-09:45', 'Basic Electrical Wiring', 'Er. R. Kumar'),
          free('P2', '09:45-10:30'),
          breakSlot,
          classSlot('P4', '11:30-12:15', 'Circuit Design', 'Er. R. Kumar', 'R-101'),
        ];
      case 'Friday':
        return [
          classSlot('P1', '09:00-09:45', 'Employability Skills', 'N. Singh', 'R-101'),
          onlineSlot('P2', '09:45-10:30', 'Circuit Design', 'Er. R. Kumar'),
          breakSlot,
          classSlot('P4', '11:30-12:15', 'Workshop Safety', 'S. Pandey', 'W-201'),
        ];
      case 'Saturday':
        return [
          classSlot('P1', '09:00-09:45', 'Circuit Design', 'Er. R. Kumar', 'R-101'),
          classSlot('P2', '09:45-10:30', 'Circuit Design', 'Er. R. Kumar', 'R-101'),
          breakSlot,
          free('P4', '11:30-12:15'),
        ];
      default:
        return [];
    }
  }

  // ---- Study Materials ----

  Future<List<StudentStudyMaterialModel>> getStudyMaterials() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      StudentStudyMaterialModel(
        id: 'sm-1',
        title: 'Chapter 4 - Wiring Diagrams Notes',
        subject: 'Basic Electrical Wiring',
        type: StudentMaterialType.pdf,
        uploadedByFacultyName: 'Er. R. Kumar',
        dateText: '29 Jul 2026',
      ),
      StudentStudyMaterialModel(
        id: 'sm-2',
        title: 'Circuit Design Reference',
        subject: 'Basic Electrical Wiring',
        type: StudentMaterialType.pdf,
        uploadedByFacultyName: 'Er. R. Kumar',
        dateText: '25 Jul 2026',
      ),
      StudentStudyMaterialModel(
        id: 'sm-3',
        title: 'Workshop Safety Handbook',
        subject: 'Workshop Safety',
        type: StudentMaterialType.pdf,
        uploadedByFacultyName: 'S. Pandey',
        dateText: '20 Jul 2026',
      ),
      StudentStudyMaterialModel(
        id: 'sm-4',
        title: 'Interview Preparation Guide',
        subject: 'Employability Skills',
        type: StudentMaterialType.document,
        uploadedByFacultyName: 'N. Singh',
        dateText: '15 Jul 2026',
      ),
      StudentStudyMaterialModel(
        id: 'sm-5',
        title: 'Practical Demo - Wiring',
        subject: 'Basic Electrical Wiring',
        type: StudentMaterialType.video,
        uploadedByFacultyName: 'Er. R. Kumar',
        dateText: '10 Jul 2026',
      ),
    ];
  }
}
