import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/student_record_model.dart';

/// Loads the student's record (API 4) and remembers their student id,
/// which other APIs (fee summary, certificates) need in their request.
class StudentRecordService {
  final ApiClient _apiClient = ApiClient();

  /// Kept for the whole app session so we only ask the server once.
  /// Cleared on logout by `clearCache`.
  static String? _cachedStudentId;
  static StudentRecordModel? _cachedRecord;

  /// The student record. Asks the server once per session; pass
  /// `fresh: true` to reload it (e.g. on pull-to-refresh).
  Future<StudentRecordModel> getRecord({bool fresh = false}) async {
    final cached = _cachedRecord;
    if (!fresh && cached != null) return cached;

    // The API returns a list with just the logged-in student in it.
    final items = jsonList(await _apiClient.get(AppUrls.studentRecord));
    if (items.isEmpty) {
      throw const ApiException('Your student record was not found.');
    }

    final json = items.first;
    final record = StudentRecordModel(
      id: jsonString(json['id']),
      fullName: jsonString(json['full_name']),
      branch: jsonString(json['branch_name']),
      session: jsonString(json['session_name']),
      attendanceText: jsonString(json['attendance_percentage']),
      feeStatus: jsonString(json['fee_status']),
      assignmentsDoneText: jsonString(json['assignments_done']),
      overallGrade: jsonString(json['overall_grade']),
      placementStatus: jsonString(json['placement_status']),
      instituteName: jsonString(json['institute_name']),
      campusName: jsonString(json['campus_name']),
      documentsPending: [
        for (final doc in (json['documents_pending'] is List ? json['documents_pending'] as List : const []))
          jsonString(doc),
      ],
    );

    _cachedStudentId = record.id;
    _cachedRecord = record;
    return record;
  }

  /// The logged-in student's id, loading the record first if needed.
  Future<String> getStudentId() async {
    final cached = _cachedStudentId;
    if (cached != null && cached.isNotEmpty) return cached;
    return (await getRecord()).id;
  }

  /// Forgets the saved student record, so the next student to log in on
  /// this phone doesn't get the previous one's.
  static void clearCache() {
    _cachedStudentId = null;
    _cachedRecord = null;
  }

  /// Devices the student is logged in on (API 43), newest first.
  Future<List<ActiveSessionModel>> getActiveSessions() async {
    final items = jsonList(await _apiClient.get(AppUrls.activeSessions));

    final sessions = items
        .map((item) => ActiveSessionModel(
              deviceName: jsonString(item['device_name']),
              createdAt: jsonDate(item['created_at']),
              expiresAt: jsonDate(item['expires_at']),
            ))
        .toList();

    sessions.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return sessions;
  }
}
