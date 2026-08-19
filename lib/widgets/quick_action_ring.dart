import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// One "Quick Action" on the dashboard: a colored progress ring with an
/// icon in the middle, a bold label underneath, and a small colored
/// line of progress text (e.g. "2/3 present").
///
/// `progress` should be a number from 0.0 (empty ring) to 1.0 (full
/// ring) - since it's computed fresh from live data every time this
/// widget rebuilds, the ring automatically grows or shrinks as the
/// underlying work is completed or new work comes in.
class QuickActionRing extends StatelessWidget {
  static const double _ringSize = 56;

  final IconData icon;
  final String label;
  final String subtitle;
  final double progress;
  final Color accentColor;
  final VoidCallback onTap;

  const QuickActionRing({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.progress,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: _ringSize,
                    height: _ringSize,
                    child: CircularProgressIndicator(
                      // Clamped so a bad ratio (like dividing by zero
                      // and getting a stray value) can never crash the
                      // progress indicator, which only accepts 0.0-1.0.
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: accentColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  Icon(icon, color: accentColor, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: AppColors.primaryNavy,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
