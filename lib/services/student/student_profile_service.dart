import 'package:lms/models/student/student_profile_model.dart';

/// Provides the student's personal and academic profile details.
class StudentProfileService {
  Future<StudentProfileModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const StudentProfileModel(
      fullName: 'Rahul Sharma',
      enrollmentNo: 'ENR-2026-0451',
      fatherName: 'Suresh Sharma',
      dateOfBirthText: '12 Apr 2007',
      mobileNumber: '+91 98xxxxxx21',
      email: 'rahul.sharma@example.com',
      address: 'Village Kanso, Mau, Uttar Pradesh',
      course: 'Electrician',
      batch: 'Batch A',
      semester: 'Semester 2',
      admissionDateText: '28 Jul 2025',
    );
  }
}
