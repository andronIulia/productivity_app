import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:productivity_app/notification_ids.dart';
import 'package:productivity_app/notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationManager {
  final _notifications = Notifications();

  Future<void> init() async {
    await _notifications.initi();
    setupNotifications();
  }

  void setupNotifications() {
    scheduleDailyTasksRemainder();
    scheduleScreenTimeThresholds();
  }

  Future<void> scheduleDailyTasksRemainder() async {
    await _notifications.flutterLocalNotificationsPlugin.cancel(
      NotificationIds.dailyTaskReminderId,
    );
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
      scheduled = scheduled.add(Duration(days: 1));
    }

    await _notifications.flutterLocalNotificationsPlugin.zonedSchedule(
      NotificationIds.dailyTaskReminderId,
      'Task-uri neterminate',
      'Mai ai task-uri nefinalizate pentru astazi!',
      scheduled,
      _getNotificationDetails('task_remainders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_task_remainder',
    );
    debugPrint('Notificare programată pentru: $scheduled');
  }

  NotificationDetails _getNotificationDetails(String channelId) {
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

  Future<void> scheduleScreenTimeThresholds() async {
    const thresholds = [
      Duration(minutes: 30),
      Duration(hours: 1),
      Duration(hours: 2),
      Duration(hours: 4),
    ];
    for (final threshold in thresholds) {
      await checkScreenTimeandNotify(threshold);
    }
  }

  Future<void> checkScreenTimeandNotify(Duration threshold) async {
    final screenTime = await getTodayScreenTime();
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

  Future<int> getTodayScreenTime() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final now = tz.TZDateTime.now(tz.local);
    final dateString = "${now.year}-${now.month}-${now.day}";
    final docRef =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('screen_time')
            .doc(dateString)
            .get();
    return docRef.data()?['totalMinutes'] ?? 0;
  }
}
