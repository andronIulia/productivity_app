import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:productivity_app/notification_ids.dart';
import 'package:productivity_app/notifications.dart';
import 'package:productivity_app/screens/auth/screen_time_manager.dart';
import 'package:productivity_app/screens/task_manger.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationManager {
  final _notifications = Notifications();
  final _tasks = TaskManager();
  final _screenTimeManager = ScreenTimeManager();

  Future<void> init() async {
    await _notifications.init();
    setupNotifications();
  }

  void setupNotifications() {
    scheduleDailyTasksRemainder();
    scheduleScreenTimeThresholds();
    checkDistractingAppsAndNotify();
  }

  Future<void> scheduleDailyTasksRemainder() async {
    await _notifications.flutterLocalNotificationsPlugin.cancel(
      NotificationIds.dailyTaskReminderId,
    );
    final hasTasks = await _tasks.hasTasksForToday();
    if (!hasTasks) return;

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21,
      0,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: 1));
    }

    await _notifications.flutterLocalNotificationsPlugin.zonedSchedule(
      NotificationIds.dailyTaskReminderId,
      'Task-uri neterminate',
      'Mai ai task-uri nefinalizate pentru astazi!',
      scheduled,
      _notifications.getNotificationDetails('task_remainders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_task_remainder',
    );
    debugPrint('Notificare programată pentru: $scheduled');
  }

  Future<void> scheduleScreenTimeThresholds() async {
    for (final threshold in NotificationIds.thresholds) {
      await checkScreenTimeandNotify(threshold);
    }
  }

  Future<void> checkScreenTimeandNotify(Duration threshold) async {
    final screenTime = await _screenTimeManager.getTodayScreenTime();
    debugPrint(
      'Screen time curent: $screenTime minute (Prag: ${threshold.inMinutes} minute)',
    );
    if (screenTime >= threshold.inMinutes &&
        screenTime < threshold.inMinutes + 30) {
      const delay = Duration(minutes: 2);
      await _notifications.showScreenTimeNotification(delay, threshold);
      debugPrint('Notificare trimisă pentru ${threshold.inHours} ore');
    } else {
      debugPrint('Pragul de ${threshold.inHours} ore NU a fost depășit.');
    }
  }

  Future<void> checkDistractingAppsAndNotify() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = tz.TZDateTime.now(tz.local);
    final dateString = "${now.year}-${now.month}-${now.day}";
    final docRef =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('screen_time')
            .doc(dateString)
            .get();
    final data = docRef.data();
    if (data == null) return;
    final apps = data['apps'] as Map<String, dynamic>? ?? {};
    final distractingPackages = [
      'com.instagram.android',
      'com.facebook.katana',
      'com.tiktok.android',
      'com.x.twitter.android',
    ];
    for (final pkg in distractingPackages) {
      final app = apps[pkg];
      if (app != null && (app['minutes'] ?? 0) >= 30) {
        await _notifications.flutterLocalNotificationsPlugin.show(
          200 + distractingPackages.indexOf(pkg),
          'Timp mare pe ${app['name']}',
          'Ai petrecut ${app['minutes']} minute pe ${app['name']} azi.',
          _notifications.getNotificationDetails('distracting_app_alert'),
          payload: 'distracting_app_${app['name']}',
        );
      }
    }
  }
}
