/// The two kinds of exams shown on the Exams & Results screen.
enum ExamType { mcq, practical }

/// One upcoming exam or online test.
class ExamModel {
  final String title;
  final String subject;
  final String dateTimeText;
  final String durationText;
  final ExamType type;

  const ExamModel({
    required this.title,
    required this.subject,
    required this.dateTimeText,
    required this.durationText,
    required this.type,
  });
}
