import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'app_drawer.dart';
import '../custom_app_bar.dart';
import '../empty_state_widget.dart';

/// A ready-to-use "Coming Soon" screen for faculty features that
/// haven't been fully designed yet (Live Classes, Timetable, etc).
///
/// It still has the real app bar and the real side drawer, so the
/// navigation works end-to-end - only the middle of the screen is a
/// placeholder. Once a screen is ready to be built for real, we can
/// replace its file's content without touching anything else.
class FacultyPlaceholderScreen extends StatelessWidget {
  final String title;
  final String currentRoute;
  final IconData icon;

  const FacultyPlaceholderScreen({
    super.key,
    required this.title,
    required this.currentRoute,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: title),
      drawer: AppDrawer(currentRoute: currentRoute),
      body: EmptyStateWidget(
        icon: icon,
        title: '$title - Coming Soon',
        message: 'This screen is still being built.',
      ),
    );
  }
}
