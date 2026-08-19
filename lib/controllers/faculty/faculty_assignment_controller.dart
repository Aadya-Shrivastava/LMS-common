import 'package:get/get.dart';
import 'package:lms/models/faculty/assignment_summary_model.dart';
import 'package:lms/models/faculty/question_bank_item_model.dart';
import 'package:lms/models/faculty/submission_model.dart';
import 'package:lms/models/faculty/test_submission_model.dart';
import 'package:lms/services/faculty/assignment_service.dart';
import 'package:lms/services/faculty/question_bank_service.dart';

/// Holds the data for the faculty Assignments and Question Bank &
/// Tests screens.
class FacultyAssignmentController extends GetxController {
  final AssignmentService _assignmentService = AssignmentService();
  final QuestionBankService _questionBankService = QuestionBankService();

  // ---- Assignments ----

  final RxBool isLoadingAssignments = true.obs;
  final RxList<AssignmentSummaryModel> assignments =
      <AssignmentSummaryModel>[].obs;

  /// The submissions for whichever assignment is currently being graded.
  final RxList<SubmissionModel> activeSubmissions = <SubmissionModel>[].obs;

  // ---- Question Bank & Tests ----

  final RxBool isLoadingQuestions = true.obs;
  final RxList<QuestionBankItemModel> questions =
      <QuestionBankItemModel>[].obs;

  final RxBool isLoadingTestSubmissions = true.obs;
  final RxList<TestSubmissionModel> testSubmissions = <TestSubmissionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAssignments();
    loadQuestions();
    loadTestSubmissions();
  }

  Future<void> loadAssignments() async {
    isLoadingAssignments.value = true;
    final results = await Future.wait([
      _assignmentService.getAssignmentSummaries(),
      _assignmentService.getSubmissionsForActiveAssignment(),
    ]);
    assignments.assignAll(results[0] as List<AssignmentSummaryModel>);
    activeSubmissions.assignAll(results[1] as List<SubmissionModel>);
    isLoadingAssignments.value = false;
  }

  /// The assignment currently shown in the Submissions tab. Used to
  /// check its due date, e.g. to know whether a missing student's row
  /// should say "Overdue".
  AssignmentSummaryModel? get activeAssignment {
    for (final assignment in assignments) {
      if (assignment.title == 'Wiring Diagram Submission') return assignment;
    }
    return null;
  }

  /// Adds a brand new assignment to the top of the list. There's no
  /// real backend yet, so "creating an assignment" just means adding
  /// it to our in-memory list.
  void addAssignment(AssignmentSummaryModel newAssignment) {
    assignments.insert(0, newAssignment);
  }

  /// Changes an assignment's due date - used when a faculty member
  /// opens their own assignment from "All Assignments" and edits it.
  void updateAssignmentDueDate(AssignmentSummaryModel assignment, DateTime newDueDate) {
    assignment.dueDate = newDueDate;
    assignments.refresh();
  }

  /// Saves the marks typed in for one submission. Since `marks` and
  /// `status` aren't `final` on `SubmissionModel`, we can update them
  /// directly and then call `.refresh()` to tell the UI to redraw.
  void saveMarksFor(SubmissionModel submission, String marks) {
    submission.marks = marks;
    submission.status = SubmissionStatus.graded;
    activeSubmissions.refresh();
  }

  /// `activeSubmissions` only has students who actually submitted
  /// something. This adds a "missing" entry for every other student in
  /// the batch, so the Submissions list shows the whole roster - not
  /// just the ones who turned something in.
  List<SubmissionModel> submissionsWithMissingFor(String batch) {
    final roster = _assignmentService.getBatchRoster(batch);
    final submittedNames = activeSubmissions.map((s) => s.studentName).toSet();

    final missingEntries = roster
        .where((name) => !submittedNames.contains(name))
        .map((name) => SubmissionModel(
              studentName: name,
              studentInitials: _initialsFor(name),
              submittedAtText: '-',
              fileName: '-',
              status: SubmissionStatus.missing,
            ));

    return [...activeSubmissions, ...missingEntries];
  }

  Future<void> loadQuestions() async {
    isLoadingQuestions.value = true;
    final items = await _questionBankService.getMyQuestions();
    questions.assignAll(items);
    isLoadingQuestions.value = false;
  }

  /// Adds a brand new question to the top of the question bank.
  void addQuestion(QuestionBankItemModel newQuestion) {
    questions.insert(0, newQuestion);
  }

  /// Saves edits made to an existing question - its text, options,
  /// correct answer, and/or difficulty.
  void updateQuestion(
    QuestionBankItemModel question, {
    required String questionText,
    required List<String> options,
    required int correctOptionIndex,
    required QuestionDifficulty difficulty,
  }) {
    question.questionText = questionText;
    question.options = options;
    question.correctOptionIndex = correctOptionIndex;
    question.difficulty = difficulty;
    questions.refresh();
  }

  Future<void> loadTestSubmissions() async {
    isLoadingTestSubmissions.value = true;
    final results = await _questionBankService.getTestSubmissions();
    testSubmissions.assignAll(results);
    isLoadingTestSubmissions.value = false;
  }
}

/// Turns a name like "Karan Mehta" into initials like "KM".
String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length < 2) return name.substring(0, 2).toUpperCase();
  return (words.first[0] + words[1][0]).toUpperCase();
}
