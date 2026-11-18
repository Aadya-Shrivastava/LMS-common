import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/recorded_lecture_model.dart';
import 'package:lms/models/student/student_class_schedule_model.dart';
import 'package:lms/models/student/student_study_material_model.dart';
import 'package:lms/models/student/student_timetable_slot_model.dart';

/// Provides everything for the student's course-related screens: Live
/// Classes (API 7), My Timetable (API 46), and Study Materials (API 8
/// plus the lesson APIs 9-15).
class StudentCourseService {
  final ApiClient _apiClient = ApiClient();

  // ---- Live Classes ----

  /// Loads every live class for the student's batch from
  /// `AppUrls.liveClasses` and splits it into:
  ///   - `schedule`: classes that are live now or still coming up,
  ///     soonest first.
  ///   - `past`: finished or cancelled classes, most recent first.
  ///   - `recorded`: finished classes that have a recording.
  Future<
      ({
        List<StudentClassScheduleModel> schedule,
        List<StudentClassScheduleModel> past,
        List<RecordedLectureModel> recorded,
      })> getLiveClasses() async {
    final items = jsonList(await _apiClient.get(AppUrls.liveClasses));
    final now = DateTime.now();

    final upcoming = <(DateTime, StudentClassScheduleModel)>[];
    final past = <(DateTime, StudentClassScheduleModel)>[];
    final recorded = <RecordedLectureModel>[];

    for (final item in items) {
      final date = jsonDate(item['date']);
      final start = _atTime(date, jsonString(item['start_time']));
      final end = _atTime(date, jsonString(item['end_time']));
      final status = jsonString(item['status']).toLowerCase();

      final subject = jsonString(item['subject_name']);
      final topic = jsonString(item['topic']);
      final faculty = jsonString(item['faculty_name']);

      final recordingUrl = jsonString(item['recording_url']);
      if (item['is_recorded'] == true && recordingUrl.isNotEmpty) {
        recorded.add(RecordedLectureModel(
          tag: subject,
          title: topic.isNotEmpty ? topic : subject,
          durationText: '${jsonInt(item['duration_minutes'])} min',
          facultyName: faculty,
          recordingUrl: recordingUrl,
        ));
      }

      final isLive = status == 'live' ||
          status == 'ongoing' ||
          (start != null && end != null && now.isAfter(start) && now.isBefore(end));
      final isCancelled = status == 'cancelled';
      final isFinished = status == 'completed' || isCancelled || (end != null && now.isAfter(end));
      if (!isLive && isFinished) {
        past.add((
          start ?? date ?? DateTime(0),
          StudentClassScheduleModel(
            timeRange: _timeRangeText(date, item),
            subject: topic.isNotEmpty ? '$subject · $topic' : subject,
            facultyName: faculty,
            platform: _platformName(jsonString(item['platform'])),
            status: isCancelled ? StudentClassStatus.cancelled : StudentClassStatus.completed,
            meetingLink: jsonString(item['meeting_link']),
            id: jsonInt(item['id']),
            startsAt: start,
            endsAt: end,
          ),
        ));
        continue;
      }

      upcoming.add((
        start ?? now,
        StudentClassScheduleModel(
          timeRange: _timeRangeText(date, item),
          subject: topic.isNotEmpty ? '$subject · $topic' : subject,
          facultyName: faculty,
          platform: _platformName(jsonString(item['platform'])),
          status: isLive ? StudentClassStatus.live : StudentClassStatus.upcoming,
          meetingLink: jsonString(item['meeting_link']),
          id: jsonInt(item['id']),
          startsAt: start,
          endsAt: end,
        ),
      ));
    }

    upcoming.sort((a, b) => a.$1.compareTo(b.$1));
    past.sort((a, b) => b.$1.compareTo(a.$1));

    return (
      schedule: [for (final entry in upcoming) entry.$2],
      past: [for (final entry in past) entry.$2],
      recorded: recorded,
    );
  }

