/// The different "states" a dashboard list item can be in.
/// Each one is shown with a different color chip in the UI, so the
/// faculty member can tell things apart at a glance.
enum ListItemStatus {
  /// Something happening right now, e.g. a live class. Shown in red.
  live,

  /// Something coming up soon, e.g. a class later today. Shown in amber.
  upcoming,

  /// Something waiting to be done, e.g. ungraded work. Shown in orange.
  pending,

  /// Something finished, e.g. a graded submission. Shown in green.
  done,

  /// Something that still needs a second look. Shown in purple.
  review,

  /// Something whose deadline has already passed. Shown as a bold
  /// solid red pill, same weight as `live`, since both are urgent.
  overdue,
}

/// A single row shown in one of the dashboard's lists:
/// "Today's Schedule", "Pending Grading", or "Recent Submissions".
///
/// We reuse this one simple class for all three lists instead of making
/// a separate class for each, since they all display the same way
/// (a title, a small subtitle, and a colored status chip).
class DashboardListItem {
  final String title;
  final String subtitle;
  final ListItemStatus status;

  const DashboardListItem({
    required this.title,
    required this.subtitle,
    required this.status,
  });
}
