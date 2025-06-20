import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notifications {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initi() async {
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
      'test_channel', // id-ul canalului trebuie să fie unic
      'cnal tesr',
      description: 'merge la munte',
      importance: Importance.high,
    );
    //channel
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

  void displayNotification(String title, String body) async {
    final now = tz.TZDateTime.now(tz.local);
    /*tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21, //aici poate modific sa primeasca ca argumnet
      5,
    );*/
    final scheduled = now.add(const Duration(seconds: 20));
    print("Notificare programată pentru: $scheduled");
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      //0,zone
      notificationId,
      title,
      body,
      //scheduled,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30)),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'cnal tesr',
          channelDescription: 'merge la munte',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'app_icon',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'test_payload',
    );
    print('Notificare programata');
  }

  Future<bool> hasTasksForToday() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final userDailyTasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');
    final remainingTasks =
        await userDailyTasksRef.where('isDone', isEqualTo: false).get();
    return remainingTasks.docs.isNotEmpty;
  }

  Future<void> scheduleDailyTasksRemainder() async {
    final hasTasks = await hasTasksForToday();
    if (!hasTasks) return;

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21, //aici poate modific sa primeasca ca argumnet
      0,
    );
    if (scheduled.isBefore(now)) {
      scheduled.add(Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '',
      '',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channelId',
          'channelName',
          channelDescription: 'Task-uri zilnice',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'app_icon',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
