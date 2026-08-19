/// Small helper functions for turning a `DateTime` into the short,
/// readable text format used across the app, e.g. "02 Aug 2026" or
/// "02 Aug, 09:00 AM".
///
/// We write these by hand instead of adding a date-formatting package,
/// since we only need these two simple formats.
library;

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Formats a date only, e.g. "02 Aug 2026".
String formatDate(DateTime date) {
  return '${_twoDigits(date.day)} ${_monthNames[date.month - 1]} ${date.year}';
}

/// Formats a date and time together, e.g. "02 Aug, 09:00 AM".
String formatDateTime(DateTime dateTime) {
  final hour24 = dateTime.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final minute = _twoDigits(dateTime.minute);

  return '${_twoDigits(dateTime.day)} ${_monthNames[dateTime.month - 1]}, '
      '$hour12:$minute $period';
}

/// True if the current time of day falls inside a "HH:MM-HH:MM" range,
/// e.g. `isNowWithinTimeRange('09:00-09:45')`. Used on the Timetable
/// screen to decide whether an online class's "Join" button should be
/// enabled right now.
bool isNowWithinTimeRange(String range) {
  final parts = range.split('-');
  if (parts.length != 2) return false;

  final start = _parseTimeOfDayMinutes(parts[0].trim());
  final end = _parseTimeOfDayMinutes(parts[1].trim());
  if (start == null || end == null) return false;

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;

  return nowMinutes >= start && nowMinutes <= end;
}

/// Turns "09:00" into the number of minutes since midnight (540), so
/// two times can be compared with simple integer math. Returns null if
/// the text isn't in that "HH:MM" shape.
int? _parseTimeOfDayMinutes(String text) {
  final parts = text.split(':');
  if (parts.length != 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;

  return hour * 60 + minute;
}
