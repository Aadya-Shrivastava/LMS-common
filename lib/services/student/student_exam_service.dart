import 'package:lms/models/student/exam_model.dart';
import 'package:lms/models/student/exam_result_model.dart';

/// Provides the student's upcoming exams and past result history.
class StudentExamService {
  Future<List<ExamModel>> getUpcomingExams() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      ExamModel(
        title: 'Semester 2 Theory Exam',
        subject: 'Basic Electrical Wiring',
        dateTimeText: '18 Aug 2026, 10:00 AM',
        durationText: '90 min',
        type: ExamType.mcq,
      ),
      ExamModel(
        title: 'Practical Assessment',
        subject: 'Workshop Safety',
        dateTimeText: '20 Aug 2026, 09:00 AM',
        durationText: '3 hr',
        type: ExamType.practical,
      ),
    ];
  }

  Future<List<ExamResultModel>> getResultHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      ExamResultModel(
        examTitle: 'Employability Skills Quiz',
        subject: 'Employability Skills',
        marksText: '27/30',
        grade: 'A',
        rankText: '4th',
      ),
      ExamResultModel(
        examTitle: 'Unit Test 1',
        subject: 'Basic Electrical Wiring',
        marksText: '38/50',
        grade: 'B+',
        rankText: '9th',
      ),
      ExamResultModel(
        examTitle: 'Semester 1 Final Exam',
        subject: 'All Subjects',
        marksText: '412/500',
        grade: 'A',
        rankText: '6th',
      ),
    ];
  }
}
