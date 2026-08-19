import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';

/// The very first function that runs when the app launches.
Future<void> main() async {
  // GetStorage needs to be set up once before we can use it anywhere
  // in the app (see core/storage/local_storage_service.dart).
  await GetStorage.init();

  runApp(const App());
}
