/// One finished exam in "Result History" (API 22).
class ExamResultModel {
  /// The attempt id - matches `ExamAttemptModel.id`.
  final String id;

  final String examTitle;
  final String subject;
  final String scoreText;

  /// e.g. "Evaluated".
  final String statusText;

  final DateTime? submittedAt;

  const ExamResultModel({
    required this.id,
    required this.examTitle,
    required this.subject,
    required this.scoreText,
    required this.statusText,
    required this.submittedAt,
  });
}

/// The full detail of one exam attempt (API 20), with the answers the
/// student gave (API 21). Shown when a result is tapped.
class ExamAttemptModel {
  final String id;
  final String examTitle;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final String scoreText;
  final bool evaluated;

  /// How many times the student left the exam screen during the test.
  final int tabSwitches;

  /// True if time ran out and the exam submitted itself.
  final bool autoSubmitted;

  final List<ExamAnswerModel> answers;

  const ExamAttemptModel({
    required this.id,
    required this.examTitle,
    required this.startedAt,
    required this.submittedAt,
    required this.scoreText,
    required this.evaluated,
    required this.tabSwitches,
    required this.autoSubmitted,
    required this.answers,
  });

  /// How long the student took, e.g. "24 sec" or "12 min".
  String get timeTakenText {
    final start = startedAt;
    final end = submittedAt;
    if (start == null || end == null) return '—';

    final taken = end.difference(start);
    if (taken.inMinutes < 1) return '${taken.inSeconds} sec';
    return '${taken.inMinutes} min';
  }
}

/// One answer the student submitted in an exam.
class ExamAnswerModel {
  final String attemptId;
  final String questionId;

  /// The id of the option picked for a multiple-choice question, or
  /// empty for a written answer.
  final String selectedChoiceId;

  /// The written answer, or empty for a multiple-choice question.
  final String subjectiveAnswer;

  const ExamAnswerModel({
    required this.attemptId,
    required this.questionId,
    required this.selectedChoiceId,
    required this.subjectiveAnswer,
  });
}

/// One band of the campus grading scale (API 23), e.g. "A+ · 95-100% ·
/// 9.0 points · Excellent".
class GradeBandModel {
  final String grade;
  final double fromPercent;
  final double toPercent;
  final double gradePoint;
  final String remarks;

  const GradeBandModel({
    required this.grade,
    required this.fromPercent,
    required this.toPercent,
    required this.gradePoint,
    required this.remarks,
  });
}
