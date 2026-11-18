/// The kind of file a study material is - decides the badge and
/// whether the action button says "Download", "Watch", "Open" or "Read".
enum StudentMaterialType { pdf, video, document, image, presentation, text, link }

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

  /// e.g. "Chapter 4". Can be empty.
  final String chapter;

  /// The file or video link to open. Can be empty.
  final String url;

  /// The lesson text, for text lessons (API 11) and lessons that come
  /// with notes. Can be empty.
  final String textContent;

  const StudentStudyMaterialModel({
    this.chapter = '',
    this.url = '',
    this.textContent = '',
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.uploadedByFacultyName,
    required this.dateText,
  });
}
