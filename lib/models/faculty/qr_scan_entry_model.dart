/// One row in the QR attendance mode's "Live Scan Log".
class QrScanEntryModel {
  final String studentName;
  final String studentInitials;

  /// The time the student scanned the QR code, or "-" if they haven't.
  final String scannedAtText;

  final String status;

  const QrScanEntryModel({
    required this.studentName,
    required this.studentInitials,
    required this.scannedAtText,
    required this.status,
  });
}
