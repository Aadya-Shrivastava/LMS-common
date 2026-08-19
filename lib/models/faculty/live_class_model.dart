/// How a scheduled live class relates to "right now".
enum LiveClassStatus { live, upcoming, completed }

/// One live class a faculty member has scheduled (or is running).
class LiveClassModel {
  final String id;
  final String subject;
  final String batch;

  /// Shown as text, e.g. "01 Aug, 09:00 AM" - kept as a ready-made
  /// string since this is mock data, instead of a full DateTime.
  final String dateTimeText;

  final String platform;
  final String meetingLink;
  final LiveClassStatus status;

  const LiveClassModel({
    required this.id,
    required this.subject,
    required this.batch,
    required this.dateTimeText,
    required this.platform,
    required this.meetingLink,
    required this.status,
  });
}
