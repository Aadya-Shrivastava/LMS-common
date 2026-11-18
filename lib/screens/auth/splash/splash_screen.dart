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
    // Just long enough to see the logo; the session check runs right after.
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final authController = Get.find<AuthController>();
    await authController.checkSavedSession();
    if (!mounted) return;

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryNavy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A white backdrop behind the logo, so it reads cleanly
              // against the navy background no matter what's around
              // the seal's edge in the source image.
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/logo.png'),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}
