import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/dashboard_list_item_model.dart';

/// Turns a ListItemStatus into the label + colors we show on screen.
/// Keeping this in one place means every list on the dashboard uses
/// exactly the same colors for "live", "pending", "done", etc.
class _StatusStyle {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _StatusStyle(this.label, this.color, this.backgroundColor);
}

_StatusStyle _styleFor(ListItemStatus status) {
  switch (status) {
    case ListItemStatus.live:
      return const _StatusStyle(
          'Live', AppColors.statusRed, AppColors.statusRedBg);
    case ListItemStatus.upcoming:
      return const _StatusStyle(
          'Upcoming', AppColors.statusAmber, AppColors.statusAmberBg);
    case ListItemStatus.pending:
      return const _StatusStyle(
          'Pending', AppColors.statusOrange, AppColors.statusOrangeBg);
    case ListItemStatus.done:
      return const _StatusStyle(
          'Graded', AppColors.statusGreen, AppColors.statusGreenBg);
    case ListItemStatus.review:
      return const _StatusStyle(
          'In Review', AppColors.statusPurple, AppColors.statusPurpleBg);
    case ListItemStatus.overdue:
      return const _StatusStyle(
          'Overdue', AppColors.statusRed, AppColors.statusRedBg);
  }
}

/// Turns a name like "Priya Nair" into initials like "PN", for the
/// little circle avatar shown next to recent submissions.
String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return '?';
  if (words.length == 1) {
    return words.first.length >= 2
        ? words.first.substring(0, 2).toUpperCase()
        : words.first.substring(0, 1).toUpperCase();
  }
  return (words.first[0] + words[1][0]).toUpperCase();
}

/// A single row used in the dashboard's "Today's Schedule",
/// "Pending Grading", and "Recent Submissions" lists.
///
/// It shows either a colored bar or a little initials avatar on the
/// left, a title, a subtitle, and a small colored chip on the right
/// showing the status - e.g. a bold solid "Live" pill for something
/// happening right now, or a soft "Pending" chip for something waiting.
class StatusListTile extends StatelessWidget {
  final DashboardListItem item;

  /// When true, shows a small circle with the person's initials
  /// instead of the colored left bar - used for "Recent Submissions",
  /// where each row is about a specific student.
  final bool useAvatar;

  const StatusListTile({
    super.key,
    required this.item,
    this.useAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(item.status);

    // "Live" and "Overdue" are the statuses urgent enough to deserve a
    // solid, eye-catching pill instead of the usual soft pastel chip.
    final isUrgent = item.status == ListItemStatus.live || item.status == ListItemStatus.overdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (useAvatar)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
                child: Text(
                  _initialsFor(item.title),
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            // The colored left bar that hints at the status.
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: style.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The small colored chip on the right, e.g. "Live" or "Pending".
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                // Urgent items get a solid fill; everything else gets a
                // soft pastel background.
                color: isUrgent ? style.color : style.backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                style.label,
                style: TextStyle(
                  color: isUrgent ? AppColors.white : style.color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
