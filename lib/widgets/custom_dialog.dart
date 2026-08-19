import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Shows a "are you sure?" dialog with Cancel and a destructive
/// confirm button (e.g. "Delete"). Returns `true` if the user
/// confirmed, `false` if they cancelled or dismissed the dialog.
///
/// Example usage:
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context,
///   title: 'Delete material?',
///   message: 'This cannot be undone.',
///   confirmLabel: 'Delete',
/// );
/// if (confirmed) { ... }
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusRed),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  // If the user taps outside the dialog to dismiss it instead of
  // pressing a button, `showDialog` returns null - we treat that the
  // same as "Cancel".
  return confirmed ?? false;
}

/// Shows a simple pop-up dialog with a title, a message, and an "OK" button.
///
/// Example usage:
/// ```dart
/// showAppDialog(context, title: 'Success', message: 'Saved!');
/// ```
Future<void> showAppDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
