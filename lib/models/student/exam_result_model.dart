/// One past exam result, shown in "Result History".
class ExamResultModel {
  final String examTitle;
  final String subject;
  final String marksText;
  final String grade;
  final String rankText;

  const ExamResultModel({
    required this.examTitle,
    required this.subject,
    required this.marksText,
    required this.grade,
    required this.rankText,
  });
}