  /// Combines a date with "14:00:00" into one `DateTime`.
  DateTime? _atTime(DateTime? date, String time) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (date == null || hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// e.g. "Today · 02:00 PM - 03:00 PM" or "20 Oct 2026 · 02:00 PM - 03:00 PM".
  String _timeRangeText(DateTime? date, Map<String, dynamic> item) {
    final now = DateTime.now();
    final isToday = date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final dayText = date == null ? '' : (isToday ? 'Today' : formatDate(date));
    final timeText = '${formatTimeText(jsonString(item['start_time']))}'
        ' - ${formatTimeText(jsonString(item['end_time']))}';

    return dayText.isEmpty ? timeText : '$dayText · $timeText';
  }

  /// "google_meet" -> "Google Meet", "zoom" -> "Zoom".
  String _platformName(String platform) {
    return platform
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // ---- Timetable ----

  static const _dayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Every period for the student's batch from `AppUrls.timetableEntries`
  /// (API 46), grouped by day ("Monday" → periods in order). Days are
  /// in week order, and always include Monday to Saturday so the day
  /// picker doesn't jump around when a day has no classes.
  Future<Map<String, List<StudentTimetableSlotModel>>> getTimetable() async {
    final items = jsonList(await _apiClient.get(AppUrls.timetableEntries));

    final byDay = <String, List<(int, String, StudentTimetableSlotModel)>>{};
    for (final item in items) {
      final day = _dayName(jsonString(item['day']));
      if (day.isEmpty) continue;

      final start = _shortTime(jsonString(item['start_time']));
      final end = _shortTime(jsonString(item['end_time']));
      final isOnline = jsonString(item['class_mode']).toLowerCase() == 'online';
      final room = jsonString(item['room_name']);

      byDay.putIfAbsent(day, () => []).add((
        jsonInt(item['period_order']),
        start,
        StudentTimetableSlotModel(
          period: _periodLabel(jsonString(item['period_name']), jsonInt(item['period_order'])),
          timeRange: '$start-$end',
          kind: StudentTimetableSlotKind.classSlot,
          subject: jsonString(item['subject_name']),
          facultyName: jsonString(item['faculty_name']),
          room: isOnline ? 'Online' : (room.isEmpty ? '—' : room),
          isOnline: isOnline,
        ),
      ));
    }

    // By start time, then by period order for equal times.
    for (final slots in byDay.values) {
      slots.sort((a, b) {
        final byTime = a.$2.compareTo(b.$2);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });
    }

    final days = {..._dayOrder.take(6), ...byDay.keys}.toList()
      ..sort((a, b) => _dayOrder.indexOf(a).compareTo(_dayOrder.indexOf(b)));

    return {
      for (final day in days) day: [for (final entry in byDay[day] ?? const []) entry.$3],
    };
  }

  /// "monday" / "MON" -> "Monday". Empty if it isn't a weekday.
  String _dayName(String day) {
    final lower = day.toLowerCase();
    if (lower.length < 3) return '';
    for (final name in _dayOrder) {
      if (name.toLowerCase().startsWith(lower.substring(0, 3))) return name;
    }
    return '';
  }

  /// "15:00:00" -> "15:00".
  String _shortTime(String time) {
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0].padLeft(2, '0')}:${parts[1]}' : time;
  }

  /// "period 7" -> "P7"; falls back to the period order, e.g. "P2".
  String _periodLabel(String name, int order) {
    final number = RegExp(r'\d+').firstMatch(name)?.group(0);
    if (number != null) return 'P$number';
    if (name.isNotEmpty) return name;
    return order > 0 ? 'P$order' : '—';
  }

  // ---- Study Materials ----

