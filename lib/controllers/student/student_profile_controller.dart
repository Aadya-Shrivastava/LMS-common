import 'package:get/get.dart';
import 'package:lms/models/student/student_profile_model.dart';
import 'package:lms/services/student/student_profile_service.dart';

/// Holds the student's profile data for the Account Settings screen.
class StudentProfileController extends GetxController {
  final StudentProfileService _service = StudentProfileService();

  final RxBool isLoading = true.obs;
  final Rx<StudentProfileModel?> profile = Rx<StudentProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    profile.value = await _service.getProfile();
    isLoading.value = false;
  }
}
