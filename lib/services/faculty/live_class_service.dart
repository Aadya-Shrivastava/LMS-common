import 'package:lms/models/faculty/live_class_model.dart';

/// Provides the list of live classes a faculty member has scheduled.
class LiveClassService {
  Future<List<LiveClassModel>> getScheduledClasses() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      LiveClassModel(
        id: 'lc1',
        subject: 'Basic Electrical Wiring',
        batch: 'Batch A',
        dateTimeText: '01 Aug, 09:00 AM',
        platform: 'Google Meet',
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        status: LiveClassStatus.live,
      ),
      LiveClassModel(
        id: 'lc2',
        subject: 'Circuit Design',
        batch: 'Batch B',
        dateTimeText: '01 Aug, 11:00 AM',
        platform: 'Zoom',
        meetingLink: 'https://zoom.us/j/1234567890',
        status: LiveClassStatus.upcoming,
      ),
      LiveClassModel(
        id: 'lc3',
        subject: 'Practical Lab',
        batch: 'Batch A',
        dateTimeText: '01 Aug, 02:00 PM',
        platform: 'Google Meet',
        meetingLink: 'https://meet.google.com/xyz-abcd-wxy',
        status: LiveClassStatus.upcoming,
      ),
      LiveClassModel(
        id: 'lc4',
        subject: 'Wiring Basics - Session 4',
        batch: 'Batch A',
        dateTimeText: '29 Jul, 09:00 AM',
        platform: 'Google Meet',
        meetingLink: 'https://meet.google.com/old-session',
        status: LiveClassStatus.completed,
      ),
    ];
  }
}
