/// This class will one day be responsible for talking to our real backend
/// server (for example, using the `http` or `dio` package to send requests).
///
/// Right now the app has no backend yet, so this class is just an empty
/// placeholder. All of our `services/` classes return fake ("mock") data
/// instead of calling this class. When a real backend is ready, we can
/// fill in the methods below (get, post, etc.) and update the services to
/// use them.
class ApiClient {
  // The base web address of our backend, e.g. "https://api.example.com".
  // Left empty for now because we don't have a backend yet.
  final String baseUrl = '';

  // TODO: Add real network methods here once we have a backend, for example:
  // Future<Map<String, dynamic>> get(String path) async { ... }
  // Future<Map<String, dynamic>> post(String path, Map body) async { ... }
}
