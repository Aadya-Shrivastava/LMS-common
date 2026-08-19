/// The student's full profile - personal and academic details shown
/// on the Account Settings screen.
class StudentProfileModel {
  final String fullName;
  final String enrollmentNo;
  final String fatherName;
  final String dateOfBirthText;
  final String mobileNumber;
  final String email;
  final String address;

  final String course;
  final String batch;
  final String semester;
  final String admissionDateText;

  const StudentProfileModel({
    required this.fullName,
    required this.enrollmentNo,
    required this.fatherName,
    required this.dateOfBirthText,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.course,
    required this.batch,
    required this.semester,
    required this.admissionDateText,
  });
}
