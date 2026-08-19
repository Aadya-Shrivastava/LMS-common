import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../custom_app_bar.dart';
import '../empty_state_widget.dart';
import 'student_drawer.dart';

/// A ready-to-use "Coming Soon" screen for student features that
/// haven't been fully designed yet (Live Classes, Fees, etc).
///
/// It still has the real app bar and the real side drawer, so the
/// navigation works end-to-end - only the middle of the screen is a
/// placeholder. Once a screen is ready to be built for real, we can
/// replace its file's content without touching anything else.
class StudentPlaceholderScreen extends StatelessWidget {
  final String title;
  final String currentRoute;
  final IconData icon;

  const StudentPlaceholderScreen({
    super.key,
    required this.title,
    required this.currentRoute,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: title, fallbackRoute: Routes.studentDashboard),
      drawer: StudentDrawer(currentRoute: currentRoute),
      body: EmptyStateWidget(
        icon: icon,
        title: '$title - Coming Soon',
        message: 'This screen is still being built.',
      ),
    );
  }
}
