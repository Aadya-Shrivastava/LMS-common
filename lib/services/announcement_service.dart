import '../models/announcement_model.dart';

/// Provides announcements/notices posted for students or faculty.
class AnnouncementService {
  Future<List<AnnouncementModel>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      AnnouncementModel(
        id: 'an1',
        title: 'Mid-Semester Exams',
        message: 'Mid-semester exams begin next Monday. Check the timetable.',
        postedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AnnouncementModel(
        id: 'an2',
        title: 'Faculty Meeting',
        message: 'Department meeting scheduled for Friday, 4 PM.',
        postedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}
