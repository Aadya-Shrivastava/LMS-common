import 'package:lms/models/faculty/timetable_slot_model.dart';

/// Provides a faculty member's weekly teaching timetable.
class TimetableService {
  /// How many periods this faculty member teaches per week. There's no
  /// screen that adds/removes timetable periods, so unlike the other
  /// stats on this screen, this one just stays as reference data.
  Future<int> getPeriodsPerWeek() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 22;
  }

  /// The days of the week, in order, used to build the day-picker.
  List<String> get weekDays => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ];

  /// Returns the timetable slots for one day of the week.
  Future<List<TimetableSlotModel>> getSlotsForDay(String day) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // A small helper so we don't have to repeat `TimetableSlotModel(...)`
    // with every field for a normal, in-person class slot.
    TimetableSlotModel classSlot(
      String period,
      String time,
      String subject,
      String batch,
      String room,
    ) {
      return TimetableSlotModel(
        period: period,
        timeRange: time,
        kind: TimetableSlotKind.classSlot,
        subject: subject,
        batch: batch,
        room: room,
      );
    }

    // Same as `classSlot`, but for a period held online instead of in a
    // physical room - this is what makes the "Join" button show up.
    TimetableSlotModel onlineSlot(
      String period,
      String time,
      String subject,
      String batch,
    ) {
      return TimetableSlotModel(
        period: period,
        timeRange: time,
        kind: TimetableSlotKind.classSlot,
        subject: subject,
        batch: batch,
        room: 'Online',
        isOnline: true,
        meetingLink: 'https://meet.google.com/timetable-session',
      );
    }

    TimetableSlotModel free(String period, String time) {
      return TimetableSlotModel(
        period: period,
        timeRange: time,
        kind: TimetableSlotKind.free,
      );
    }

    const breakSlot = TimetableSlotModel(
      period: 'Break',
      timeRange: '11:15 - 11:30',
      kind: TimetableSlotKind.breakSlot,
    );

    switch (day) {
      case 'Monday':
        return [
          onlineSlot('P1', '09:00-09:45', 'Basic Electrical Wiring', 'Batch A'),
          classSlot('P2', '09:45-10:30', 'Basic Electrical Wiring', 'Batch A', 'R-101'),
          breakSlot,
          free('P4', '11:30-12:15'),
        ];
      case 'Tuesday':
        return [
          onlineSlot('P1', '09:00-09:45', 'Circuit Design', 'Batch A'),
          classSlot('P2', '09:45-10:30', 'Circuit Design', 'Batch A', 'R-101'),
          breakSlot,
          free('P4', '11:30-12:15'),
        ];
      case 'Wednesday':
        return [
          free('P1', '09:00-09:45'),
          free('P2', '09:45-10:30'),
          breakSlot,
          classSlot('P4', '11:30-12:15', 'Basic Electrical Wiring', 'Batch A', 'R-101'),
        ];
      case 'Thursday':
        return [
          onlineSlot('P1', '09:00-09:45', 'Basic Electrical Wiring', 'Batch A'),
          free('P2', '09:45-10:30'),
          breakSlot,
          classSlot('P4', '11:30-12:15', 'Circuit Design', 'Batch A', 'R-101'),
        ];
      case 'Friday':
        return [
          classSlot('P1', '09:00-09:45', 'Circuit Design', 'Batch B', 'R-102'),
          onlineSlot('P2', '09:45-10:30', 'Circuit Design', 'Batch B'),
          breakSlot,
          free('P4', '11:30-12:15'),
        ];
      case 'Saturday':
        return [
          classSlot('P1', '09:00-09:45', 'Circuit Design', 'Batch A', 'R-101'),
          classSlot('P2', '09:45-10:30', 'Circuit Design', 'Batch A', 'R-101'),
          breakSlot,
          free('P4', '11:30-12:15'),
        ];
      default:
        return [];
    }
  }
}
