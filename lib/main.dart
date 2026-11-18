import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/api_cache.dart';

/// The very first function that runs when the app launches.
Future<void> main() async {
  // GetStorage needs to be set up once before we can use it anywhere
  // in the app (see core/storage/local_storage_service.dart).
  await GetStorage.init();

  // Saved API replies, so screens still show data when offline.
  await GetStorage.init(GetStorageApiCache.boxName);
  ApiClient.cache = GetStorageApiCache();

  // If part of a screen fails to draw (e.g. the server sent data in an
  // unexpected shape), show a small "Something went wrong" in its place
  // instead of Flutter's grey box. Debug builds keep the red error
  // screen, which says what broke.
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const Material(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ),
        );
  }

  runApp(const App());
}
