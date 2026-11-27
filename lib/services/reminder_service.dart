import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily mood reminder: a local notification every day at the chosen time.
/// The choice (on/off + time) is saved on the phone with shared_preferences.
/// Notifications only work in the Android app (not in Chrome).
class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  static const _notificationId = 1;
  static const _keyOn = 'reminder_on';
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool enabled = false;
  TimeOfDay time = const TimeOfDay(hour: 20, minute: 0); // 8:00 PM

  /// True on Android (where notifications work)
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Called once in main(): loads the saved choice and re-schedules if needed
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_keyOn) ?? false;
    time = TimeOfDay(
      hour: prefs.getInt(_keyHour) ?? 20,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );

    if (!supported) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
    if (enabled) await _schedule();
  }

  /// Turn on/off or change the time. Returns true if the reminder is active.
  Future<bool> update({required bool on, required TimeOfDay at}) async {
    enabled = on;
    time = at;
    await _save();

    if (!supported || !_ready) return on; // Chrome: just save the choice

    if (!on) {
      await _plugin.cancel(_notificationId);
      return false;
    }

    // Android 13+ asks the user for permission to show notifications
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? true;
    if (!granted) {
      enabled = false;
      await _save();
      return false;
    }

    await _schedule();
    return true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOn, enabled);
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
  }

  // Next time the clock shows the chosen time, then repeat every day
  Future<void> _schedule() async {
    await _plugin.cancel(_notificationId);

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      _notificationId,
      'How are you feeling today? 🌿',
      'Take a moment to check in with your mood on Moodsage.',
      tz.TZDateTime.from(next, tz.UTC),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'A gentle daily nudge to log your mood',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }
}