/// How hard a question bank question is.
enum QuestionDifficulty { easy, medium, hard }

/// One multiple-choice question saved in a faculty member's question
/// bank.
///
/// Nothing here is `final` except `id` and `addedOnText` - a faculty
/// member can open a question and edit its text, its 4 options, its
/// correct answer, and its difficulty.
class QuestionBankItemModel {
  final String id;
  String questionText;
  QuestionDifficulty difficulty;

  /// Exactly 4 options, e.g. ["4 ohms", "2 ohms", "8 ohms", "1 ohm"].
  List<String> options;

  /// Which option is correct - an index into `options` (0 = first).
  int correctOptionIndex;

  /// Shown as text, e.g. "20 Jul 2026".
  final String addedOnText;

  QuestionBankItemModel({
    required this.id,
    required this.questionText,
    required this.difficulty,
    required this.addedOnText,
    this.options = const ['', '', '', ''],
    this.correctOptionIndex = 0,
  });
}
