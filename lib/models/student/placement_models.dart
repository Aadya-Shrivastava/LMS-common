/// One company placement drive (API 36), e.g. "CISCO, 25 positions,
/// 7 To 8.99 LPA".
class PlacementDriveModel {
  final String id;
  final String companyName;
  final DateTime? date;
  final int positions;

  /// e.g. "Upcoming".
  final String status;

  final String eligibility;

  /// e.g. "7 To 8.99(LPA)". Can be empty.
  final String packageText;

  /// The job role. Can be empty.
  final String role;

  /// Courses and branches that can apply, e.g. ["COURSE ITI"].
  final List<String> courses;
  final List<String> branches;

  /// A link to the drive's details PDF. Can be empty.
  final String pdfUrl;

  const PlacementDriveModel({
    required this.id,
    required this.companyName,
    required this.date,
    required this.positions,
    required this.status,
    required this.eligibility,
    required this.packageText,
    required this.role,
    required this.courses,
    required this.branches,
    required this.pdfUrl,
  });
}

/// One drive the student applied to (API 37).
class PlacementApplicationModel {
  final String id;

  /// The drive this application is for - matches `PlacementDriveModel.id`.
  final String driveId;
  final String companyName;

  /// e.g. "applied", "shortlisted", "selected".
  final String status;
  final DateTime? appliedAt;

  /// A link to the resume sent with the application. Can be empty.
  final String resumeUrl;

  const PlacementApplicationModel({
    required this.id,
    required this.driveId,
    required this.companyName,
    required this.status,
    required this.appliedAt,
    required this.resumeUrl,
  });
}

/// One placed student (API 39).
class PlacedStudentModel {
  final String studentName;
  final String companyName;

  /// Salary package in lakhs per year, e.g. "25.00".
  final String packageLpa;
  final DateTime? date;

  /// True if this is the logged-in student.
  final bool isMe;

  const PlacedStudentModel({
    required this.studentName,
    required this.companyName,
    required this.packageLpa,
    required this.date,
    required this.isMe,
  });
}
