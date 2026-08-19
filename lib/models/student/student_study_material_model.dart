/// The kind of file a study material is - decides whether the action
/// button says "Download" or "Watch".
enum StudentMaterialType { pdf, video, document }

/// One file a faculty member has shared, shown on the student's Study
/// Materials screen.
class StudentStudyMaterialModel {
  final String id;
  final String title;
  final String subject;
  final StudentMaterialType type;
  final String uploadedByFacultyName;

  /// Shown as text, e.g. "29 Jul 2026".
  final String dateText;

  const StudentStudyMaterialModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.uploadedByFacultyName,
    required this.dateText,
  });
}
