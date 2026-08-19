import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A small circle showing someone's initials, e.g. "RS" for
/// "Rahul Sharma" - used next to student names throughout the
/// grading, attendance, and performance tables.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double radius;

  const InitialsAvatar({super.key, required this.initials, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primaryNavy,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
