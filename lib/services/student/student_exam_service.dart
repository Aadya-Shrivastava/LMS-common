import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/exam_model.dart';
import 'package:lms/models/student/exam_result_model.dart';

/// Loads the student's exams (APIs 18 and 19), result history (API
/// 22), attempt details with answers (APIs 20 and 21) and the grading
/// scale (API 23).
class StudentExamService {
  final ApiClient _apiClient = ApiClient();

  /// Only the exams still to come, soonest first (API 19).
  Future<List<ExamModel>> getUpcomingExams() async {
    final exams = jsonList(await _apiClient.get(AppUrls.upcomingExams)).map(_exam).toList();
    exams.sort(_bySoonest);
    return exams;
  }

  /// Every exam for the student's batch, newest first (API 18).
  Future<List<ExamModel>> getAllExams() async {
    final exams = jsonList(await _apiClient.get(AppUrls.exams)).map(_exam).toList();
    exams.sort((a, b) => _bySoonest(b, a));
    return exams;
  }

  /// Finished exams with score and status, most recent first (API 22).
  Future<List<ExamResultModel>> getResultHistory() async {
    final results = jsonList(await _apiClient.get(AppUrls.examHistory))
        .map((item) => ExamResultModel(
              id: jsonString(item['id']),
              examTitle: jsonString(item['exam_title']),
              subject: jsonString(item['subject_name']),
              scoreText: _number(item['score']),
              statusText: jsonString(item['status']),
              submittedAt: jsonDate(item['submitted_at']),
            ))
        .toList();

    results.sort((a, b) => (b.submittedAt ?? DateTime(0)).compareTo(a.submittedAt ?? DateTime(0)));
    return results;
  }

  /// Every attempt with its answers, by attempt id (APIs 20 and 21).
  Future<Map<String, ExamAttemptModel>> getAttempts() async {
    final results = await Future.wait([
      _apiClient.get(AppUrls.examAttempts),
      _apiClient.get(AppUrls.examAnswers),
    ]);

    // Answers from API 21, grouped by attempt. Used when an attempt
    // from API 20 doesn't already include its answers.
    final answersByAttempt = <String, List<ExamAnswerModel>>{};
    for (final answer in jsonList(results[1]).map(_answer)) {
      answersByAttempt.putIfAbsent(answer.attemptId, () => []).add(answer);
    }

    return {
      for (final item in jsonList(results[0]))
        jsonString(item['id']): () {
          final id = jsonString(item['id']);
          final ownAnswers = jsonList(item['answers']).map(_answer).toList();

          return ExamAttemptModel(
            id: id,
            examTitle: jsonString(item['exam_title']),
            startedAt: jsonDate(item['started_at']),
            submittedAt: jsonDate(item['submitted_at']),
            scoreText: _number(item['score']),
            evaluated: item['evaluated'] == true,
            tabSwitches: jsonInt(item['tab_switches']),
            autoSubmitted: item['auto_submitted'] == true,
            answers: ownAnswers.isNotEmpty ? ownAnswers : answersByAttempt[id] ?? const [],
          );
        }(),
    };
  }

  /// The campus grading scale, best grade first (API 23). Bands the
  /// office switched off are left out.
  Future<List<GradeBandModel>> getGradingScale() async {
    final bands = jsonList(await _apiClient.get(AppUrls.examGrades))
        .where((item) => item['is_active'] != false)
        .map((item) => GradeBandModel(
              grade: jsonString(item['grade']),
              fromPercent: jsonDouble(item['from_percent']),
              toPercent: jsonDouble(item['to_percent']),
              gradePoint: jsonDouble(item['grade_point']),
              remarks: jsonString(item['remarks']),
            ))
        .toList();

    bands.sort((a, b) => b.fromPercent.compareTo(a.fromPercent));
    return bands;
  }

  ExamModel _exam(Map<String, dynamic> item) {
    return ExamModel(
      id: jsonString(item['id']),
      title: jsonString(item['title']),
      subject: jsonString(item['subject_name']),
      chapter: jsonString(item['chapter_name']),
      startTime: jsonDate(item['start_time']),
      durationMinutes: jsonInt(item['duration_minutes']),
      // API 18 has both; "num_questions_to_ask" is what the student sees.
      questionCount: jsonInt(item['num_questions_to_ask'] ?? item['question_count']),
      typeName: jsonString(item['exam_type_name']),
    );
  }

  ExamAnswerModel _answer(Map<String, dynamic> item) {
    return ExamAnswerModel(
      attemptId: jsonString(item['attempt']),
      questionId: jsonString(item['question']),
      selectedChoiceId: jsonString(item['selected_choice']),
      subjectiveAnswer: jsonString(item['subjective_answer']),
    );
  }

  int _bySoonest(ExamModel a, ExamModel b) {
    return (a.startTime ?? DateTime(9999)).compareTo(b.startTime ?? DateTime(9999));
  }

  /// "1" -> "1", "17.5" -> "17.5", null -> "—".
  String _number(dynamic value) {
    if (value == null) return '—';
    final number = jsonDouble(value);
    return number == number.roundToDouble() ? number.round().toString() : number.toString();
  }
}
