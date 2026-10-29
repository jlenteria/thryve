import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import 'reminder_copy.dart';

/// Result of a reminder request. Only [denied] is worth telling the user
/// about: [unsupported] means the platform has no notification backend at all
/// (web, or a desktop without one), which is not something they can fix.
enum ReminderResult { scheduled, denied, unsupported }

abstract final class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const DarwinInitializationSettings _darwin =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }
    try {
      tz_data.initializeTimeZones();
      await _useDeviceTimezone();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_launcher_monochrome'),
          iOS: _darwin,
          macOS: _darwin,
        ),
      );
      _initialized = true;
    } on Object catch (error) {
      // Desktop/test environments may not provide an implementation.
      debugPrint('Thryve: notifications unavailable ($error).');
    }
  }

  /// Schedules (or reschedules) the daily reminder.
  ///
  /// [askExactAlarms] also asks Android 12+ for "Alarms & reminders" access
  /// when it isn't granted yet. That opens a system settings page, so only
  /// pass it when the user has just asked for reminders.
  static Future<ReminderResult> scheduleDaily({
    required int hour,
    required int minute,
    required ReminderCopy copy,
    bool askExactAlarms = false,
  }) async {
    await initialize();
    if (!_initialized) {
      return ReminderResult.unsupported;
    }
    try {
      if (!await _requestPermission()) {
        return ReminderResult.denied;
      }
      final AndroidScheduleMode mode = await _scheduleMode(
        askExactAlarms: askExactAlarms,
      );
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!next.isAfter(now)) {
        // Calendar arithmetic, not `add(Duration(days: 1))`: a 23 or 25 hour
        // DST day would put the trigger an hour off, and the repeating
        // reminder keeps that wrong wall-clock time forever.
        next = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + 1,
          hour,
          minute,
        );
      }
      await _plugin.zonedSchedule(
        id: AppConstants.dailyReminderId,
        title: copy.title,
        body: copy.body,
        scheduledDate: next,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_focus',
            'Daily focus reminders',
            channelDescription:
                'Your chosen daily time to work toward your goal',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return ReminderResult.scheduled;
    } on Object catch (error) {
      debugPrint('Thryve: could not schedule reminder ($error).');
      return ReminderResult.unsupported;
    }
  }

  static Future<void> cancelDaily() async {
    // Initialize first: `cancel` on an uninitialized plugin is a silent
    // no-op, which would leave a previously scheduled nudge firing.
    await initialize();
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(id: AppConstants.dailyReminderId);
    } on Object {
      // Notification support is optional on unsupported platforms.
    }
  }

  /// Inexact alarms are batched by Android and can land many minutes late,
  /// so the reminder uses an exact alarm whenever the OS allows one.
  static Future<AndroidScheduleMode> _scheduleMode({
    required bool askExactAlarms,
  }) async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    bool exact = await androidPlugin.canScheduleExactNotifications() ?? false;
    if (!exact && askExactAlarms) {
      exact = await androidPlugin.requestExactAlarmsPermission() ?? false;
    }
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static Future<bool> _requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      // Skip the permission round-trip when it's already granted.
      if (await androidPlugin.areNotificationsEnabled() ?? false) {
        return true;
      }
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    final bool? ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final bool? macos = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return ios ?? macos ?? true;
  }

  static Future<void> _useDeviceTimezone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      return;
    } on Object catch (error) {
      debugPrint('Thryve: could not read device timezone ($error).');
    }
    // Fall back to a region whose UTC offset matches the device *now* and six
    // months ago, so a hemisphere with the opposite DST pattern (or an
    // offset-matching region that never observes it) is rejected instead of
    // shifting every reminder by an hour twice a year.
    final DateTime now = DateTime.now();
    final DateTime halfYearAgo = DateTime(now.year, now.month - 6);
    final int nowMs = now.millisecondsSinceEpoch;
    final int pastMs = halfYearAgo.millisecondsSinceEpoch;
    final Duration nowOffset = now.timeZoneOffset;
    final Duration pastOffset = halfYearAgo.timeZoneOffset;
    for (final tz.Location location in tz.timeZoneDatabase.locations.values) {
      if (location.name.startsWith('Antarctica/')) {
        continue;
      }
      if (location.timeZone(nowMs).offset != nowOffset ||
          location.timeZone(pastMs).offset != pastOffset) {
        continue;
      }
      tz.setLocalLocation(location);
      return;
    }
    debugPrint('Thryve: no timezone match; reminders may fire on UTC.');
  }
}
