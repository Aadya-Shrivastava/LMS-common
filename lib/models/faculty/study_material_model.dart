/// The kind of file a study material upload is.
///
/// Named `StudyMaterialType` (not just `MaterialType`) because Flutter
/// itself already has a widget-related enum called `MaterialType`, and
/// we don't want the two to clash.
enum StudyMaterialType { pdf, video, document }

/// One file a faculty member has shared with students.
class StudyMaterialModel {
  final String id;
  final String title;
  final String subject;
  final StudyMaterialType type;
  final String batch;

  /// Shown as text, e.g. "29 Jul 2026".
  final String uploadedOnText;

  const StudyMaterialModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.batch,
    required this.uploadedOnText,
  });
}
