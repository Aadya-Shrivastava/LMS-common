import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/student_assignment_model.dart';

/// Loads the student's assignments (API 16) and their submissions
/// (API 17), and merges them into one list. Also uploads submissions.
class StudentAssignmentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<StudentAssignmentModel>> getAssignments() async {
    final results = await Future.wait([
      _apiClient.get(AppUrls.myAssignments),
      _apiClient.get(AppUrls.assignmentSubmissions),
    ]);

    // The student's submissions, by assignment id, so each assignment
    // can show when it was handed in.
    final submissions = {
      for (final submission in jsonList(results[1]))
        jsonString(submission['assignment']): submission,
    };

    return jsonList(results[0]).map((item) {
      final id = jsonString(item['id']);
      final submission = submissions[id];

      final dueDate = _dueDate(item) ?? DateTime.now();
      final maxMarks = jsonInt(item['max_marks']);

      final marks = item['marks_obtained'] ?? submission?['marks'];
      final statusText = jsonString(item['submission_status']).toLowerCase();

      final status = marks != null || statusText.contains('grad') || statusText.contains('evaluat')
          ? StudentAssignmentStatus.graded
          : statusText.contains('submit') || submission != null
              ? StudentAssignmentStatus.submitted
              : StudentAssignmentStatus.pending;

      final feedback = jsonString(item['feedback']).isNotEmpty
          ? jsonString(item['feedback'])
          : jsonString(submission?['feedback']);

      return StudentAssignmentModel(
        id: id,
        title: jsonString(item['title']),
        subject: jsonString(item['subject_name']),
        dueDate: dueDate,
        status: status,
        marksText: marks == null
            ? null
            : '${_marksNumber(marks)}${maxMarks > 0 ? '/$maxMarks' : ''}',
        maxMarks: maxMarks,
        description: jsonString(item['description']),
        fileUrl: jsonString(item['file']),
        facultyName: jsonString(item['created_by_name']),
        feedback: feedback,
        submittedAt: jsonDate(submission?['submitted_at']),
        submittedFileUrl: jsonString(item['submitted_file']).isNotEmpty
            ? jsonString(item['submitted_file'])
            : jsonString(submission?['file']),
      );
    }).toList()
      // Latest due date first, so the ones still open are on top.
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  }

  /// Hands in the student's file for one assignment (form-data with
  /// `assignment` and `file`).
  Future<void> submitAssignment({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    await _apiClient.postMultipart(
      AppUrls.assignmentSubmissions,
      fields: {'assignment': assignmentId},
      fileField: 'file',
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  /// Combines "due_date" (2026-10-25) and "due_time" (17:00:00).
  DateTime? _dueDate(Map<String, dynamic> item) {
    final date = jsonDate(item['due_date']);
    if (date == null) return jsonDate(item['due_at']);

    final timeParts = jsonString(item['due_time']).split(':');
    final hour = int.tryParse(timeParts.first) ?? 23;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 59 : 59;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// "18.0" -> "18", "17.5" -> "17.5".
  String _marksNumber(dynamic marks) {
    final value = jsonDouble(marks);
    return value == value.roundToDouble() ? value.round().toString() : value.toString();
  }
}
