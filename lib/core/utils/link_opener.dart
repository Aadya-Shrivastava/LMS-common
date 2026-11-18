import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web link from the API (a meeting link, a PDF, an attachment)
/// in the phone's browser or the app that handles it (e.g. Google Meet).
///
/// Shows a short message instead of crashing if the link is empty or
/// nothing on the phone can open it.
Future<void> openLink(String url) async {
  final uri = Uri.tryParse(url.trim());

  if (url.trim().isEmpty || uri == null || !uri.hasScheme) {
    Get.snackbar('No link', 'There is no file or link attached to this yet.',
        snackPosition: SnackPosition.BOTTOM);
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('not opened');
  } catch (_) {
    Get.snackbar("Couldn't open link", url, snackPosition: SnackPosition.BOTTOM);
  }
}
