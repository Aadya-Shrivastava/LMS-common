/// The student's full record from API 4 - mainly the student `id`
/// (other APIs need it), plus a few summary numbers shown on the
/// profile screen.
class StudentRecordModel {
  /// The student's id (a UUID), e.g. used in the fee summary URL.
  final String id;

  final String fullName;
  final String branch;
  final String session;

  /// e.g. "75%".
  final String attendanceText;

  /// e.g. "No Dues".
  final String feeStatus;

  /// e.g. "1/6".
  final String assignmentsDoneText;

  /// e.g. "A".
  final String overallGrade;

  /// e.g. "SELECTED".
  final String placementStatus;

  /// Documents the office is still waiting on, e.g. "Income certificate".
  final List<String> documentsPending;

  /// e.g. "Mgbi" - printed at the top of fee receipts. Can be empty.
  final String instituteName;

  /// e.g. "MAA Gulijari Bharat Private ITI, Kanso MAU". Can be empty.
  final String campusName;

  const StudentRecordModel({
    this.instituteName = '',
    this.campusName = '',
    required this.id,
    required this.fullName,
    required this.branch,
    required this.session,
    required this.attendanceText,
    required this.feeStatus,
    required this.assignmentsDoneText,
    required this.overallGrade,
    required this.placementStatus,
    required this.documentsPending,
  });
}

/// One device the student is logged in on (API 43), e.g. "Linux -
/// Chrome, expires 22 Oct 2026".
class ActiveSessionModel {
  final String deviceName;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const ActiveSessionModel({
    required this.deviceName,
    required this.createdAt,
    required this.expiresAt,
  });
}
