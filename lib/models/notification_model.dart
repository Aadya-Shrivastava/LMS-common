/// Represents one notification shown to the user,
/// e.g. "Your assignment was graded".
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  /// Whether the user has already opened/read this notification.
  final bool isRead;

  /// A link to an attached file or image. Can be empty.
  final String attachmentUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.attachmentUrl = '',
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}
