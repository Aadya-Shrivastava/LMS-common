// A basic smoke test: it just checks that the app starts up without
// crashing and shows the splash screen's logo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lms/app.dart';

void main() {
  testWidgets('App starts and shows the splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // The splash screen should be the very first thing shown.
    expect(find.byType(Image), findsOneWidget);

    // The splash screen waits a moment and then moves to the login
    // screen. We fast-forward time here so that timer finishes before
    // the test ends, instead of leaving it "pending".
    await tester.pump(const Duration(seconds: 3));
  });
}
