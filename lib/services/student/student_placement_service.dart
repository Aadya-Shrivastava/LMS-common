import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/placement_models.dart';
import 'package:lms/services/student/student_record_service.dart';

/// Loads placement drives (API 36), the student's applications (API
/// 37), placed students (API 39), and applies to a drive (API 38).
class StudentPlacementService {
  final ApiClient _apiClient = ApiClient();
  final StudentRecordService _recordService = StudentRecordService();

  /// Soonest drive first.
  Future<List<PlacementDriveModel>> getDrives() async {
    final drives = jsonList(await _apiClient.get(AppUrls.placementDrives))
        .map((item) => PlacementDriveModel(
              id: jsonString(item['id']),
              companyName: jsonString(item['company_name']),
              date: jsonDate(item['date']),
              positions: jsonInt(item['positions']),
              status: jsonString(item['status']),
              eligibility: jsonString(item['eligibility_criteria']),
              packageText: jsonString(item['package_lpa']),
              role: jsonString(item['role']),
              courses: _texts(item['courses_info']),
              branches: _texts(item['branches_info']),
              pdfUrl: jsonString(item['pdf_docs']),
            ))
        .toList();

    drives.sort((a, b) => (a.date ?? DateTime(9999)).compareTo(b.date ?? DateTime(9999)));
    return drives;
  }

  /// Newest application first.
  Future<List<PlacementApplicationModel>> getApplications() async {
    final applications = jsonList(await _apiClient.get(AppUrls.placementApplications)).map((item) {
      final job = jsonMap(item['job_details']);
      return PlacementApplicationModel(
        id: jsonString(item['id']),
        // The live API calls it "job"; the API document calls it "drive".
        driveId: jsonString(item['job'] ?? item['drive'] ?? job['id']),
        companyName: jsonString(job['company_name']),
        status: jsonString(item['status']),
        appliedAt: jsonDate(item['applied_at']),
        resumeUrl: jsonString(item['resume_url'] ?? item['resume']),
      );
    }).toList();

    applications.sort((a, b) => (b.appliedAt ?? DateTime(0)).compareTo(a.appliedAt ?? DateTime(0)));
    return applications;
  }

  /// Applies to a drive (API 38). Returns the server's own success
  /// message if it sent one (e.g. "Applied successfully."), else null.
  Future<String?> apply(String driveId) async {
    final data = await _apiClient.post(
      AppUrls.placementApplications,
      body: {'job': int.tryParse(driveId) ?? driveId},
    );
    return ApiClient.successMessage(data);
  }

  /// The logged-in student's own placements, newest first. API 39
  /// returns every placed student on the campus, so the others are
  /// filtered out here; a student only ever sees themselves.
  Future<List<PlacedStudentModel>> getPlacedStudents() async {
    final results = await Future.wait([
      _apiClient.get(AppUrls.placedStudents),
      _recordService.getStudentId(),
    ]);
    final myId = results[1] as String;

    final placed = jsonList(results[0])
        .where((item) => jsonString(item['student']) == myId)
        .map((item) => PlacedStudentModel(
              studentName: jsonString(item['student_name']),
              companyName: jsonString(item['company_name']),
              packageLpa: jsonString(item['package']),
              date: jsonDate(item['date']),
              isMe: true, // Only the student's own placements are kept.
            ))
        .toList();

    placed.sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    return placed;
  }

  List<String> _texts(dynamic value) {
    if (value is! List) return const [];
    return value.map(jsonString).where((text) => text.isNotEmpty).toList();
  }
}
