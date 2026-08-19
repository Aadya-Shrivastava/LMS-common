/// Whether a certificate is ready to download yet.
enum CertificateStatus { available, notYetAvailable }

/// One certificate/document card on the Certificates screen.
class CertificateModel {
  final String title;

  /// e.g. "Issued on 15 Feb 2026", or an explanation of when it will
  /// become available if `status` is `notYetAvailable`.
  final String subtitle;

  final CertificateStatus status;
  final IconIdentifier icon;

  const CertificateModel({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
  });
}

/// Which icon/color treatment a certificate card uses. Kept as a
/// simple enum here (instead of importing `IconData` into the model
/// layer) so this file has no Flutter dependency.
enum IconIdentifier { marksheet, bonafide, completion }
