/// One student's result for an online MCQ test.
///
/// The score isn't stored as a number directly - it's always
/// calculated fresh from `correctAnswers` / `totalQuestions`, the same
/// way a real auto-graded MCQ test would work.
class TestSubmissionModel {
  final String studentName;
  final String studentInitials;
  final String testName;
  final int correctAnswers;
  final int totalQuestions;

  const TestSubmissionModel({
    required this.studentName,
    required this.studentInitials,
    required this.testName,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  /// The score as a percentage, e.g. 80.0 for 16/20 correct.
  double get scorePercent {
    if (totalQuestions == 0) return 0;
    return (correctAnswers / totalQuestions) * 100;
  }
}
