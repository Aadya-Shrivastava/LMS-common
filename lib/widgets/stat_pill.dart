import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// One capsule-shaped stat, e.g. a solid orange circle icon +
/// "120 / Students". Meant to sit in a row (usually one that scrolls
/// sideways when there isn't room for every pill at once).
///
/// Pass `onTap` to make the pill jump to the screen that stat is
/// about (like the dashboard does), or to use it as a filter chip
/// (like the Attendance screen's stat pills); leave it out for a
/// purely informational stat (like the Timetable screen's stats,
/// which aren't links to anything).
///
/// Pass `selected: true` to draw a highlighted ring around the pill -
/// used when the pill is doubling as a filter, to show which one is
/// currently active.
class StatPill extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool selected;

  const StatPill({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          // A light tint of the accent color as the whole pill's fill,
          // instead of a white card - this is what gives the strip its
          // soft, colorful look.
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(40),
          border: selected ? Border.all(color: accentColor, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.white, size: 19),
            ),
            const SizedBox(width: 10),
            // `Flexible` (not `mainAxisSize.min`, which has no upper
            // bound) is what lets the value/title shrink with an
            // ellipsis instead of overflowing when this pill is
            // squeezed into a narrow `Expanded` slot, e.g. a 2-wide grid.
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
