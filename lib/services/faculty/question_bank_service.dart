import 'package:lms/models/faculty/question_bank_item_model.dart';
import 'package:lms/models/faculty/test_submission_model.dart';

/// Provides a faculty member's saved question bank questions, and who
/// has taken their online tests.
class QuestionBankService {
  Future<List<QuestionBankItemModel>> getMyQuestions() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      QuestionBankItemModel(
        id: 'q1',
        questionText: 'What is the SI unit of electrical resistance?',
        difficulty: QuestionDifficulty.easy,
        addedOnText: '20 Jul 2026',
        options: const ['Ohm', 'Volt', 'Ampere', 'Watt'],
        correctOptionIndex: 0,
      ),
      QuestionBankItemModel(
        id: 'q2',
        questionText: 'Which wire color indicates earth connection?',
        difficulty: QuestionDifficulty.easy,
        addedOnText: '20 Jul 2026',
        options: const ['Green', 'Red', 'Black', 'Blue'],
        correctOptionIndex: 0,
      ),
      QuestionBankItemModel(
        id: 'q3',
        questionText: 'Explain the working of an MCB.',
        difficulty: QuestionDifficulty.medium,
        addedOnText: '18 Jul 2026',
        options: const [
          'Trips the circuit on overload',
          'Boosts voltage',
          'Stores charge',
          'Converts AC to DC',
        ],
        correctOptionIndex: 0,
      ),
    ];
  }

  /// Who has taken the faculty member's online tests, and how many
  /// questions they got right - the score itself is always computed
  /// from these two numbers, the way a real auto-graded MCQ test would.
  Future<List<TestSubmissionModel>> getTestSubmissions() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      TestSubmissionModel(
        studentName: 'Rahul Sharma',
        studentInitials: 'RS',
        testName: 'Unit Test 1',
        correctAnswers: 18,
        totalQuestions: 20,
      ),
      TestSubmissionModel(
        studentName: 'Suman Nishad',
        studentInitials: 'SN',
        testName: 'Unit Test 1',
        correctAnswers: 12,
        totalQuestions: 20,
      ),
      TestSubmissionModel(
        studentName: 'Deepak Singh',
        studentInitials: 'DS',
        testName: 'Unit Test 1',
        correctAnswers: 20,
        totalQuestions: 20,
      ),
      TestSubmissionModel(
        studentName: 'Karan Mehta',
        studentInitials: 'KM',
        testName: 'Unit Test 1',
        correctAnswers: 15,
        totalQuestions: 20,
      ),
    ];
  }
}
