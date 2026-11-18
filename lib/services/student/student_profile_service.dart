import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/student_profile_model.dart';

/// Loads the student's personal and academic profile from
/// `AppUrls.studentProfile` (API 5), and saves contact details (API 6).
class StudentProfileService {
  final ApiClient _apiClient = ApiClient();

  /// Saves the editable contact details. Returns the server's message.
  Future<String> updateContactDetails({
    required String mobile,
    required String guardianMobile,
    required String address,
  }) async {
    final data = await _apiClient.post(
      AppUrls.updateProfile,
      body: {
        'mobile': mobile,
        'guardian_mobile': guardianMobile,
        'address': address,
      },
    );
    final message = jsonMap(data)['message'];
    return message is String && message.isNotEmpty ? message : 'Profile updated successfully';
  }

  // The student's numbers are `registration_no` ("REG-010202") and
  // `roll_no` ("982837") only. `enrollment_no` is not used anywhere in
  // the app, and none of these read-only numbers is ever sent back.
  Future<StudentProfileModel> getProfile() async {
    final json = jsonMap(await _apiClient.get(AppUrls.studentProfile));

    // Show a dash instead of a blank row when a field isn't filled in.
    String text(String key) {
      final value = jsonString(json[key]);
      return value.isEmpty ? '—' : value;
    }

    String date(String key) {
      final value = jsonDate(json[key]);
      return value == null ? '—' : formatDate(value);
    }

    final fullName = '${jsonString(json['first_name'])} ${jsonString(json['last_name'])}'.trim();

    return StudentProfileModel(
      fullName: fullName.isEmpty ? '—' : fullName,
      registrationNo: text('registration_no'),
      rollNo: text('roll_no'),
      fatherName: text('father_name'),
      guardianName: text('guardian_name'),
      guardianMobile: text('guardian_mobile'),
      dateOfBirthText: date('dob'),
      gender: text('gender_name'),
      bloodGroup: text('blood_group_name'),
      mobileNumber: text('mobile'),
      email: text('email'),
      address: text('address'),
      course: text('course'),
      branch: text('branch'),
      batch: text('batch'),
      semester: text('semester'),
      session: text('session_name'),
      studyMode: text('study_mode_name'),
      admissionDateText: date('admission_date'),
      photoUrl: jsonString(json['photo']),
      idProofUrl: jsonString(json['id_proof']),
      marksheetUrl: jsonString(json['marksheet']),
      campusName: jsonString(json['campus_name']),
      dateOfBirth: jsonDate(json['dob']),
    );
  }
}
