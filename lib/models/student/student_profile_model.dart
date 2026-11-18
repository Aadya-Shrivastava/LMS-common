/// The student's full profile - personal and academic details shown
/// on the Account Settings screen.
class StudentProfileModel {
  final String fullName;

  /// "Registration No.", e.g. "REG-010202" (profile, ID card, receipts).
  final String registrationNo;

  /// "Roll No.", e.g. "982837".
  final String rollNo;
  final String fatherName;
  final String guardianName;
  final String guardianMobile;
  final String dateOfBirthText;
  final String gender;
  final String bloodGroup;
  final String mobileNumber;
  final String email;
  final String address;

  final String course;
  final String branch;
  final String batch;
  final String semester;
  final String session;
  final String studyMode;
  final String admissionDateText;

  /// Links to files on the server. Can be empty.
  final String photoUrl;
  final String idProofUrl;
  final String marksheetUrl;

  /// e.g. "MAA Gulijari Bharat Private ITI, Kanso MAU" - the ID card's
  /// header. Can be empty.
  final String campusName;

  /// For the ID card, which prints it as "09-09-2002". Null if unknown.
  final DateTime? dateOfBirth;

  const StudentProfileModel({
    required this.fullName,
    required this.fatherName,
    required this.dateOfBirthText,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.course,
    required this.batch,
    required this.semester,
    required this.admissionDateText,
    this.registrationNo = '—',
    this.rollNo = '—',
    this.guardianName = '—',
    this.guardianMobile = '—',
    this.gender = '—',
    this.bloodGroup = '—',
    this.branch = '—',
    this.session = '—',
    this.studyMode = '—',
    this.photoUrl = '',
    this.idProofUrl = '',
    this.marksheetUrl = '',
    this.campusName = '',
    this.dateOfBirth,
  });
}
