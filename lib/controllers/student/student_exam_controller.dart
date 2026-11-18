import 'package:get/get.dart';
import '../../core/network/saved_then_fresh.dart';
import 'package:lms/models/student/exam_model.dart';
import 'package:lms/models/student/exam_result_model.dart';
import 'package:lms/services/student/student_exam_service.dart';

/// Holds the student's exams, result history and attempt details,
/// shown on the Exams & Results screen.
class StudentExamController extends GetxController {
  final StudentExamService _service = StudentExamService();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  bool hasLoaded = false;

  final RxList<ExamModel> upcomingExams = <ExamModel>[].obs;
  final RxList<ExamModel> allExams = <ExamModel>[].obs;
  final RxList<ExamResultModel> resultHistory = <ExamResultModel>[].obs;

  /// Attempt details by attempt id, for when a result is tapped.
  final RxMap<String, ExamAttemptModel> attempts = <String, ExamAttemptModel>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadExamsAndResults();
  }

  Future<void> loadExamsAndResults() async {
    isLoading.value = true;
    errorMessage.value = null;

    // The grading scale is an extra: it loads alongside, and if it
    // fails the card just hides.
    final gradingScaleDone = loadSavedThenFresh(
      _service.getGradingScale,
      gradingScale.assignAll,
    );

    errorMessage.value = await loadSavedThenFresh(
      () => Future.wait([
        _service.getUpcomingExams(),
        _service.getAllExams(),
        _service.getResultHistory(),
        _service.getAttempts(),
      ]),
      (results) {
        upcomingExams.assignAll(results[0] as List<ExamModel>);
        allExams.assignAll(results[1] as List<ExamModel>);
        resultHistory.assignAll(results[2] as List<ExamResultModel>);
        attempts.assignAll(results[3] as Map<String, ExamAttemptModel>);
        hasLoaded = true;
        isLoading.value = false;
      },
    );
    isLoading.value = false;
    await gradingScaleDone;
  }

  /// The campus grading scale (API 23), best grade first.
  final RxList<GradeBandModel> gradingScale = <GradeBandModel>[].obs;

  /// The attempt behind a result in the history list. The history id
  /// is the attempt id; falls back to matching by exam title.
  ExamAttemptModel? attemptFor(ExamResultModel result) {
    final byId = attempts[result.id];
    if (byId != null) return byId;

    for (final attempt in attempts.values) {
      if (attempt.examTitle == result.examTitle) return attempt;
    }
    return null;
  }
}
