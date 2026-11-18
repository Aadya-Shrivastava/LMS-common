import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// What happened when the student tapped "Reminder".
enum ReminderResult { scheduled, tooLate, permissionDenied, unsupported }

/// Schedules a phone notification shortly before a live class starts.
///
/// Uses the live class id as the notification id, so each class has at
/// most one reminder and it can be cancelled again. Works on Android
/// and iOS only; everywhere else (and in tests, where there's no
/// notification plugin) every call quietly does nothing.
class ClassReminderService {
  ClassReminderService._();
  static final ClassReminderService instance = ClassReminderService._();

  /// How long before the class the reminder goes off.
  static const Duration remindBefore = Duration(minutes: 10);

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Whether setup worked; null until it has run once.
  bool? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'class_reminders',
      'Class reminders',
      channelDescription: 'Reminders shortly before your live classes start',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Sets up the plugin once. False when reminders can't work here.
  ///
  /// Remembers the result (not the Future): a Future created in one
  /// zone can hang when awaited from another, e.g. between tests.
  Future<bool> _init() async {
    return _ready ??= await () async {
      if (!_supported) return false;
      try {
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            // Ask for permission when the first reminder is set, not at
            // app start.
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestSoundPermission: false,
              requestBadgePermission: false,
            ),
          ),
        );
        return true;
      } catch (_) {
        // No plugin registered (tests, unsupported builds) or setup
        // failed: reminders just aren't available, the screen still works.
        return false;
      }
    }();
  }

  /// Asks for notification permission if needed. True if allowed.
  Future<bool> _askPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// Schedules the reminder for class `id`, `remindBefore` its start.
  Future<ReminderResult> schedule({
    required int id,
    required String subject,
    required DateTime startsAt,
  }) async {
    if (!await _init()) return ReminderResult.unsupported;

    final remindAt = startsAt.subtract(remindBefore);
    if (!remindAt.isAfter(DateTime.now())) return ReminderResult.tooLate;

    try {
      if (!await _askPermission()) return ReminderResult.permissionDenied;

      // UTC avoids needing the phone's time zone name: the moment in
      // time is the same either way.
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(remindAt.toUtc(), tz.UTC),
        notificationDetails: _details,
        // Inexact needs no "exact alarm" permission; it may fire a
        // minute or two late, which is fine for a 10-minute heads-up.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Class starts in ${remindBefore.inMinutes} minutes',
        body: subject,
      );
      return ReminderResult.scheduled;
    } on PlatformException {
      return ReminderResult.unsupported;
    }
  }

  /// Removes the reminder for class `id`, if there is one.
  Future<void> cancel(int id) async {
    if (!await _init()) return;
    try {
      await _plugin.cancel(id: id);
    } on PlatformException {
      // Nothing to cancel.
    }
  }

  /// Ids of the classes that currently have a reminder set.
  Future<Set<int>> scheduledIds() async {
    if (!await _init()) return {};
    try {
      return {for (final request in await _plugin.pendingNotificationRequests()) request.id};
    } on PlatformException {
      return {};
    } on MissingPluginException {
      return {};
    }
  }
}
