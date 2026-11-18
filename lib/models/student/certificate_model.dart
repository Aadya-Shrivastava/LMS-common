/// Where a certificate request is.
enum CertificateStatus { available, notYetAvailable, rejected }

/// One certificate request on the Certificates screen (API 33).
class CertificateModel {
  final String id;

  /// e.g. "Bonafide", "Character Certificate".
  final String title;

  /// e.g. "Issued on 17 Oct 2026 · CHR/2026/0001", or "Requested on
  /// 21 Oct 2026" while it's still pending.
  final String subtitle;

  final CertificateStatus status;
  final IconIdentifier icon;

  /// The student's reason, or the office's note. Can be empty.
  final String remarks;

  /// The details printed on the issued certificate (name, roll no,
  /// trade, ...), as label -> value. Empty until it's issued.
  final Map<String, String> issuedDetails;

  // ---- Printed on the certificate document ----

  /// The type as the server names it, e.g. "Bonafide", "Character
  /// Certificate", "Course Completion".
  final String certificateType;

  /// e.g. "CHR/2026/0001". Can be empty.
  final String certificateNo;
  final DateTime? issuedDate;

  /// The server's `issued_data` with its own keys (name, father, roll,
  /// trade, dob, pob, gender, conduct, session, ...).
  final Map<String, String> issuedData;

  const CertificateModel({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    this.id = '',
    this.remarks = '',
    this.issuedDetails = const {},
    this.certificateType = '',
    this.certificateNo = '',
    this.issuedDate,
    this.issuedData = const {},
  });
}

/// Which icon/color treatment a certificate card uses. Kept as a
/// simple enum here (instead of importing `IconData` into the model
/// layer) so this file has no Flutter dependency.
enum IconIdentifier { marksheet, bonafide, completion }
