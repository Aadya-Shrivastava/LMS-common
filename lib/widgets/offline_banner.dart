import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/date_formatters.dart';

/// Wraps the whole app (see `App`'s `builder`) and shows a strip at the
/// bottom while the phone is offline and screens are showing saved
/// data, e.g. "Offline - showing data saved 22 Oct, 3:15 PM".
class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: ApiClient.showingSavedDataFrom,
      builder: (context, savedAt, _) {
        if (savedAt == null) return child;

        return Column(
          children: [
            // The banner takes the bottom safe area instead of the page.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child,
              ),
            ),
            Material(
              color: AppColors.textPrimary,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_outlined, color: AppColors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline - showing data saved ${formatDateTime(savedAt)}. '
                          'Pull down to refresh when you\'re back online.',
                          style: const TextStyle(color: AppColors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
