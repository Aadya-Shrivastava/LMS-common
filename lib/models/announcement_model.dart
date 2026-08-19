/// Represents one announcement/notice posted to students or faculty.
class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final DateTime postedAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.postedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      postedAt: DateTime.parse(json['postedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'postedAt': postedAt.toIso8601String(),
    };
  }
}
