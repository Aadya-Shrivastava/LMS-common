import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A white, rounded card with a title (and optional trailing widget,
/// e.g. a badge or button) in its header - used for every "block" on
/// the feature screens, like "Schedule New Class" or "My Question Bank".
///
/// This is the same visual language as the dashboard's cards, just
/// generic enough to hold any content.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // `Flexible` (not just leaving `trailing` as-is) means
                // that if it's ever unusually wide - a long badge label,
                // say - it can shrink instead of squeezing the title's
                // `Expanded` box down to nothing and causing an overflow.
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Flexible(child: trailing!),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
