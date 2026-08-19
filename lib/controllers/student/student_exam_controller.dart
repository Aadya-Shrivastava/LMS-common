import 'package:get/get.dart';
import 'package:lms/models/student/exam_model.dart';
import 'package:lms/models/student/exam_result_model.dart';
import 'package:lms/services/student/student_exam_service.dart';

/// Holds the student's upcoming exams and past result history, shown
/// on the Exams & Results screen.
class StudentExamController extends GetxController {
  final StudentExamService _service = StudentExamService();

  final RxBool isLoading = true.obs;
  final RxList<ExamModel> upcomingExams = <ExamModel>[].obs;
  final RxList<ExamResultModel> resultHistory = <ExamResultModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadExamsAndResults();
  }

  Future<void> loadExamsAndResults() async {
    isLoading.value = true;

    final results = await Future.wait([
      _service.getUpcomingExams(),
      _service.getResultHistory(),
    ]);

    upcomingExams.assignAll(results[0] as List<ExamModel>);
    resultHistory.assignAll(results[1] as List<ExamResultModel>);

    isLoading.value = false;
  }
}
