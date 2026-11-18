import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/auth_binding.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'widgets/offline_banner.dart';
import 'widgets/update_prompt.dart';

/// The root widget of the whole app.
///
/// We use `GetMaterialApp` (instead of the usual `MaterialApp`) because
/// it comes with GetX's navigation system built in, which is what lets
/// us write `Get.toNamed(Routes.login)` from anywhere in the app
/// without needing a BuildContext.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Campus LMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // The first screen shown when the app opens.
      initialRoute: Routes.splash,

      // The full list of screens and how to reach them (app_pages.dart).
      getPages: AppPages.pages,

      // Creates AuthController once, right when the app starts, so it's
      // available everywhere (the drawer, every screen's logout button).
      initialBinding: AuthBinding(),

      // Shows the "Offline - showing saved data" strip on every screen,
      // and the "please update" prompt when the store has a newer version.
      builder: (context, child) => UpdatePrompt(
        child: OfflineBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
