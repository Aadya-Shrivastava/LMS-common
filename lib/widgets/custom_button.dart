import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A simple, reusable "main action" button, e.g. the Login button.
///
/// Instead of writing an ElevatedButton with a loading spinner every time
/// we need one, we just use `CustomButton(...)` and pass in what we need.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  /// When true, we show a spinner instead of the text and disable taps.
  /// Useful while something (like a login request) is in progress.
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // If we're loading, we pass `null` so the button becomes disabled.
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(text),
      ),
    );
  }
}