  /// Everything the student can study, newest first: the study
  /// materials (API 8) plus the video, PDF, text, image, presentation,
  /// multimedia and download lessons (APIs 9-15), merged into one list.
  ///
  /// The sources load in parallel. If some fail, the rest still show;
  /// only if every one fails is the error passed on.
  Future<List<StudentStudyMaterialModel>> getStudyMaterials() async {
    final sources = <String, List<(DateTime?, StudentStudyMaterialModel)> Function(List<Map<String, dynamic>>)>{
      AppUrls.studyMaterials: (items) => items.map(_studyMaterial).toList(),
      AppUrls.videoLessons: (items) => [
            for (final item in items)
              _lesson(
                item,
                'video',
                StudentMaterialType.video,
                jsonString(item['video_link']).isNotEmpty
                    ? jsonString(item['video_link'])
                    : jsonString(item['video_file']),
              ),
          ],
      AppUrls.pdfLessons: (items) => [
            for (final item in items)
              _lesson(item, 'pdf', StudentMaterialType.pdf, jsonString(item['pdf_file'])),
          ],
      AppUrls.textLessons: (items) => [
            for (final item in items) _lesson(item, 'text', StudentMaterialType.text, ''),
          ],
      AppUrls.imageLessons: (items) => [
            for (final item in items)
              _lesson(item, 'image', StudentMaterialType.image, jsonString(item['image_file'])),
          ],
      AppUrls.presentationLessons: (items) => [
            for (final item in items)
              _lesson(
                item,
                'slides',
                StudentMaterialType.presentation,
                jsonString(item['slides_file']),
              ),
          ],
      AppUrls.multimediaLessons: (items) => [
            for (final item in items)
              _lesson(item, 'media', StudentMaterialType.link, jsonString(item['external_url'])),
          ],
      AppUrls.downloadLessons: (items) => [for (final item in items) ..._downloadLesson(item)],
    };

    ApiException? firstError;
    final results = await Future.wait([
      for (final MapEntry(key: path, value: parse) in sources.entries)
        _apiClient.get(path).then<List<(DateTime?, StudentStudyMaterialModel)>?>(
          (data) => parse(jsonList(data)),
          onError: (Object e) {
            if (e is! ApiException) throw e;
            firstError ??= e;
            return null;
          },
        ),
    ]);

    if (results.every((result) => result == null)) throw firstError!;

    final materials = [for (final result in results) ...?result];
    materials.sort((a, b) => (b.$1 ?? DateTime(0)).compareTo(a.$1 ?? DateTime(0)));
    return [for (final material in materials) material.$2];
  }

  /// One item from API 8.
  (DateTime?, StudentStudyMaterialModel) _studyMaterial(Map<String, dynamic> item) {
    final uploadedAt = jsonDate(item['uploaded_at']);
    final videoUrl = jsonString(item['video_url']);
    final fileUrl = jsonString(item['file_url'] ?? item['file']);
    final materialType = jsonString(item['material_type']).toLowerCase();

    final type = videoUrl.isNotEmpty || materialType.contains('video')
        ? StudentMaterialType.video
        : materialType == 'pdf'
            ? StudentMaterialType.pdf
            : StudentMaterialType.document;

    return (
      uploadedAt,
      StudentStudyMaterialModel(
        id: 'material-${jsonString(item['id'])}',
        title: jsonString(item['title']),
        subject: jsonString(item['subject_name']),
        type: type,
        uploadedByFacultyName: jsonString(item['uploaded_by_name']),
        dateText: uploadedAt == null ? '' : formatDate(uploadedAt),
        chapter: jsonString(item['chapter']),
        url: videoUrl.isNotEmpty ? videoUrl : fileUrl,
      ),
    );
  }

  /// One item from a lesson API (9-14). `idPrefix` keeps ids unique
  /// across the APIs, since each numbers its lessons from 1.
  (DateTime?, StudentStudyMaterialModel) _lesson(
    Map<String, dynamic> item,
    String idPrefix,
    StudentMaterialType type,
    String url, {
    String? title,
  }) {
    final createdAt = jsonDate(item['created_at']);
    return (
      createdAt,
      StudentStudyMaterialModel(
        id: '$idPrefix-${jsonString(item['id'])}',
        title: title ?? jsonString(item['title']),
        subject: jsonString(item['subject_name']),
        type: type,
        // The lesson APIs don't say who uploaded the lesson.
        uploadedByFacultyName: '',
        dateText: createdAt == null ? '' : formatDate(createdAt),
        url: url,
        textContent: jsonString(item['text_content']).replaceAll('\r\n', '\n'),
      ),
    );
  }

  /// A download lesson (API 15) holds a list of files: one row per file,
  /// or a single row (with the notes only) if it has none.
  List<(DateTime?, StudentStudyMaterialModel)> _downloadLesson(Map<String, dynamic> item) {
    final files = jsonList(item['files']);
    if (files.isEmpty) {
      return [_lesson(item, 'download', StudentMaterialType.document, '')];
    }

    final title = jsonString(item['title']);
    return [
      for (final file in files)
        _lesson(
          item,
          'download-${jsonString(file['id'])}',
          StudentMaterialType.document,
          jsonString(file['file']),
          title: files.length == 1 || jsonString(file['file_name']).isEmpty
              ? title
              : '$title · ${jsonString(file['file_name'])}',
        ),
    ];
  }
}
