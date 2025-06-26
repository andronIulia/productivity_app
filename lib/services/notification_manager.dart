import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity_app/notifications/notification_ids.dart';
import 'package:productivity_app/notifications/notifications.dart';
import 'package:productivity_app/services/screen_time_manager.dart';
import 'package:productivity_app/services/task_manager.dart';
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

    await _notifications.showDailyTaskReminder(scheduled);
    print('Notificare programată pentru: $scheduled');
  }

  Future<void> scheduleScreenTimeThresholds() async {
    for (final threshold in NotificationIds.thresholds) {
      await checkScreenTimeandNotify(threshold);
    }
  }

  Future<void> checkScreenTimeandNotify(Duration threshold) async {
    final screenTime = await _screenTimeManager.getTodayScreenTime();
    print(
      'Screen time curent: $screenTime minute (Prag: ${threshold.inMinutes} minute)',
    );
    if (screenTime >= threshold.inMinutes &&
        screenTime < threshold.inMinutes + 30) {
      const delay = Duration(minutes: 2);
      await _notifications.showScreenTimeNotification(delay, threshold);
      print('Notificare trimisă pentru ${threshold.inHours} ore');
    } else {
      print('Pragul de ${threshold.inHours} ore NU a fost depășit.');
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
      'com.twitter.android',
    ];
    for (final package in distractingPackages) {
      final app = apps[package];
      if (app != null && (app['minutes'] ?? 0) >= 30) {
        await _notifications.showDistractingAppNotification(
          appName: app['name'],
          minutes: app['minutes'],
          id: 200 + distractingPackages.indexOf(package),
        );
      }
    }
  }
}
