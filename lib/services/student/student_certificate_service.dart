import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/certificate_model.dart';
import 'package:lms/services/student/student_record_service.dart';

/// Loads the student's certificate requests (API 33), asks for a new
/// certificate (API 32), and creates/downloads issued certificates
/// (APIs 34 and 35).
class StudentCertificateService {
  final ApiClient _apiClient = ApiClient();
  final StudentRecordService _recordService = StudentRecordService();

  /// Newest request first.
  Future<List<CertificateModel>> getCertificates() async {
    final items = jsonList(await _apiClient.get(AppUrls.certificateRequests));

    final certificates = <(DateTime?, CertificateModel)>[];
    for (final item in items) {
      final type = jsonString(item['certificate_type']);
      final statusText = jsonString(item['status']).toLowerCase();
      final requestDate = jsonDate(item['request_date']);
      final issuedDate = jsonDate(item['issued_date']);
      final certificateNo = jsonString(item['certificate_no']);

      final status = statusText == 'issued' || statusText == 'approved'
          ? CertificateStatus.available
          : statusText == 'rejected'
              ? CertificateStatus.rejected
              : CertificateStatus.notYetAvailable;

      final subtitle = switch (status) {
        CertificateStatus.available => [
            issuedDate == null ? 'Issued' : 'Issued on ${formatDate(issuedDate)}',
            if (certificateNo.isNotEmpty) certificateNo,
          ].join(' · '),
        CertificateStatus.rejected => 'Request rejected',
        CertificateStatus.notYetAvailable =>
          requestDate == null ? 'Requested' : 'Requested on ${formatDate(requestDate)}',
      };

      certificates.add((
        requestDate,
        CertificateModel(
          id: jsonString(item['id']),
          title: type.isEmpty ? 'Certificate' : type,
          subtitle: subtitle,
          status: status,
          icon: _iconFor(type),
          remarks: jsonString(item['remarks']),
          issuedDetails: {
            for (final entry in jsonMap(item['issued_data']).entries)
              if (jsonString(entry.value).isNotEmpty) _label(entry.key): jsonString(entry.value),
          },
          certificateType: type,
          certificateNo: certificateNo,
          issuedDate: issuedDate,
          issuedData: {
            for (final entry in jsonMap(item['issued_data']).entries)
              entry.key: jsonString(entry.value),
          },
        ),
      ));
    }

    certificates.sort((a, b) => (b.$1 ?? DateTime(0)).compareTo(a.$1 ?? DateTime(0)));
    return [for (final certificate in certificates) certificate.$2];
  }

  /// Asks for a new certificate (API 32). The server fills in the
  /// student, course and campus and the request starts as "Pending".
  ///
  /// The server's own values are like "Bonafide" and "Course
  /// Completion", so "Bonafide Certificate" is sent as "Bonafide".
  Future<void> requestCertificate(String title) async {
    final type = title.replaceFirst(RegExp(r'\s+Certificate$', caseSensitive: false), '');
    await _apiClient.post(
      AppUrls.certificateRequests,
      body: {'certificate_type': type},
    );
  }

  /// Creates an issued-certificate record for the logged-in student
  /// (API 34) and returns its id, which `downloadIssuedCertificate`
  /// needs.
  Future<String> createIssuedCertificate(String title) async {
    final studentId = await _recordService.getStudentId();
    final data = await _apiClient.post(
      AppUrls.issuedCertificates,
      body: {'title': title, 'student': studentId},
    );
    return jsonString(jsonMap(data)['id']);
  }

  /// The rendered certificate document for an issued-certificate id
  /// (API 35). It's not JSON: show or save the bytes as they are,
  /// using `contentType` (e.g. "text/html" or "application/pdf").
  Future<({List<int> bytes, String contentType})> downloadIssuedCertificate(String id) {
    return _apiClient.getDocument(AppUrls.downloadIssuedCertificate(id));
  }

  IconIdentifier _iconFor(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('bonafide') || lower.contains('character')) return IconIdentifier.bonafide;
    if (lower.contains('mark')) return IconIdentifier.marksheet;
    return IconIdentifier.completion;
  }

  /// "issueDate" -> "Issue Date", "dob" -> "Date of Birth".
  String _label(String key) {
    const known = {
      'dob': 'Date of Birth',
      'pob': 'Place of Birth',
      'refNo': 'Ref. No.',
      'roll': 'Roll No.',
    };
    if (known.containsKey(key)) return known[key]!;

    final words = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    return words.isEmpty ? key : words[0].toUpperCase() + words.substring(1);
  }
}
