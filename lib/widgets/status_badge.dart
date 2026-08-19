import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// The different "flavors" a badge can have - matches the badge colors
/// used throughout the prototype (success/warning/danger/info/neutral).
enum BadgeType { success, warning, danger, info, neutral }

/// A small pill-shaped label, e.g. "Live Now", "Pending Review",
/// "Graded". Used all over the feature screens wherever the prototype
/// shows a colored `<span class="badge">`.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({super.key, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _BadgeColors _colorsFor(BadgeType type) {
    switch (type) {
      case BadgeType.success:
        return const _BadgeColors(AppColors.statusGreen, AppColors.statusGreenBg);
      case BadgeType.warning:
        return const _BadgeColors(AppColors.statusAmber, AppColors.statusAmberBg);
      case BadgeType.danger:
        return const _BadgeColors(AppColors.statusRed, AppColors.statusRedBg);
      case BadgeType.info:
        return const _BadgeColors(AppColors.statCardBlue, AppColors.sectionBlueBg);
      case BadgeType.neutral:
        return const _BadgeColors(AppColors.textSecondary, AppColors.background);
    }
  }
}

class _BadgeColors {
  final Color text;
  final Color background;
  const _BadgeColors(this.text, this.background);
}
