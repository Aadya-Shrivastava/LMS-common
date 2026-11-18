// Draws every student screen on a small phone (320 x 568, like an
// iPhone SE / budget Android) at normal, large and very large text
// sizes, filled with the fixture data, and goes through every tab.
//
// Flutter fails a test when anything overflows its space (the yellow
// and black stripes you'd see in debug mode), so this catches layouts
// that break on small screens or with big system fonts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lms/controllers/auth_controller.dart';
import 'package:lms/core/routes/app_pages.dart';
import 'package:lms/core/routes/app_routes.dart';
import 'package:lms/core/theme/app_theme.dart';
import 'package:lms/models/user_model.dart';

import '../helpers/fake_server.dart';

/// Student screens, and the tab names to visit on each (empty = no tabs).
const Map<String, List<String>> screens = {
  Routes.studentDashboard: [],
  Routes.studentLiveClasses: ['Live & Schedule', 'Recorded Lectures'],
  Routes.studentTimetable: [],
  Routes.studentCourses: [],
  Routes.studentAssignments: [],
  Routes.studentExamsResults: ['Exams', 'Results'],
  Routes.studentAttendance: [],
  // Routes.studentSelfAttendanceQr: [], (self attendance is switched off)
  Routes.studentFees: ['Payment', 'History'],
  Routes.studentCertificates: [],
  Routes.studentPlacements: ['Drives', 'My Applications', 'Placed'],
  Routes.studentNotifications: [],
  Routes.studentProfile: [],
  Routes.studentAccountSettings: [],
};

/// Text sizes to check: normal, Android "Large" (about 130%), and the
/// largest accessibility size (200%).
const List<double> textSizes = [1.0, 1.3, 2.0];

void main() {
  setUp(resetApiState);
  tearDown(Get.reset);

  for (final MapEntry(key: route, value: tabs) in screens.entries) {
    for (final textSize in textSizes) {
      testWidgets('$route fits a small phone at ${(textSize * 100).round()}% text', (tester) async {
        // Keep the full report of each layout error - it names the
        // widget and file/line that overflowed - to print on failure.
        final reports = <String>[];
        final original = FlutterError.onError;
        FlutterError.onError = (details) {
          reports.add(details.toString());
          original?.call(details);
        };
        addTearDown(() => FlutterError.onError = original);

        tester.view.physicalSize = const Size(320, 568) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await withServer(fakeServer(), () async {
          Get.put(AuthController(), permanent: true).currentUser.value = const UserModel(
            id: '',
            name: 'Test Student',
            email: 'student@example.com',
            role: UserRole.student,
            department: 'COURSE  ITI',
            designation: 'BATCH A · SEMESTER 1',
          );

          await tester.pumpWidget(
            GetMaterialApp(
              theme: AppTheme.lightTheme,
              initialRoute: route,
              getPages: AppPages.pages,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textSize)),
                child: child!,
              ),
            ),
          );

          // Let the fake API calls finish and the screen fill in.
          await tester.pumpAndSettle();

          for (final tab in tabs) {
            await tester.tap(find.text(tab).first);
            await tester.pumpAndSettle();
          }

          // Scroll to the bottom of the visible list, so rows below the
          // fold get built and checked too.
          final scrollable = find.byType(Scrollable);
          if (scrollable.evaluate().isNotEmpty) {
            await tester.drag(scrollable.first, const Offset(0, -3000));
            await tester.pumpAndSettle();
          }
        });

        FlutterError.onError = original;
        expect(tester.takeException(), isNull, reason: reports.join('\n'));
      });
    }
  }
}
