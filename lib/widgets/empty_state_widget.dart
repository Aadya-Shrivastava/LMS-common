import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A friendly "nothing here yet" placeholder.
///
/// We use this on every screen that isn't fully built yet, so instead of
/// a blank white page, the user sees an icon and a helpful message.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.construction_outlined,
    this.title = 'Coming Soon',
    this.message = 'This screen is still being built.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
