import 'package:lms/models/student/certificate_model.dart';

/// Provides the student's certificates and other issued documents.
class StudentCertificateService {
  Future<List<CertificateModel>> getCertificates() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      CertificateModel(
        title: 'Semester 1 Marksheet',
        subtitle: 'Issued on 15 Feb 2026',
        status: CertificateStatus.available,
        icon: IconIdentifier.marksheet,
      ),
      CertificateModel(
        title: 'Bonafide Certificate',
        subtitle: 'Issued on 10 Jun 2026',
        status: CertificateStatus.available,
        icon: IconIdentifier.bonafide,
      ),
      CertificateModel(
        title: 'Course Completion Certificate',
        subtitle: 'Available after final semester',
        status: CertificateStatus.notYetAvailable,
        icon: IconIdentifier.completion,
      ),
    ];
  }
}
