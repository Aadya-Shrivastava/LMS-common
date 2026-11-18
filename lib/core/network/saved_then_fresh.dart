import 'api_client.dart';

/// Loads a screen's data in two steps, so it appears instantly:
///   1. The data saved from the last visit, with no network wait (if
///      this screen was opened before on this phone).
///   2. Fresh data from the server, which replaces it.
///
/// `apply` puts the data on screen, and is called once or twice. Only
/// a first-ever visit waits for the server (and shows the skeleton).
///
/// Returns an error message if step 2 failed (the server's own message
/// when it sent one, otherwise "Something went wrong"), or null. When
/// saved data was already shown, screens keep showing it on an error.
Future<String?> loadSavedThenFresh<T>(
  Future<T> Function() load,
  void Function(T data) apply,
) async {
  final saved = await ApiClient.fromCache(load);
  if (saved != null) apply(saved);

  try {
    apply(await load());
    return null;
  } catch (e) {
    return ApiClient.messageFor(e);
  }
}
