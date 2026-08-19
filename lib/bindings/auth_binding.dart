import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

/// A "binding" tells GetX which controllers a screen (or the whole app)
/// needs, and creates them right before that screen is shown.
///
/// AuthController is special: we want it available everywhere in the
/// app (the drawer needs it, every screen needs it for logout), so this
/// binding is used as the app's `initialBinding` in app.dart, not just
/// for one screen.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // `Get.put` creates the controller immediately and keeps it alive
    // for as long as the app is running.
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
