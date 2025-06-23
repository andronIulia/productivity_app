import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:productivity_app/notification_ids.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notifications {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    await _requestPermissions();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'test_channel',
      'canal test',
      description: 'merge la munte',
      importance: Importance.high,
    );
    final androidFlutterPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidFlutterPlugin?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  Future<void> _requestPermissions() async {
    final statusNotifications = await Permission.notification.status;
    if (!statusNotifications.isGranted) {
      await Permission.notification.request();
    }
    final androidFlutterPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final canScheduleExactAlarms =
        await androidFlutterPlugin?.canScheduleExactNotifications() ?? false;

    if (!canScheduleExactAlarms) {
      debugPrint('permisiune exact alarms nu e acordata ');
      await androidFlutterPlugin?.requestExactAlarmsPermission();
    }
  }

  void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    print("Notificare apăsată: ${notificationResponse.payload}");
  }

  NotificationDetails getNotificationDetails(String channelId) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Productivity Alerts',
        channelDescription: 'Notifications for productivity tracking',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'app_icon',
        //color: Colors.blue,
      ),
    );
  }

  Future<void> showScreenTimeNotification(
    Duration delay,
    Duration threshold,
  ) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      NotificationIds.getScreenTimeId(threshold),
      'Screen Time Alert',
      'Ai depășit ${threshold.inHours} ore de utilizare!',
      scheduledTime,
      getNotificationDetails('screen_time_alerts'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'screen_time_${threshold.inMinutes}',
    );
  }
}
