import '../../core/utils/date_formatters.dart';

/// Where an exam is right now, worked out from its start time and
/// duration.
enum ExamStatus { upcoming, live, finished }

/// One online exam for the student's batch.
class ExamModel {
  final String id;
  final String title;
  final String subject;

  /// e.g. "Chapter-1 LLM". Can be empty.
  final String chapter;

  /// Null if the exam hasn't been scheduled yet.
  final DateTime? startTime;
  final int durationMinutes;

  /// How many questions the student will be asked. 0 if not known.
  final int questionCount;

  /// e.g. "Mid Term". Empty when the faculty didn't pick a type.
  final String typeName;

  const ExamModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.chapter,
    required this.startTime,
    required this.durationMinutes,
    required this.questionCount,
    required this.typeName,
  });

  /// e.g. "25 Oct, 02:00 PM", or "Not scheduled".
  String get dateTimeText => startTime == null ? 'Not scheduled' : formatDateTime(startTime!);

  /// e.g. "60 min" or "1 hr 30 min".
  String get durationText {
    if (durationMinutes <= 0) return '';
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours == 0) return '$minutes min';
    return minutes == 0 ? '$hours hr' : '$hours hr $minutes min';
  }

  ExamStatus get status {
    final start = startTime;
    if (start == null) return ExamStatus.upcoming;

    final now = DateTime.now();
    if (now.isBefore(start)) return ExamStatus.upcoming;
    if (now.isBefore(start.add(Duration(minutes: durationMinutes)))) return ExamStatus.live;
    return ExamStatus.finished;
  }
}
