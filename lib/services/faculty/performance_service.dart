import 'package:lms/models/faculty/assignment_model.dart';
import 'package:lms/models/faculty/student_assignment_record_model.dart';
import 'package:lms/models/faculty/student_performance_model.dart';

/// Provides the performance overview (attendance, assignments, marks,
/// grade) for the students in a faculty member's batch.
class PerformanceService {
  /// Returns the performance rows for one batch, e.g. "Batch A".
  Future<List<StudentPerformanceModel>> getBatchPerformance(String batch) async {
    await Future.delayed(const Duration(milliseconds: 400));

    switch (batch) {
      case 'Batch B':
        return [
          StudentPerformanceModel(
            studentName: 'Anjali Verma',
            studentInitials: 'AV',
            attendancePercent: 90,
            assignmentsCompletedText: '7/8',
            internalMarks: '36/40',
            grade: 'A',
          ),
          StudentPerformanceModel(
            studentName: 'Mohit Rana',
            studentInitials: 'MR',
            attendancePercent: 68,
            assignmentsCompletedText: '4/8',
            internalMarks: '24/40',
            grade: 'D',
          ),
          StudentPerformanceModel(
            studentName: 'Priya Nair',
            studentInitials: 'PN',
            attendancePercent: 84,
            assignmentsCompletedText: '8/8',
            internalMarks: '33/40',
            grade: 'B',
          ),
        ];
      case 'Batch A':
      default:
        return [
          StudentPerformanceModel(
            studentName: 'Rahul Sharma',
            studentInitials: 'RS',
            attendancePercent: 92,
            assignmentsCompletedText: '6/8',
            internalMarks: '38/40',
            grade: 'A',
          ),
          StudentPerformanceModel(
            studentName: 'Suman Nishad',
            studentInitials: 'SN',
            attendancePercent: 76,
            assignmentsCompletedText: '5/8',
            internalMarks: '29/40',
            grade: 'C',
          ),
          StudentPerformanceModel(
            studentName: 'Deepak Singh',
            studentInitials: 'DS',
            attendancePercent: 88,
            assignmentsCompletedText: '8/8',
            internalMarks: '35/40',
            grade: 'A',
          ),
          StudentPerformanceModel(
            studentName: 'Karan Mehta',
            studentInitials: 'KM',
            attendancePercent: 95,
            assignmentsCompletedText: '8/8',
            internalMarks: '39/40',
            grade: 'A+',
          ),
        ];
    }
  }

  /// Returns one student's assignment history - what they've been
  /// given, whether they've submitted/been graded yet, and their
  /// marks - for the Student Performance detail screen.
  Future<List<StudentAssignmentRecordModel>> getAssignmentRecordsFor(String studentName) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      StudentAssignmentRecordModel(
        title: 'Wiring Diagram Submission',
        dueDateText: '02 Aug 2026',
        status: AssignmentStatus.graded,
        marks: '18/20',
      ),
      StudentAssignmentRecordModel(
        title: 'Circuit Analysis Worksheet',
        dueDateText: '22 Jul 2026',
        status: AssignmentStatus.graded,
        marks: '20/20',
      ),
      StudentAssignmentRecordModel(
        title: 'Practical Lab Report',
        dueDateText: '10 Aug 2026',
        status: AssignmentStatus.pending,
      ),
    ];
  }
}
