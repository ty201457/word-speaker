import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  static const _enabledKey = 'daily_notification_enabled';
  static const _hourKey = 'daily_notification_hour';
  static const _minuteKey = 'daily_notification_minute';

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  Future<({int hour, int minute})> reminderTime() async {
    final preferences = await SharedPreferences.getInstance();
    return (
      hour: preferences.getInt(_hourKey) ?? 20,
      minute: preferences.getInt(_minuteKey) ?? 0,
    );
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
  }) async {
    final granted = await requestPermission();
    if (!granted) throw Exception('通知權限未開啟');

    await _plugin.cancel(1001);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1001,
      '今天的 3 個英文單字準備好了',
      '從單音節、雙音節到多音節，每天進步一點點。',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_words',
          '每日單字',
          channelDescription: '每天提醒完成單字與音節訓練',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, true);
    await preferences.setInt(_hourKey, hour);
    await preferences.setInt(_minuteKey, minute);
  }

  Future<void> disable() async {
    await _plugin.cancel(1001);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, false);
  }
}
