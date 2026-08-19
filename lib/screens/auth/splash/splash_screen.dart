import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';

/// The very first screen shown when the app opens.
///
/// It displays the app's logo/name for a moment, then decides where to
/// go next:
///   - If someone is already logged in (AuthController restored their
///     session from the device - see AuthController.onInit), we skip
///     straight to their dashboard.
///   - Otherwise, we go to the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideWhereToGo();
  }

  Future<void> _decideWhereToGo() async {
    // Wait a couple of seconds so the splash screen is actually visible.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authController = Get.find<AuthController>();

    // `Get.offAllNamed` replaces the whole navigation history with the
    // next screen, so the user can't press "back" to return here.
    if (authController.isLoggedIn) {
      Get.offAllNamed(authController.dashboardRoute);
    } else {
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen has no real AppBar, so we have to explicitly tell the
    // status bar to use light/white icons ourselves - otherwise they'd
    // default to dark icons, which would be invisible on our navy
    // background.
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryNavy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 72, color: AppColors.white),
              SizedBox(height: 16),
              Text(
                'Campus LMS',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}
