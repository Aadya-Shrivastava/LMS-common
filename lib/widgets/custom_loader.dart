import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A simple centered loading spinner, shown while data is being fetched.
class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryNavy),
    );
  }
}
