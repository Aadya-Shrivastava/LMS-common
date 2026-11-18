/// Small helpers for reading values out of API JSON safely.
///
/// The backend isn't always consistent: money can come as `"120000.00"`
/// (text) or `9000.0` (number), and some fields can be `null`. These
/// helpers turn whatever comes back into the type we want, falling back
/// to an empty/zero value instead of crashing.
library;

/// Text value, or '' if missing.
String jsonString(dynamic value) => value == null ? '' : value.toString().trim();

/// Number value from a number or numeric text, or 0 if missing.
double jsonDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(jsonString(value)) ?? 0;
}

/// Whole number value from a number or numeric text, or 0 if missing.
int jsonInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(jsonString(value)) ?? jsonDouble(value).toInt();
}

/// Date from text like "2026-10-08" or "2026-10-08T13:00:00+05:30",
/// in the phone's local time. Null if missing or unreadable.
DateTime? jsonDate(dynamic value) {
  final parsed = DateTime.tryParse(jsonString(value));
  return parsed?.isUtc == true ? parsed!.toLocal() : parsed;
}

/// A list of JSON objects. Also accepts a paginated reply like
/// `{"results": [...]}`, in case the backend turns on paging later.
List<Map<String, dynamic>> jsonList(dynamic value) {
  if (value is Map && value['results'] is List) value = value['results'];
  if (value is! List) return [];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

/// A JSON object, or an empty map if it's missing.
Map<String, dynamic> jsonMap(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
