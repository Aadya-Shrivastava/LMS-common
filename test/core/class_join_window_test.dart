// Tests when a live class's Join button opens and when it counts as live.

import 'package:flutter_test/flutter_test.dart';
import 'package:lms/core/notifications/class_reminder_service.dart';
import 'package:lms/models/student/student_class_schedule_model.dart';

void main() {
  final start = DateTime(2026, 10, 28, 14, 0);
  final end = DateTime(2026, 10, 28, 15, 0);

  StudentClassScheduleModel classWith(StudentClassStatus status) => StudentClassScheduleModel(
        id: 1,
        timeRange: '',
        subject: 'Electricak',
        facultyName: '',
        platform: '',
        status: status,
        startsAt: start,
        endsAt: end,
      );

  final upcoming = classWith(StudentClassStatus.upcoming);

  test('Join opens 10 minutes before the start', () {
    expect(upcoming.canJoin(DateTime(2026, 10, 28, 13, 49)), isFalse);
    expect(upcoming.canJoin(DateTime(2026, 10, 28, 13, 50)), isTrue);
    expect(upcoming.isLiveNow(DateTime(2026, 10, 28, 13, 50)), isFalse, reason: 'not live yet');
  });

  test('live from the start time until the end, then closed', () {
    expect(upcoming.isLiveNow(DateTime(2026, 10, 28, 14, 0)), isTrue);
    expect(upcoming.canJoin(DateTime(2026, 10, 28, 14, 59)), isTrue);
    expect(upcoming.canJoin(DateTime(2026, 10, 28, 15, 0)), isFalse);
    expect(upcoming.isLiveNow(DateTime(2026, 10, 28, 15, 0)), isFalse);
  });

  test('finished or cancelled classes can never be joined', () {
    final during = DateTime(2026, 10, 28, 14, 30);
    expect(classWith(StudentClassStatus.completed).canJoin(during), isFalse);
    expect(classWith(StudentClassStatus.cancelled).canJoin(during), isFalse);
  });

  test('a class the server marks live can be joined', () {
    expect(classWith(StudentClassStatus.live).canJoin(DateTime(2026, 10, 28, 9, 0)), isTrue);
  });

  test('reminders do nothing (no crash) where the plugin is missing', () async {
    final reminders = ClassReminderService.instance;
    final result = await reminders.schedule(
      id: 1,
      subject: 'Electricak',
      startsAt: DateTime.now().add(const Duration(hours: 1)),
    );
    expect(result, ReminderResult.unsupported);
    expect(await reminders.scheduledIds(), isEmpty);
  });
}
