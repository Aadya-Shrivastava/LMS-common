import 'package:get/get.dart';
import 'package:lms/models/student/certificate_model.dart';
import 'package:lms/services/student/student_certificate_service.dart';

/// Holds the student's certificates and other issued documents.
class StudentCertificateController extends GetxController {
  final StudentCertificateService _service = StudentCertificateService();

  final RxBool isLoading = true.obs;
  final RxList<CertificateModel> certificates = <CertificateModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCertificates();
  }

  Future<void> loadCertificates() async {
    isLoading.value = true;
    final items = await _service.getCertificates();
    certificates.assignAll(items);
    isLoading.value = false;
  }
}
