import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/network/saved_then_fresh.dart';
import 'package:lms/models/student/certificate_model.dart';
import 'package:lms/services/student/student_certificate_service.dart';

/// Holds the student's certificate requests, and sends new ones.
class StudentCertificateController extends GetxController {
  final StudentCertificateService _service = StudentCertificateService();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  bool hasLoaded = false;

  final RxList<CertificateModel> certificates = <CertificateModel>[].obs;

  /// True while a new request is being sent, so the button can show a
  /// spinner and can't be pressed twice.
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCertificates();
  }

  Future<void> loadCertificates() async {
    isLoading.value = true;
    errorMessage.value = null;

    errorMessage.value = await loadSavedThenFresh(_service.getCertificates, (data) {
      certificates.assignAll(data);
      hasLoaded = true;
      isLoading.value = false;
    });
    isLoading.value = false;
  }

  /// Sends a request for `title`, then reloads the list. Returns an
  /// error message, or null if it worked.
  Future<String?> requestCertificate(String title) async {
    isSubmitting.value = true;

    try {
      await _service.requestCertificate(title);
      await loadCertificates();
      return null;
    } catch (e) {
      return ApiClient.messageFor(e);
    } finally {
      isSubmitting.value = false;
    }
  }
}
