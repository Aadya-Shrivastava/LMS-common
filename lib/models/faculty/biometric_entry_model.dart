/// One row in the biometric attendance mode's sync log.
class BiometricEntryModel {
  final String studentName;

  /// The time the biometric device recorded a punch, or "-" if none.
  final String punchTimeText;

  final String matchStatus;
  final String attendanceStatus;

  const BiometricEntryModel({
    required this.studentName,
    required this.punchTimeText,
    required this.matchStatus,
    required this.attendanceStatus,
  });
}
