import 'package:lms/models/student/student_assignment_model.dart';

/// Provides the student's assignment list.
class StudentAssignmentService {
  Future<List<StudentAssignmentModel>> getAssignments() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();

    return [
      StudentAssignmentModel(
        id: 'sa-1',
        title: 'Wiring Diagram Submission',
        subject: 'Basic Electrical Wiring',
        dueDate: now.add(const Duration(days: 1)),
        status: StudentAssignmentStatus.pending,
      ),
      StudentAssignmentModel(
        id: 'sa-2',
        title: 'Safety Protocol Report',
        subject: 'Workshop Safety',
        dueDate: now.subtract(const Duration(days: 4)),
        status: StudentAssignmentStatus.pending,
      ),
      StudentAssignmentModel(
        id: 'sa-3',
        title: 'Circuit Analysis Worksheet',
        subject: 'Basic Electrical Wiring',
        dueDate: now.subtract(const Duration(days: 10)),
        status: StudentAssignmentStatus.graded,
        marksText: '18/20',
      ),
      StudentAssignmentModel(
        id: 'sa-4',
        title: 'Resume Building Exercise',
        subject: 'Employability Skills',
        dueDate: now.subtract(const Duration(days: 14)),
        status: StudentAssignmentStatus.graded,
        marksText: '9/10',
      ),
      StudentAssignmentModel(
        id: 'sa-5',
        title: 'Tool Identification Quiz',
        subject: 'Workshop Safety',
        dueDate: now.subtract(const Duration(days: 22)),
        status: StudentAssignmentStatus.graded,
        marksText: '15/15',
      ),
    ];
  }
}
