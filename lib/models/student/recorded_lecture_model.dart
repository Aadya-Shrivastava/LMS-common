/// One recorded lecture in the "Recorded Lecture Library" on the Live
/// Classes screen, e.g. "Wiring Basics - Session 4, 42 min, Er. R. Kumar".
class RecordedLectureModel {
  final String tag;
  final String title;
  final String durationText;
  final String facultyName;

  /// Link to the recording. Can be empty.
  final String recordingUrl;

  const RecordedLectureModel({
    required this.tag,
    required this.title,
    required this.durationText,
    required this.facultyName,
    this.recordingUrl = '',
  });
}
