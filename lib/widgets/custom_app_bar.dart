import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/routes/app_routes.dart';

/// The navy app bar used on every faculty and student screen (except
/// the dashboards, which have their own headers).
///
/// It shows a title (e.g. "Live Classes") and, underneath it, an
/// optional smaller subtitle. It always shows a back arrow on the
/// left - tapping it goes back to whichever screen you came from, or
/// to `fallbackRoute` if there's nothing to go back to (this can
/// happen because the side drawer jumps between screens instead of
/// stacking them, so there isn't always a previous screen to "pop"
/// back to).
///
/// Pass `bottom` to add a row below the title - this is how screens
/// with tabs (Assignments, Study Material, Question Bank) add their
/// `TabBar` right into the app bar.
///
/// Because we implement `PreferredSizeWidget`, Flutter lets us use this
/// directly as a Scaffold's `appBar:`.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final PreferredSizeWidget? bottom;

  /// Where the back arrow sends the user when there's no previous
  /// screen to pop back to. Faculty screens fall back to the faculty
  /// dashboard; student screens should pass the student dashboard.
  final String fallbackRoute;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.bottom,
    this.fallbackRoute = Routes.facultyDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => _goBack(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.white,
              ),
            ),
        ],
      ),
      bottom: bottom,
    );
  }

  /// Goes back to the previous screen if there is one. If there isn't
  /// (e.g. we got here by tapping a drawer item, which replaces the
  /// current screen instead of stacking on top of it), we fall back to
  /// sending the user to the dashboard instead of leaving them stuck.
  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed(fallbackRoute);
    }
  }

  // This tells Flutter how tall our app bar is: the usual 64 for the
  // title/subtitle area, plus however tall `bottom` is (if given).
  @override
  Size get preferredSize => Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));
}
