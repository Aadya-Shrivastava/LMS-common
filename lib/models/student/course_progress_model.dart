/// How far a student has gotten through one course - shown as a
/// progress bar in the "Course Progress" section of the dashboard.
class CourseProgressModel {
  final String courseName;

  /// A number from 0 to 100.
  final double percentComplete;

  const CourseProgressModel({
    required this.courseName,
    required this.percentComplete,
  });
}
