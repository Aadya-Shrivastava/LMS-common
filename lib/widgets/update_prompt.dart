import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';

/// Asks the student to update when the Play Store / App Store has a
/// newer version than the one installed.
///
/// - A normal update can be put off with "Later" (asked again after 3
///   days).
/// - To force everyone on an old version to update, add this line to
///   the store listing's description, with the oldest version that
///   still works:
///     Play Store: `[Minimum supported app version: 1.2.0]`
///     App Store:  `[:mav: 1.2.0]`
///   Anyone below it gets the prompt with no "Later" button.
///
/// Only runs in release builds: debug builds and tests aren't installed
/// from a store, so there's nothing to compare against.
class UpdatePrompt extends StatelessWidget {
  final Widget child;

  const UpdatePrompt({super.key, required this.child});

  static final Upgrader _upgrader = Upgrader(
    // Don't re-check the store every time the app comes back from the
    // background; once per launch is enough.
    checkOnResume: false,
  );

  @override
  Widget build(BuildContext context) {
    if (!kReleaseMode) return child;

    return UpgradeAlert(
      upgrader: _upgrader,
      // The prompt opens on top of whatever screen is showing.
      navigatorKey: Get.key,
      showIgnore: false,
      showReleaseNotes: false,
      child: child,
    );
  }
}
